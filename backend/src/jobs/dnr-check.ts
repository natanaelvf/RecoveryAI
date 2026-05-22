import { supabase } from '../config/supabase';
import { LeadStatus } from '../types';
import { sendPushNotification } from '../services/notifications';

/**
 * DNR (Did Not Respond) check job.
 *
 * Queries leads that have been in 'consent_sent' or 'booking_sent' status
 * for longer than the contractor's urgency threshold, and sends a push
 * notification alerting the contractor.
 *
 * Uses urgency_threshold_urgent_min for high/emergency leads,
 * and urgency_threshold_normal_min for others.
 *
 * Called by cron every 15 minutes.
 */
export async function runDnrCheck(): Promise<void> {
  console.log('[cron] Running DNR check...');

  try {
    // Find leads stuck in consent_sent, qualifying sub-states, or booking_sent
    const { data: overdue, error } = await supabase
      .from('leads')
      .select('*, contractors!inner(*)')
      .in('status', [
        LeadStatus.ConsentSent,
        LeadStatus.QualifyingIssue,
        LeadStatus.QualifyingUrgency,
        LeadStatus.QualifyingName,
        LeadStatus.BookingSent,
      ])
      .eq('dnr_alert_sent', false);

    if (error) {
      console.error('[cron] DNR check query error:', error.message);
      return;
    }

    if (!overdue || overdue.length === 0) {
      return;
    }

    const now = Date.now();

    for (const row of overdue) {
      const lead = row;
      const contractor = row.contractors;

      // Fix #15: Use the appropriate threshold based on lead urgency
      const isUrgent = ['high', 'emergency'].includes(lead.urgency);
      const thresholdMin = isUrgent
        ? (contractor.urgency_threshold_urgent_min || 60)
        : (contractor.urgency_threshold_normal_min || 1440);
      const thresholdMs = thresholdMin * 60 * 1000;
      const leadAge = now - new Date(lead.created_at).getTime();

      if (leadAge >= thresholdMs) {
        // Mark DNR alert sent
        await supabase
          .from('leads')
          .update({
            dnr_alert_sent: true,
            dnr_alert_sent_at: new Date().toISOString(),
            status: LeadStatus.DnrAlert,
            updated_at: new Date().toISOString(),
          })
          .eq('id', lead.id);

        // Send push notification
        await sendPushNotification(
          contractor.id,
          'Lead Not Responding',
          `${lead.caller_phone} hasn't responded after ${thresholdMin} min (urgency: ${lead.urgency})`,
          { leadId: lead.id }
        );

        console.log(`[cron] DNR alert sent for lead ${lead.id} (${lead.urgency}, threshold: ${thresholdMin}min)`);
      }
    }
  } catch (err) {
    console.error('[cron] DNR check failed:', err);
  }
}

