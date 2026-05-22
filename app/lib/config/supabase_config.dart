import 'package:supabase_flutter/supabase_flutter.dart';

/// Convenience accessor for the Supabase client singleton.
/// Usage: `import 'package:missed_lead_recovery/config/supabase_config.dart';`
/// Then: `supabase.auth.signInWithPassword(...)` etc.
final supabase = Supabase.instance.client;
