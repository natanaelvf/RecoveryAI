import { Router, Request, Response } from 'express';
import Twilio from 'twilio';
import { lookupContractorByTwilioNumber } from '../../services/twilio';
import { findOrCreateLead } from '../../services/deduplication';
import { initiateConsentSms } from '../../services/sms-state-machine';
import { sendPushNotification } from '../../services/notifications';
import { isWithinWorkingHours } from '../../utils/working-hours';
import { TwilioVoiceWebhookBody } from '../../types';
import { supabase } from '../../config/supabase';

const router = Router();
const VoiceResponse = Twilio.twiml.VoiceResponse;

/**
 * Helper to get host base URL (e.g. https://unmissed.fly.dev)
 */
function getBaseUrl(req: Request): string {
  const protocol = req.secure || req.headers?.['x-forwarded-proto'] === 'https' ? 'https' : 'http';
  return `${protocol}://${req.get('host')}`;
}

/**
 * POST / — Twilio voice webhook: incoming call arrives
 */
router.post('/', async (req: Request, res: Response) => {
  const body = req.body as TwilioVoiceWebhookBody;
  const twiml = new VoiceResponse();

  try {
    const contractor = await lookupContractorByTwilioNumber(body.To);

    if (!contractor) {
      twiml.say('Sorry, this number is not configured. Goodbye.');
      twiml.hangup();
      res.type('text/xml').send(twiml.toString());
      return;
    }

    const afterHours = !isWithinWorkingHours(contractor);
    const isPT = body.From.startsWith('+351') || contractor.locale === 'pt';

    // 1. Create/Find lead immediately to start tracking the call
    const { lead, isNew } = await findOrCreateLead(contractor.id, body.From, afterHours);

    // If it's Portuguese or contractor's locale is Portuguese, go straight to PT voicemail
    if (isPT) {
      if (isNew) {
        await supabase
          .from('leads')
          .update({ locale: 'pt', updated_at: new Date().toISOString() })
          .eq('id', lead.id);
      }
      twiml.redirect(`/webhooks/twilio-voice/voicemail-pt?contractorId=${contractor.id}&leadId=${lead.id}&isNew=${isNew}`);
      res.type('text/xml').send(twiml.toString());
      return;
    }

    // 2. Determine call routing based on setup type
    if (contractor.number_setup_type === 'forwarding') {
      // Forwarded calls mean the contractor ALREADY missed it on their phone.
      // Bypass dialing the contractor to prevent infinite forwarding loops.
      twiml.redirect(`/webhooks/twilio-voice/ivr-menu?contractorId=${contractor.id}&leadId=${lead.id}&isNew=${isNew}`);
    } else {
      // Direct number setup — we should ring the contractor first if open
      if (!afterHours || contractor.after_hours_ring) {
        const dial = twiml.dial({
          action: `/webhooks/twilio-voice/status?contractorId=${contractor.id}&leadId=${lead.id}&isNew=${isNew}`,
          method: 'POST',
          timeout: 20,
        });
        dial.number(contractor.contact_phone);
      } else {
        // Closed / after hours — route directly to IVR/Voicemail
        twiml.redirect(`/webhooks/twilio-voice/ivr-menu?contractorId=${contractor.id}&leadId=${lead.id}&isNew=${isNew}`);
      }
    }

    res.type('text/xml').send(twiml.toString());
  } catch (err) {
    console.error('Error handling voice webhook:', err);
    twiml.say('An error occurred. Please try again later.');
    twiml.hangup();
    res.type('text/xml').send(twiml.toString());
  }
});

/**
 * POST /status — Twilio dial status callback
 * Fired after the <Dial> completes (answered, no-answer, busy, failed).
 */
router.post('/status', async (req: Request, res: Response) => {
  const { DialCallStatus } = req.body as Record<string, string>;
  const { contractorId, leadId, isNew } = req.query as Record<string, string>;
  const twiml = new VoiceResponse();

  try {
    if (['no-answer', 'busy', 'failed'].includes(DialCallStatus)) {
      // Contractor missed the call -> redirect caller to IVR menu
      twiml.redirect(`/webhooks/twilio-voice/ivr-menu?contractorId=${contractorId}&leadId=${leadId}&isNew=${isNew}`);
    } else if (DialCallStatus === 'completed') {
      // Call was successfully answered by contractor
      // Mark lead as completed or remove/update it so we don't trigger missed call SMS
      if (leadId) {
        await supabase
          .from('leads')
          .update({ status: 'completed', updated_at: new Date().toISOString() })
          .eq('id', leadId);
      }
      twiml.hangup();
    } else {
      twiml.hangup();
    }
  } catch (err) {
    console.error('Error handling voice dial status callback:', err);
    twiml.hangup();
  }

  res.type('text/xml').send(twiml.toString());
});

/**
 * POST /ivr-menu — Interactive Voice Response language selection menu
 */
router.post('/ivr-menu', async (req: Request, res: Response) => {
  const { contractorId, leadId, isNew } = req.query as Record<string, string>;
  const twiml = new VoiceResponse();
  const baseUrl = getBaseUrl(req);

  try {
    const gather = twiml.gather({
      action: `/webhooks/twilio-voice/ivr-gather?contractorId=${contractorId}&leadId=${leadId}&isNew=${isNew}`,
      method: 'POST',
      numDigits: 1,
      timeout: 5,
    });

    // Play bilingual language selection prompt
    gather.play(`${baseUrl}/audio/ivr_menu.mp3`);
    // Fallback TTS in case the audio file load fails
    gather.say({ language: 'fi-FI' }, 'Paina 1 englanniksi, tai odota suomeksi.');
    gather.say({ language: 'en-US' }, 'Press 1 for English, or wait for Finnish.');

    // Fallback: If no keys are pressed within timeout, proceed with Finnish voicemail
    twiml.redirect(`/webhooks/twilio-voice/voicemail-fi?contractorId=${contractorId}&leadId=${leadId}&isNew=${isNew}`);
  } catch (err) {
    console.error('Error serving IVR menu:', err);
    twiml.redirect(`/webhooks/twilio-voice/voicemail-fi?contractorId=${contractorId}&leadId=${leadId}&isNew=${isNew}`);
  }

  res.type('text/xml').send(twiml.toString());
});

