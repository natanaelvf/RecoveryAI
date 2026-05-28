import { supabase } from '../config/supabase';
import { Lead, LeadStatus, Contractor, Locale } from '../types';
import { sendSms } from './twilio';
import { sendPushNotification } from './notifications';

// --- SMS Templates (bilingual: Finnish + English) ---
// Finnish translations should be reviewed by a native speaker before launch.

type TemplateSet = {
  consentRequest: (businessName: string) => string;
  askIssue: (businessName: string) => string;
  askUrgency: () => string;
  askName: () => string;
  bookingLink: (businessName: string, calendlyUrl: string, urgency?: string) => string;
  bookingConfirmation: (businessName: string, bookingTime: string) => string;
  satisfactionFollowup: (businessName: string) => string;
  noConsent: () => string;
};

const TEMPLATES_EN: TemplateSet = {
  consentRequest: (businessName) =>
    `Hi! You just called ${businessName} but we couldn't answer. We'd like to help you via text. Reply YES to continue or STOP to opt out. Msg & data rates may apply.`,

  askIssue: (businessName) =>
    `Great, thanks for opting in! Can you briefly describe the issue you need help with? (e.g. "leaking pipe", "broken AC")`,

  askUrgency: () =>
    `How urgent is this?\n1 - Not urgent, can wait a few days\n2 - Soon, within 24-48h\n3 - Urgent, need help today\n4 - Emergency, need help now`,

  askName: () =>
    `Thanks! What's your name so we can address you properly?`,

  bookingLink: (businessName, calendlyUrl, urgency) => {
    switch (urgency) {
      case 'emergency':
      case 'high':
        return `⚡ ${businessName} will try to call you back ASAP. In the meantime, book the earliest available slot: ${calendlyUrl}\nWe'll confirm once it's booked!`;
      case 'medium':
        return `Thanks! Please book a time within the next 2-3 days with ${businessName}: ${calendlyUrl}\nWe'll confirm once it's booked!`;
      case 'low':
        return `Thanks! Book a time this week with ${businessName}: ${calendlyUrl}\nWe'll confirm once it's booked!`;
      default:
        return `Thanks! Here's a link to book a time with ${businessName}: ${calendlyUrl}\nWe'll confirm once it's booked!`;
    }
  },

  bookingConfirmation: (businessName, bookingTime) =>
    `Your appointment with ${businessName} is confirmed for ${bookingTime}. We look forward to helping you!`,

  satisfactionFollowup: (businessName) =>
    `Hi! How was your experience with ${businessName}? Reply with a number 1-5 (1=poor, 5=excellent) and any feedback you'd like to share.`,

  noConsent: () =>
    `No problem! We won't text you again. If you need help in the future, give us a call.`,
};

