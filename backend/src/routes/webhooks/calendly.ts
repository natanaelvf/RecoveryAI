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
 *
 * Calendly sends a header like:
 *   Calendly-Webhook-Signature: t=timestamp,v1=signature
 *
 * The signature is an HMAC-SHA256 of "timestamp.payload" using the
 * webhook signing key (NOT the PAT — the signing key is provided
 * when you create the webhook subscription via the Calendly API).
 */
function verifyCalendlySignature(
  payload: string,
  signatureHeader: string,
  secret: string
): boolean {
  if (!signatureHeader) return false;

  // Parse the t= and v1= components
  const parts: Record<string, string> = {};
  for (const part of signatureHeader.split(',')) {
    const [key, value] = part.split('=', 2);
    if (key && value) parts[key.trim()] = value.trim();
  }

  const timestamp = parts['t'];
  const expectedSig = parts['v1'];
  if (!timestamp || !expectedSig) return false;

  // Reject if timestamp is too old (5-minute tolerance for replay protection)
  const tolerance = 5 * 60 * 1000;
  const age = Date.now() - parseInt(timestamp, 10) * 1000;
  if (isNaN(age) || age > tolerance) {
    console.warn(`[calendly] Webhook signature too old: ${age}ms`);
    return false;
  }

  // Compute expected signature: HMAC-SHA256(timestamp.payload)
  const signedPayload = `${timestamp}.${payload}`;
  const computed = crypto
    .createHmac('sha256', secret)
    .update(signedPayload)
    .digest('hex');

  try {
    return crypto.timingSafeEqual(
      Buffer.from(expectedSig),
      Buffer.from(computed)
    );
  } catch {
    return false;
  }
}

/**
 * POST / — Calendly webhook: booking created
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const signatureHeader = req.headers['calendly-webhook-signature'] as string || '';
    const rawBody = (req as Request & { rawBody?: string }).rawBody || JSON.stringify(req.body);

    // Skip signature verification if webhook secret is not configured
    if (env.calendlyWebhookSecret) {
      if (!verifyCalendlySignature(rawBody, signatureHeader, env.calendlyWebhookSecret)) {
        res.status(401).json({ error: 'Invalid webhook signature' });
        return;
      }
    } else {
      console.warn('[calendly] Webhook signature verification SKIPPED — CALENDLY_WEBHOOK_SECRET not set');
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
      // Send confirmation SMS to the lead
      // Format booking time in the contractor's timezone with Finnish locale
      const formattedTime = new Date(eventStartTime).toLocaleString('fi-FI', {
        timeZone: contractor.timezone || 'Europe/Helsinki',
        dateStyle: 'medium',
        timeStyle: 'short',
      });
      const confirmMsg = `Your appointment with ${contractor.business_name} is confirmed for ${formattedTime}. We look forward to helping you!`;
      const smsSid = await sendSms(lead.caller_phone, contractor.twilio_phone_number, confirmMsg);

      // Record the confirmation message
      await supabase.from('messages').insert({
        lead_id: lead.id,
        direction: 'outbound',
        body: confirmMsg,
        twilio_message_sid: smsSid,
        sent_at: new Date().toISOString(),
      });

      // Notify the contractor
      await sendPushNotification(
        contractor.id,
        'New Booking!',
        `${lead.caller_name || lead.caller_phone} booked for ${formattedTime}`,
        { leadId: lead.id }
      );
    }

    // NOTE: Satisfaction follow-up is NOT scheduled here.
    // It's scheduled when the contractor marks the job as completed
    // (via the Flutter app's markLeadComplete).

    res.status(200).json({ ok: true });
  } catch (err) {
    console.error('Error handling Calendly webhook:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
