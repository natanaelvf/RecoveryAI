import { supabase } from '../config/supabase';
import { Lead, LeadStatus, Contractor } from '../types';
import { sendSms } from './twilio';

// --- SMS Templates (English drafts — TODO: translate to Finnish) ---

const TEMPLATES = {
  consentRequest: (businessName: string) =>
    `Hi! You just called ${businessName} but we couldn't answer. We'd like to help you via text. Reply YES to continue or STOP to opt out. Msg & data rates may apply.`,

  askIssue: (businessName: string) =>
    `Great, thanks for opting in! Can you briefly describe the issue you need help with? (e.g. "leaking pipe", "broken AC")`,

  askUrgency: () =>
    `How urgent is this?\n1 - Not urgent, can wait a few days\n2 - Soon, within 24-48h\n3 - Urgent, need help today\n4 - Emergency, need help now`,

  bookingLink: (businessName: string, calendlyUrl: string) =>
    `Thanks! Here's a link to book a time with ${businessName}: ${calendlyUrl}\nWe'll confirm once it's booked!`,

  bookingConfirmation: (businessName: string, bookingTime: string) =>
    `Your appointment with ${businessName} is confirmed for ${bookingTime}. We look forward to helping you!`,

  satisfactionFollowup: (businessName: string) =>
    `Hi! How was your experience with ${businessName}? Reply with a number 1-5 (1=poor, 5=excellent) and any feedback you'd like to share.`,

  noConsent: () =>
    `No problem! We won't text you again. If you need help in the future, give us a call.`,

  // TODO: Add Finnish translations
} as const;

/**
 * Record a message in the messages table.
 */
async function recordMessage(
  leadId: string,
  direction: 'inbound' | 'outbound',
  body: string,
  twilioMessageSid: string | null = null
): Promise<void> {
  await supabase.from('messages').insert({
    lead_id: leadId,
    direction,
    body,
    twilio_message_sid: twilioMessageSid,
    sent_at: new Date().toISOString(),
  });
}

/**
 * Update lead status in the database.
 */
async function updateLeadStatus(
  leadId: string,
  status: LeadStatus,
  extra: Record<string, unknown> = {}
): Promise<void> {
  await supabase
    .from('leads')
    .update({ status, ...extra, updated_at: new Date().toISOString() })
    .eq('id', leadId);
}

/**
 * Send an outbound SMS and record it.
 */
async function sendAndRecord(
  lead: Lead,
  fromNumber: string,
  body: string
): Promise<void> {
  const sid = await sendSms(lead.caller_phone, fromNumber, body);
  await recordMessage(lead.id, 'outbound', body, sid);
}

/**
 * Parse urgency from reply text (1-4 mapping).
 */
function parseUrgency(text: string): string | null {
  const trimmed = text.trim();
  const map: Record<string, string> = {
    '1': 'low',
    '2': 'medium',
    '3': 'high',
    '4': 'emergency',
  };
  return map[trimmed] || null;
}

/**
 * Main SMS state machine — processes inbound SMS based on lead's current status.
 */
export async function handleInboundSms(
  lead: Lead,
  messageBody: string,
  contractor: Contractor
): Promise<void> {
  const body = messageBody.trim();
  const fromNumber = contractor.twilio_phone_number;

  // Record inbound message
  await recordMessage(lead.id, 'inbound', body);

  switch (lead.status) {
    // --- Consent phase ---
    case LeadStatus.ConsentSent: {
      const upper = body.toUpperCase();
      if (upper === 'YES' || upper === 'KYLLÄ' || upper === 'KYLLA') {
        await updateLeadStatus(lead.id, LeadStatus.OptedIn, {
          consent_given: true,
          consent_given_at: new Date().toISOString(),
        });
        const msg = TEMPLATES.askIssue(contractor.business_name);
        await sendAndRecord(lead, fromNumber, msg);
        await updateLeadStatus(lead.id, LeadStatus.Qualifying);
      } else if (upper === 'STOP' || upper === 'EI') {
        await updateLeadStatus(lead.id, LeadStatus.NoConsent);
        const msg = TEMPLATES.noConsent();
        await sendAndRecord(lead, fromNumber, msg);
      } else {
        // Unrecognized reply — resend consent prompt
        const msg = TEMPLATES.consentRequest(contractor.business_name);
        await sendAndRecord(lead, fromNumber, msg);
      }
      break;
    }

    // --- Qualifying: collecting issue description ---
    case LeadStatus.Qualifying: {
      // Check if we already have the issue_description set — if not, this is the issue reply
      if (!lead.issue_description) {
        await supabase
          .from('leads')
          .update({ issue_description: body, updated_at: new Date().toISOString() })
          .eq('id', lead.id);

        // Ask urgency
        const msg = TEMPLATES.askUrgency();
        await sendAndRecord(lead, fromNumber, msg);
      } else {
        // This should be the urgency reply
        const urgency = parseUrgency(body);
        if (urgency) {
          await supabase
            .from('leads')
            .update({ urgency, updated_at: new Date().toISOString() })
            .eq('id', lead.id);

          // Send booking link
          const msg = TEMPLATES.bookingLink(contractor.business_name, contractor.calendly_url);
          await sendAndRecord(lead, fromNumber, msg);
          await updateLeadStatus(lead.id, LeadStatus.BookingSent);
        } else {
          // Unrecognized — re-ask urgency
          const msg = TEMPLATES.askUrgency();
          await sendAndRecord(lead, fromNumber, msg);
        }
      }
      break;
    }

    // --- Booking sent: waiting for Calendly webhook, but user might reply ---
    case LeadStatus.BookingSent: {
      // TODO: Handle free-text replies while waiting for booking
      // Could re-send the booking link or acknowledge
      const msg = TEMPLATES.bookingLink(contractor.business_name, contractor.calendly_url);
      await sendAndRecord(lead, fromNumber, msg);
      break;
    }

    // --- Satisfaction follow-up ---
    case LeadStatus.FollowedUp: {
      // Parse satisfaction score
      const score = parseInt(body, 10);
      if (score >= 1 && score <= 5) {
        // Extract remaining text as feedback
        const feedbackText = body.replace(/^\d\s*/, '').trim() || null;
        await supabase
          .from('leads')
          .update({
            satisfaction_score: score,
            satisfaction_feedback: feedbackText,
            updated_at: new Date().toISOString(),
          })
          .eq('id', lead.id);
        await updateLeadStatus(lead.id, LeadStatus.Completed);
      } else {
        // Re-ask
        const msg = TEMPLATES.satisfactionFollowup(contractor.business_name);
        await sendAndRecord(lead, fromNumber, msg);
      }
      break;
    }

    default: {
      // TODO: Handle unexpected inbound messages in other statuses
      console.warn(`Received SMS for lead ${lead.id} in unexpected status: ${lead.status}`);
      break;
    }
  }
}

/**
 * Kick off the consent flow for a newly missed lead.
 * Called after a missed call is detected.
 */
export async function initiateConsentSms(
  lead: Lead,
  contractor: Contractor
): Promise<void> {
  const msg = TEMPLATES.consentRequest(contractor.business_name);
  await sendAndRecord(lead, contractor.twilio_phone_number, msg);
  await updateLeadStatus(lead.id, LeadStatus.ConsentSent);
}