const TEMPLATES_FI: TemplateSet = {
  consentRequest: (businessName) =>
    `Hei! Yritit juuri soittaa yritykseen ${businessName}, mutta emme päässeet vastaamaan. Haluaisimme auttaa sinua tekstiviestillä. Vastaa KYLLÄ jatkaaksesi tai EI lopettaaksesi. Tietosuojaseloste: https://unmissed.io/privacy`,

  askIssue: (_businessName) =>
    `Kiitos! Voitko lyhyesti kuvata ongelman, johon tarvitset apua? (esim. "vuotava putki", "rikki mennyt ilmastointi")`,

  askUrgency: () =>
    `Kuinka kiireellinen asia on?\n1 - Ei kiire, voi odottaa muutaman päivän\n2 - Pian, 24-48h sisällä\n3 - Kiireellinen, tarvitsen apua tänään\n4 - Hätätilanne, tarvitsen apua nyt`,

  askName: () =>
    `Kiitos! Mikä on nimesi, jotta voimme puhutella sinua oikein?`,

  bookingLink: (businessName, calendlyUrl, urgency) => {
    switch (urgency) {
      case 'emergency':
      case 'high':
        return `⚡ ${businessName} yrittää soittaa sinulle takaisin pian. Varaa ensimmäinen vapaa aika: ${calendlyUrl}\nVahvistamme kun varaus on tehty!`;
      case 'medium':
        return `Kiitos! Varaa aika seuraavan 2-3 päivän sisällä yrityksen ${businessName} kanssa: ${calendlyUrl}\nVahvistamme kun varaus on tehty!`;
      case 'low':
        return `Kiitos! Varaa sinulle sopiva aika tämän viikon aikana yrityksen ${businessName} kanssa: ${calendlyUrl}\nVahvistamme kun varaus on tehty!`;
      default:
        return `Kiitos! Tässä linkki ajanvaraukseen yrityksen ${businessName} kanssa: ${calendlyUrl}\nVahvistamme kun varaus on tehty!`;
    }
  },

  bookingConfirmation: (businessName, bookingTime) =>
    `Ajanvarauksesi yrityksen ${businessName} kanssa on vahvistettu ajankohtaan ${bookingTime}. Odotamme innolla palvelemistasi!`,

  satisfactionFollowup: (businessName) =>
    `Hei! Miten kokemuksesi yrityksen ${businessName} kanssa sujui? Vastaa numerolla 1-5 (1=huono, 5=erinomainen) ja kerro vapaasti palautetta.`,

  noConsent: () =>
    `Ei hätää! Emme lähetä sinulle enää viestejä. Jos tarvitset apua tulevaisuudessa, soita meille.`,
};

const TEMPLATES_PT: TemplateSet = {
  consentRequest: (businessName) =>
    `Olá! Você ligou para ${businessName} mas não conseguimos atender. Gostaríamos de ajudá-lo por SMS. Responda SIM para continuar ou NÃO para cancelar. Política de privacidade: https://unmissed.io/privacy`,

  askIssue: (_businessName) =>
    `Obrigado! Pode descrever brevemente o problema que precisa resolver? (ex: "cano vazando", "ar-condicionado quebrado")`,

  askUrgency: () =>
    `Qual a urgência?\n1 - Sem pressa, pode esperar alguns dias\n2 - Em breve, nas próximas 24-48h\n3 - Urgente, preciso de ajuda hoje\n4 - Emergência, preciso de ajuda agora`,

  askName: () =>
    `Obrigado! Qual é o seu nome?`,

  bookingLink: (businessName, calendlyUrl, urgency) => {
    switch (urgency) {
      case 'emergency':
      case 'high':
        return `⚡ ${businessName} vai tentar ligar-lhe de volta em breve. Agende o primeiro horário disponível: ${calendlyUrl}\nConfirmaremos assim que o agendamento for feito!`;
      case 'medium':
        return `Obrigado! Agende um horário nos próximos 2-3 dias com ${businessName}: ${calendlyUrl}\nConfirmaremos assim que o agendamento for feito!`;
      case 'low':
        return `Obrigado! Agende um horário esta semana com ${businessName}: ${calendlyUrl}\nConfirmaremos assim que o agendamento for feito!`;
      default:
        return `Obrigado! Aqui está o link para agendar um horário com ${businessName}: ${calendlyUrl}\nConfirmaremos assim que o agendamento for feito!`;
    }
  },

  bookingConfirmation: (businessName, bookingTime) =>
    `Seu agendamento com ${businessName} está confirmado para ${bookingTime}. Estamos ansiosos para ajudá-lo!`,

  satisfactionFollowup: (businessName) =>
    `Olá! Como foi sua experiência com ${businessName}? Responda com um número de 1 a 5 (1=ruim, 5=excelente) e deixe seu comentário.`,

  noConsent: () =>
    `Sem problemas! Não enviaremos mais mensagens. Se precisar de ajuda no futuro, ligue para nós.`,
};

/**
 * Get the correct template set based on contractor locale.
 * Exported as getSmsTemplates for use by cron jobs and webhooks.
 */
export function getSmsTemplates(locale: Locale): TemplateSet {
  switch (locale) {
    case 'fi': return TEMPLATES_FI;
    case 'pt': return TEMPLATES_PT;
    default:   return TEMPLATES_EN;
  }
}

