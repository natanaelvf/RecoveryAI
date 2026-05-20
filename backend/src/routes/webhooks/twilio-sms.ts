import { Router, Request, Response } from 'express';
import Twilio from 'twilio';
import { supabase } from '../../config/supabase';
import { lookupContractorByTwilioNumber } from '../../services/twilio';
import { handleInboundSms } from '../../services/sms-state-machine';
import { TwilioSmsWebhookBody, Lead } from '../../types';

const router = Router();

const MessagingResponse = Twilio.twiml.MessagingResponse;

/**
 * POST / — Twilio SMS webhook: inbound SMS arrives
 */
router.post('/', async (req: Request, res: Response) => {
  const body = req.body as TwilioSmsWebhookBody;
  const twiml = new MessagingResponse();

  try {
    // Look up the contractor who owns this Twilio number
    const contractor = await lookupContractorByTwilioNumber(body.To);
    if (!contractor) {
      console.error(`No contractor found for Twilio number ${body.To}`);
      res.type('text/xml').send(twiml.toString());
      return;
    }

    // Find the lead by caller phone + contractor
    const { data: lead, error } = await supabase
      .from('leads')
      .select('*')
      .eq('contractor_id', contractor.id)
      .eq('caller_phone', body.From)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (error || !lead) {
      console.warn(`No lead found for phone ${body.From} / contractor ${contractor.id}`);
      // TODO: Optionally create a new lead for unsolicited inbound SMS
      res.type('text/xml').send(twiml.toString());
      return;
    }

    // Process through the SMS state machine
    await handleInboundSms(lead as Lead, body.Body, contractor);
  } catch (err) {
    console.error('Error handling inbound SMS:', err);
  }

  // Return empty TwiML (responses are sent asynchronously via the state machine)
  res.type('text/xml').send(twiml.toString());
});

export default router;
