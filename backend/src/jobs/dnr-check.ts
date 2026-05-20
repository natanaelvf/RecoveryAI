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
 * Called by cron every 15 minutes.
 */
export async function runDnrCheck(): Promise<void> {
  console.log('[cron] Running DNR check...');

  try {
    // Find leads stuck in consent_sent or booking_sent for too long
    // Use the contractor's urgency_threshold_normal_min as the cutoff
    const { data: overdue, error } = await supabase
      .from('leads')
      .select('*, contractors!inner(*)')
      .in('status', [LeadStatus.ConsentSent, LeadStatus.BookingSent])
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
      const thresholdMs = (contractor.urgency_threshold_normal_min || 60) * 60 * 1000;
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
          `${lead.caller_phone} hasn't responded after ${contractor.urgency_threshold_normal_min} minutes`,
          { leadId: lead.id }
        );

        console.log(`[cron] DNR alert sent for lead ${lead.id}`);
      }
    }
  } catch (err) {
    console.error('[cron] DNR check failed:', err);
  }
}
