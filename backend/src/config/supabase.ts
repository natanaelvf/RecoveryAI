import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { env } from './env';

export const supabase: SupabaseClient = createClient(
  env.supabaseUrl,
  env.supabaseServiceKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);
