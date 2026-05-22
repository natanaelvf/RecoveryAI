import { supabase } from '../config/supabase';
import { LeadStatus } from '../types';

/**
 * Consent timeout job.
 *
 * Finds scheduled_tasks of type 'consent_timeout' that are due and not yet
 * executed. For each, if the lead is still in 'consent_sent' status, it
 * transitions the lead to 'no_consent' (no further contact).
 *
 * Called by cron every 5 minutes.
 */
export async function runConsentTimeout(): Promise<void> {
  console.log('[cron] Running consent timeout check...');

  try {
    const now = new Date().toISOString();

    const { data: tasks, error } = await supabase
      .from('scheduled_tasks')
      .select('*, leads!inner(*)')
      .eq('task_type', 'consent_timeout')
      .eq('executed', false)
      .lte('execute_at', now);

    if (error) {
      console.error('[cron] Consent timeout query error:', error.message);
      return;
    }

    if (!tasks || tasks.length === 0) {
      return;
    }

    for (const task of tasks) {
      const lead = task.leads;

      // Only timeout if the lead is still waiting for consent
      if (lead.status === LeadStatus.ConsentSent) {
        await supabase
          .from('leads')
          .update({
            status: LeadStatus.NoConsent,
            updated_at: new Date().toISOString(),
          })
          .eq('id', lead.id);

        console.log(`[cron] Consent timeout: lead ${lead.id} → no_consent`);
      }

      // Mark task as executed regardless (even if lead already moved on)
      await supabase
        .from('scheduled_tasks')
        .update({ executed: true })
        .eq('id', task.id);
    }
  } catch (err) {
    console.error('[cron] Consent timeout check failed:', err);
  }
}