/**
 * POST /ivr-gather — Processes IVR keypress
 */
router.post('/ivr-gather', async (req: Request, res: Response) => {
  const { Digits } = req.body as Record<string, string>;
  const { contractorId, leadId, isNew } = req.query as Record<string, string>;
  const twiml = new VoiceResponse();

  try {
    if (Digits === '1') {
      // User selected English
      if (leadId) {
        await supabase
          .from('leads')
          .update({ locale: 'en', updated_at: new Date().toISOString() })
          .eq('id', leadId);
      }
      twiml.redirect(`/webhooks/twilio-voice/voicemail-en?contractorId=${contractorId}&leadId=${leadId}&isNew=${isNew}`);
    } else {
      // Default to Finnish for any other keypress
      if (leadId) {
        await supabase
          .from('leads')
          .update({ locale: 'fi', updated_at: new Date().toISOString() })
          .eq('id', leadId);
      }
      twiml.redirect(`/webhooks/twilio-voice/voicemail-fi?contractorId=${contractorId}&leadId=${leadId}&isNew=${isNew}`);
    }
  } catch (err) {
    console.error('Error handling IVR gather:', err);
    twiml.redirect(`/webhooks/twilio-voice/voicemail-fi?contractorId=${contractorId}&leadId=${leadId}&isNew=${isNew}`);
  }

  res.type('text/xml').send(twiml.toString());
});

/**
 * POST /voicemail-fi — Plays Finnish voicemail greeting
 */
router.post('/voicemail-fi', async (req: Request, res: Response) => {
  const twiml = new VoiceResponse();
  const baseUrl = getBaseUrl(req);

  twiml.play(`${baseUrl}/audio/voicemail_fi.mp3`);
  twiml.say({ language: 'fi-FI' }, 'Hei, pahoittelut ettemme voineet vastata puheluusi. Olemme lähettäneet sinulle tekstiviestin, jotta voit varata takaisinsoittoajan. Kuulemiin!');
  twiml.hangup();

  res.type('text/xml').send(twiml.toString());
});

/**
 * POST /voicemail-en — Plays English voicemail greeting
 */
router.post('/voicemail-en', async (req: Request, res: Response) => {
  const twiml = new VoiceResponse();
  const baseUrl = getBaseUrl(req);

  twiml.play(`${baseUrl}/audio/voicemail_en.mp3`);
  twiml.say({ language: 'en-US' }, 'Hi, sorry we missed your call. We\'ve sent you a text message to help you book a callback. Goodbye!');
  twiml.hangup();

  res.type('text/xml').send(twiml.toString());
});

/**
 * POST /voicemail-pt — Plays Portuguese voicemail greeting
 */
router.post('/voicemail-pt', async (req: Request, res: Response) => {
  const twiml = new VoiceResponse();
  const baseUrl = getBaseUrl(req);

  twiml.play(`${baseUrl}/audio/voicemail_pt.mp3`);
  twiml.say({ language: 'pt-PT' }, 'Olá, lamentamos não ter conseguido atender a sua chamada. Iremos enviar-lhe uma mensagem de texto para o ajudar a agendar um contacto. Obrigado.');
  twiml.hangup();

  res.type('text/xml').send(twiml.toString());
});

/**
 * POST /call-status — Receives final Call Status changes when the call completely ends.
 * We configure this as the Voice Status Callback on the Twilio phone number.
 */
router.post('/call-status', async (req: Request, res: Response) => {
  const { CallStatus, From, To } = req.body as Record<string, string>;

  try {
    // We only trigger lead recovery SMS when the call is fully completed (hung up)
    if (['completed', 'no-answer', 'busy', 'failed'].includes(CallStatus)) {
      const contractor = await lookupContractorByTwilioNumber(To);
      if (contractor) {
        // Fetch the most recent lead created for this caller/contractor within the last 2 minutes
        const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000).toISOString();
        const { data: lead, error } = await supabase
          .from('leads')
          .select('*')
          .eq('contractor_id', contractor.id)
          .eq('caller_phone', From)
          .gte('created_at', twoMinutesAgo)
          .order('created_at', { ascending: false })
          .limit(1)
          .single();

        if (!error && lead) {
          // If the lead status is still 'missed' (meaning we routed them to IVR/Voicemail, they hung up, and it was missed)
          if (lead.status === 'missed') {
            // Trigger the SMS sequence in their preferred language!
            // initiateConsentSms updates status to 'consent_sent' internally
            await initiateConsentSms(lead, contractor);

            await sendPushNotification(
              contractor.id,
              lead.call_count === 1 ? 'Missed Call' : `Repeat Caller (${lead.call_count}x)`,
              `Missed call from ${From}`,
              { leadId: lead.id }
            );
          }
        }
      }
    }
  } catch (err) {
    console.error('Error handling Twilio voice status callback:', err);
  }

  res.status(200).send();
});

export default router;
