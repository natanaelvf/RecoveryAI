import { supabase } from '../config/supabase';

/**
 * Monthly SMS usage reset job.
 *
 * Resets sms_used_this_month to 0 for all contractors.
 * Called by cron on the 1st of each month at midnight.
 */
export async function runSmsReset(): Promise<void> {
  console.log('[cron] Running monthly SMS usage reset...');

  try {
    const { error } = await supabase
      .from('contractors')
      .update({ sms_used_this_month: 0 })
      .neq('sms_used_this_month', 0); // Only update rows that need it

    if (error) {
      console.error('[cron] SMS reset error:', error.message);
      return;
    }

    console.log('[cron] Monthly SMS usage reset complete');
  } catch (err) {
    console.error('[cron] SMS reset failed:', err);
  }
}
