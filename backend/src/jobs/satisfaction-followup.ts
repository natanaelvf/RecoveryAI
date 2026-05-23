import { supabase } from '../config/supabase';
import { LeadStatus, Locale } from '../types';
import { sendSms } from '../services/twilio';
import { getSmsTemplates } from '../services/sms-state-machine';

/**
 * Satisfaction follow-up job.
 *
 * Queries scheduled_tasks of type 'satisfaction_followup' that are due
 * and not yet executed, then sends a satisfaction SMS to the lead.
 *
 * Called by cron every 30 minutes.
 */
export async function runSatisfactionFollowup(): Promise<void> {
  console.log('[cron] Running satisfaction follow-up check...');

  try {
    const now = new Date().toISOString();

    const { data: tasks, error } = await supabase
      .from('scheduled_tasks')
      .select('*, leads!inner(*, contractors!inner(*))')
      .eq('task_type', 'satisfaction_followup')
      .eq('executed', false)
      .lte('execute_at', now);

    if (error) {
      console.error('[cron] Satisfaction followup query error:', error.message);
      return;
    }

    if (!tasks || tasks.length === 0) {
      return;
    }

    for (const task of tasks) {
      const lead = task.leads;
      const contractor = lead.contractors;

      // Use locale-aware SMS template
      const T = getSmsTemplates((contractor.locale as Locale) ?? 'fi');
      const message = T.satisfactionFollowup(contractor.business_name);

      try {
        await sendSms(lead.caller_phone, contractor.twilio_phone_number, message);

        // Record the outbound message
        await supabase.from('messages').insert({
          lead_id: lead.id,
          direction: 'outbound',
          body: message,
          sent_at: new Date().toISOString(),
        });

        // Update lead status
        await supabase
          .from('leads')
          .update({
            status: LeadStatus.FollowedUp,
            updated_at: new Date().toISOString(),
          })
          .eq('id', lead.id);

        // Mark task as executed
        await supabase
          .from('scheduled_tasks')
          .update({ executed: true })
          .eq('id', task.id);

        console.log(`[cron] Satisfaction followup sent for lead ${lead.id}`);
      } catch (smsErr) {
        console.error(`[cron] Failed to send satisfaction SMS for lead ${lead.id}:`, smsErr);
      }
    }
  } catch (err) {
    console.error('[cron] Satisfaction followup failed:', err);
  }
}
