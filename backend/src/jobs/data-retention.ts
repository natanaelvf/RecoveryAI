import { supabase } from '../config/supabase';

/**
 * Data retention job — GDPR compliance.
 *
 * Anonymizes leads older than 12 months by clearing PII fields.
 * Messages are deleted entirely.
 * Logs each anonymization to the audit_log table.
 *
 * Called by daily cron (once per day).
 */
export async function runDataRetention(): Promise<void> {
  console.log('[cron] Running data retention cleanup...');

  try {
    const cutoff = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000).toISOString();

    // Find leads older than 12 months that haven't been anonymized yet
    const { data: oldLeads, error } = await supabase
      .from('leads')
      .select('id, contractor_id')
      .lt('created_at', cutoff)
      .not('caller_phone', 'eq', 'ANONYMIZED');

    if (error) {
      console.error('[cron] Data retention query error:', error.message);
      return;
    }

    if (!oldLeads || oldLeads.length === 0) {
      console.log('[cron] No leads to anonymize');
      return;
    }

    const leadIds = oldLeads.map((l) => l.id);

    // Delete all messages for these leads
    const { error: msgError } = await supabase
      .from('messages')
      .delete()
      .in('lead_id', leadIds);

    if (msgError) {
      console.error('[cron] Failed to delete messages:', msgError.message);
    }

    // Delete scheduled tasks for these leads
    const { error: taskError } = await supabase
      .from('scheduled_tasks')
      .delete()
      .in('lead_id', leadIds);

    if (taskError) {
      console.error('[cron] Failed to delete scheduled tasks:', taskError.message);
    }

    // Anonymize PII fields on the leads
    const { error: anonError } = await supabase
      .from('leads')
      .update({
        caller_phone: 'ANONYMIZED',
        caller_name: null,
        email: null,
        issue_description: null,
        satisfaction_feedback: null,
        updated_at: new Date().toISOString(),
      })
      .in('id', leadIds);

    if (anonError) {
      console.error('[cron] Failed to anonymize leads:', anonError.message);
      return;
    }

    // Fix #16: Log each anonymization to audit_log for GDPR compliance
    const auditEntries = oldLeads.map((l) => ({
      action: 'data_retention_anonymize',
      entity_type: 'lead',
      entity_id: l.id,
      performed_by: 'system:data_retention_cron',
    }));

    const { error: auditError } = await supabase
      .from('audit_log')
      .insert(auditEntries);

    if (auditError) {
      // Non-fatal: log but don't fail the job
      console.error('[cron] Failed to write audit log:', auditError.message);
    }

    console.log(`[cron] Anonymized ${leadIds.length} leads older than 12 months`);
  } catch (err) {
    console.error('[cron] Data retention job failed:', err);
  }
}

