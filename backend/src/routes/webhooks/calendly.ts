import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { env } from '../../config/env';
import { supabase } from '../../config/supabase';
import { LeadStatus } from '../../types';
import { sendSms } from '../../services/twilio';
import { sendPushNotification } from '../../services/notifications';

const router = Router();

/**
 * Verify Calendly webhook signature.
 */
function verifyCalendlySignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  // TODO: Confirm Calendly's exact signing scheme (HMAC-SHA256 is typical)
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expected)
  );
}

/**
 * POST / — Calendly webhook: booking created
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    // Verify signature
    // Fix #8: Use the raw body buffer for signature verification instead of
    // re-serializing JSON (which may alter key order / whitespace).
    const signature = req.headers['calendly-webhook-signature'] as string || '';
    const rawBody = (req as Request & { rawBody?: string }).rawBody || JSON.stringify(req.body);

    if (!verifyCalendlySignature(rawBody, signature, env.calendlyWebhookSecret)) {
      res.status(401).json({ error: 'Invalid webhook signature' });
      return;
    }

    const event = req.body;

    // Only handle invitee.created events
    if (event.event !== 'invitee.created') {
      res.status(200).json({ ok: true });
      return;
    }

    const payload = event.payload;
    const inviteeEmail = payload?.email as string | undefined;
    const inviteePhone = payload?.questions_and_answers?.find(
      (q: { question: string; answer: string }) =>
        q.question.toLowerCase().includes('phone')
    )?.answer as string | undefined;
    const eventStartTime = payload?.event?.start_time as string | undefined;
    const calendlyEventId = payload?.event?.uri as string | undefined;

    // Match to a lead by phone number
    // Fix #21: Removed email fallback — the SMS flow never collects email,
    // so matching by email would never work. Only match by phone.
    if (!inviteePhone) {
      console.warn('Calendly webhook: no phone number to match lead');
      res.status(200).json({ ok: true });
      return;
    }

    const { data: lead, error } = await supabase
      .from('leads')
      .select('*')
      .eq('caller_phone', inviteePhone)
      .eq('status', LeadStatus.BookingSent)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (error || !lead) {
      console.warn('Calendly webhook: no matching lead found');
      res.status(200).json({ ok: true });
      return;
    }

    // Update lead to booked
    await supabase
      .from('leads')
      .update({
        status: LeadStatus.Booked,
        booking_time: eventStartTime || null,
        calendly_event_id: calendlyEventId || null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', lead.id);

    // Look up the contractor to get Twilio number and business name
    const { data: contractor } = await supabase
      .from('contractors')
      .select('*')
      .eq('id', lead.contractor_id)
      .single();

    if (contractor && eventStartTime) {
      // Send confirmation SMS
      const formattedTime = new Date(eventStartTime).toLocaleString();
      const confirmMsg = `Your appointment with ${contractor.business_name} is confirmed for ${formattedTime}. We look forward to helping you!`;
      await sendSms(lead.caller_phone, contractor.twilio_phone_number, confirmMsg);

      // Send push notification to contractor
      await sendPushNotification(
        contractor.id,
        'New Booking!',
        `${lead.caller_phone} booked for ${formattedTime}`,
        { leadId: lead.id }
      );
    }

    // Schedule satisfaction follow-up task
    if (eventStartTime) {
      const followupTime = new Date(
        new Date(eventStartTime).getTime() + 24 * 60 * 60 * 1000
      ).toISOString();

      await supabase.from('scheduled_tasks').insert({
        lead_id: lead.id,
        task_type: 'satisfaction_followup',
        execute_at: followupTime,
        executed: false,
      });
    }

    res.status(200).json({ ok: true });
  } catch (err) {
    console.error('Error handling Calendly webhook:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
