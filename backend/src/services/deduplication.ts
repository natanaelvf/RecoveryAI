import { supabase } from '../config/supabase';
import { Lead } from '../types';

export interface FindOrCreateResult {
  lead: Lead;
  isNew: boolean;
}

/**
 * Find an existing lead for this caller + contractor within the last 24 hours,
 * or create a new one. Increments call_count on duplicates.
 * Returns { lead, isNew } so callers know whether to trigger the SMS flow.
 */
export async function findOrCreateLead(
  contractorId: string,
  callerPhone: string,
  calledDuringAfterHours: boolean
): Promise<FindOrCreateResult> {
  const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  // Check for existing recent lead from same caller
  const { data: existing, error: findError } = await supabase
    .from('leads')
    .select('*')
    .eq('contractor_id', contractorId)
    .eq('caller_phone', callerPhone)
    .gte('created_at', twentyFourHoursAgo)
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  if (!findError && existing) {
    // Duplicate call — increment call_count
    const { data: updated, error: updateError } = await supabase
      .from('leads')
      .update({
        call_count: (existing as Lead).call_count + 1,
        updated_at: new Date().toISOString(),
      })
      .eq('id', existing.id)
      .select('*')
      .single();

    if (updateError || !updated) {
      throw new Error(`Failed to update lead call_count: ${updateError?.message}`);
    }

    return { lead: updated as Lead, isNew: false };
  }

  // Look up contractor's default job value for estimated_value and default locale
  const { data: contractor } = await supabase
    .from('contractors')
    .select('default_job_value, locale')
    .eq('id', contractorId)
    .single();

  // No recent lead — create a new one
  const { data: newLead, error: insertError } = await supabase
    .from('leads')
    .insert({
      contractor_id: contractorId,
      caller_phone: callerPhone,
      urgency: 'unknown',
      call_count: 1,
      status: 'missed',
      consent_given: false,
      dnr_alert_sent: false,
      called_during_after_hours: calledDuringAfterHours,
      estimated_value: contractor?.default_job_value ?? null,
      locale: contractor?.locale ?? 'fi',
    })
    .select('*')
    .single();

  if (insertError || !newLead) {
    throw new Error(`Failed to create lead: ${insertError?.message}`);
  }

  return { lead: newLead as Lead, isNew: true };
}