// Internal alias for use within this module.
const getTemplates = getSmsTemplates;

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
 * Wrapped in try/catch so a Twilio failure doesn't crash the state machine.
 * Returns true on success, false on failure.
 */
async function sendAndRecord(
  lead: Lead,
  fromNumber: string,
  body: string
): Promise<boolean> {
  try {
    const sid = await sendSms(lead.caller_phone, fromNumber, body);
    await recordMessage(lead.id, 'outbound', body, sid);
    return true;
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error(`[sms] Failed to send SMS to ${lead.caller_phone}: ${errorMsg}`);

    // If SMS cap reached, don't record anything — just log
    if (errorMsg === 'SMS_CAP_REACHED') {
      console.warn(`[sms] SMS cap reached, skipping message for lead ${lead.id}`);
    }

    return false;
  }
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
 * Re-fetch the lead from the database to avoid stale data / race conditions.
 */
async function refreshLead(leadId: string): Promise<Lead | null> {
  const { data, error } = await supabase
    .from('leads')
    .select('*')
    .eq('id', leadId)
    .single();

  if (error || !data) return null;
  return data as Lead;
}

/**
 * Main SMS state machine — processes inbound SMS based on lead's current status.
 * Re-fetches the lead at the start to avoid race conditions with stale data.
 */
export async function handleInboundSms(
  leadInput: Lead,
  messageBody: string,
  contractor: Contractor
): Promise<void> {
  const body = messageBody.trim();
  const fromNumber = contractor.twilio_phone_number;

  // Re-fetch lead to get latest status (fix #1: race condition prevention)
  const lead = await refreshLead(leadInput.id);
  if (!lead) {
    console.error(`[sms] Lead ${leadInput.id} not found during re-fetch`);
    return;
  }

  // SMS is always in the contractor's language (design rule)
  const T = getTemplates(contractor.locale ?? 'fi');

  // Record inbound message
  await recordMessage(lead.id, 'inbound', body);

  switch (lead.status) {
    // --- Consent phase ---
    case LeadStatus.ConsentSent: {
      const upper = body.toUpperCase();
      // Accept consent in EN/FI/PT
      const yesWords = ['YES', 'KYLLÄ', 'KYLLA', 'SIM'];
      const noWords = ['STOP', 'EI', 'NÃO', 'NAO', 'NO'];
      if (yesWords.includes(upper)) {
        await updateLeadStatus(lead.id, LeadStatus.QualifyingIssue, {
          consent_given: true,
          consent_given_at: new Date().toISOString(),
        });
        const msg = T.askIssue(contractor.business_name);
        await sendAndRecord(lead, fromNumber, msg);
      } else if (noWords.includes(upper)) {
        await updateLeadStatus(lead.id, LeadStatus.NoConsent);
        const msg = T.noConsent();
        await sendAndRecord(lead, fromNumber, msg);
      } else {
        // Unrecognized reply — resend consent prompt
        const msg = T.consentRequest(contractor.business_name);
        await sendAndRecord(lead, fromNumber, msg);
      }
      break;
    }

    // --- Qualifying: collecting issue description (fix #2: dedicated state) ---
    case LeadStatus.QualifyingIssue:
    case LeadStatus.Qualifying: {
      // Store the issue description
      await supabase
        .from('leads')
        .update({ issue_description: body, updated_at: new Date().toISOString() })
        .eq('id', lead.id);

      // Advance to urgency step
      await updateLeadStatus(lead.id, LeadStatus.QualifyingUrgency);

      // Ask urgency
      const msg = T.askUrgency();
      await sendAndRecord(lead, fromNumber, msg);
      break;
    }

    // --- Qualifying: collecting urgency (fix #2: dedicated state) ---
    case LeadStatus.QualifyingUrgency: {
      const urgency = parseUrgency(body);
      if (urgency) {
        await supabase
          .from('leads')
          .update({ urgency, updated_at: new Date().toISOString() })
          .eq('id', lead.id);

        // Send high-priority push for emergency/urgent leads (regardless of hours)
        if (urgency === 'emergency' || urgency === 'high') {
          await sendPushNotification(
            contractor.id,
            urgency === 'emergency'
              ? '🚨 EMERGENCY — Call Back Now!'
              : '⚡ Urgent Lead — Call Back Soon',
            `${lead.caller_phone}: ${lead.issue_description || 'Unknown issue'}`,
            { leadId: lead.id, priority: 'high' }
          );
        }

        // Advance to name collection (fix #22)
        await updateLeadStatus(lead.id, LeadStatus.QualifyingName);

        const msg = T.askName();
        await sendAndRecord(lead, fromNumber, msg);
      } else {
        // Unrecognized — re-ask urgency
        const msg = T.askUrgency();
        await sendAndRecord(lead, fromNumber, msg);
      }
      break;
    }

    // --- Qualifying: collecting name (fix #22: name collection step) ---
    case LeadStatus.QualifyingName: {
      // Store the caller name
      await supabase
        .from('leads')
        .update({ caller_name: body, updated_at: new Date().toISOString() })
        .eq('id', lead.id);

      // Send urgency-aware booking link
      const msg = T.bookingLink(contractor.business_name, contractor.calendly_url, lead.urgency);
      await sendAndRecord(lead, fromNumber, msg);
      await updateLeadStatus(lead.id, LeadStatus.BookingSent);
      break;
    }

    // --- Booking sent: waiting for Calendly webhook, but user might reply ---
    case LeadStatus.BookingSent: {
      // Re-send the booking link if they reply while waiting
      const msg = T.bookingLink(contractor.business_name, contractor.calendly_url, lead.urgency);
      await sendAndRecord(lead, fromNumber, msg);
      break;
    }

    // --- Satisfaction follow-up (fix #13: search entire reply for score) ---
    case LeadStatus.FollowedUp: {
      // Search the entire reply for a digit 1-5
      const match = body.match(/[1-5]/);
      if (match) {
        const score = parseInt(match[0], 10);
        // Extract remaining text as feedback (remove the score digit)
        const feedbackText = body.replace(/[1-5]/, '').trim() || null;

        await supabase
          .from('leads')
          .update({
            satisfaction_score: score,
            satisfaction_feedback: feedbackText,
            updated_at: new Date().toISOString(),
          })
          .eq('id', lead.id);
        await updateLeadStatus(lead.id, LeadStatus.Completed);

        // If score <= 2, alert the contractor
        if (score <= 2) {
          await sendPushNotification(
            contractor.id,
            '⚠️ Low Satisfaction Score',
            `${lead.caller_name || lead.caller_phone} rated ${score}/5: ${feedbackText || 'No comment'}`,
            { leadId: lead.id }
          );
        }
      } else {
        // Re-ask
        const msg = T.satisfactionFollowup(contractor.business_name);
        await sendAndRecord(lead, fromNumber, msg);
      }
      break;
    }

    default: {
      console.warn(`Received SMS for lead ${lead.id} in unexpected status: ${lead.status}`);
      break;
    }
  }
}

/**
 * Kick off the consent flow for a newly missed lead.
 * Called after a missed call is detected.
 * Also schedules a consent timeout (fix #20).
 */
export async function initiateConsentSms(
  lead: Lead,
  contractor: Contractor
): Promise<void> {
  // SMS is always in the contractor's language (design rule)
  const T = getTemplates(contractor.locale ?? 'fi');
  const sent = await sendAndRecord(lead, contractor.twilio_phone_number,
    T.consentRequest(contractor.business_name));

  if (sent) {
    await updateLeadStatus(lead.id, LeadStatus.ConsentSent);

    // Schedule consent timeout: if no reply in 30 minutes, mark as no_consent
    const timeoutAt = new Date(Date.now() + 30 * 60 * 1000).toISOString();
    await supabase.from('scheduled_tasks').insert({
      lead_id: lead.id,
      task_type: 'consent_timeout',
      execute_at: timeoutAt,
      executed: false,
    });
  }
}
