import { Router, Request, Response } from 'express';
import Twilio from 'twilio';
import { lookupContractorByTwilioNumber } from '../../services/twilio';
import { findOrCreateLead } from '../../services/deduplication';
import { initiateConsentSms } from '../../services/sms-state-machine';
import { sendPushNotification } from '../../services/notifications';
import { isWithinWorkingHours } from '../../utils/working-hours';
import { TwilioVoiceWebhookBody } from '../../types';

const router = Router();

const VoiceResponse = Twilio.twiml.VoiceResponse;

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

    const withinHours = isWithinWorkingHours(contractor);

    if (withinHours || contractor.after_hours_ring) {
      // Forward the call to the contractor's personal phone
      const dial = twiml.dial({
        action: '/webhooks/twilio-voice/status',
        method: 'POST',
        timeout: 20,
      });
      dial.number(contractor.contact_phone);
    } else {
      // After hours — play message and hang up
      // TODO: Customize after-hours message per contractor
      twiml.say(
        `Thank you for calling ${contractor.business_name}. We are currently closed. ` +
        `We'll follow up with you shortly via text message.`
      );
      twiml.hangup();

      // Immediately handle as missed call (after hours)
      const { lead, isNew } = await findOrCreateLead(contractor.id, body.From, true);
      if (isNew) {
        await initiateConsentSms(lead, contractor);
      }
      await sendPushNotification(
        contractor.id,
        isNew ? 'Missed Call (After Hours)' : `Repeat Caller (${lead.call_count}x)`,
        `Call from ${body.From} while closed`,
        { leadId: lead.id }
      );
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
  const { DialCallStatus, From, To } = req.body as Record<string, string>;

  try {
    // Only handle missed calls (no-answer, busy, failed)
    if (['no-answer', 'busy', 'failed'].includes(DialCallStatus)) {
      const contractor = await lookupContractorByTwilioNumber(To);
      if (contractor) {
        const afterHours = !isWithinWorkingHours(contractor);
        const { lead, isNew } = await findOrCreateLead(contractor.id, From, afterHours);
        if (isNew) {
          await initiateConsentSms(lead, contractor);
        }
        await sendPushNotification(
          contractor.id,
          isNew ? 'Missed Call' : `Repeat Caller (${lead.call_count}x)`,
          `Missed call from ${From}`,
          { leadId: lead.id }
        );
      }
    }
  } catch (err) {
    console.error('Error handling voice status callback:', err);
  }

  // Always respond 200 to Twilio
  res.status(200).send();
});

export default router;
