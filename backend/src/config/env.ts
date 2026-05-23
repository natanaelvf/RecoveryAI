import dotenv from 'dotenv';
import path from 'path';

// Load environment-specific .env file based on NODE_ENV.
// Defaults to .env.dev for local development.
const envFile = process.env.NODE_ENV === 'production' ? '.env.prod' : '.env.dev';
dotenv.config({ path: path.resolve(process.cwd(), envFile) });

// Fallback: also try plain .env for backward compatibility
dotenv.config();

function required(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

/**
 * Optional env var — logs a warning if missing and returns the fallback.
 * Use for services that can degrade gracefully (FCM, Calendly).
 */
function optional(key: string, fallback: string, warningMsg: string): string {
  const value = process.env[key];
  if (!value) {
    console.warn(`[env] ${warningMsg}`);
    return fallback;
  }
  return value;
}

export const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  supabaseUrl: required('SUPABASE_URL'),
  supabaseServiceKey: required('SUPABASE_SERVICE_KEY'),
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || '',
  twilioAccountSid: required('TWILIO_ACCOUNT_SID'),
  twilioAuthToken: required('TWILIO_AUTH_TOKEN'),
  twilioPhoneNumber: required('TWILIO_PHONE_NUMBER'),
  // Optional: Calendly webhook signature verification is disabled if not set
  calendlyWebhookSecret: optional(
    'CALENDLY_WEBHOOK_SECRET',
    '',
    'CALENDLY_WEBHOOK_SECRET not set — Calendly webhook signature verification is DISABLED'
  ),
  // Optional: Push notifications are disabled if Firebase service account is not set
  // TODO: Test with frontend integration once Firebase project is created
  firebaseServiceAccountPath: optional(
    'FIREBASE_SERVICE_ACCOUNT_PATH',
    '',
    'FIREBASE_SERVICE_ACCOUNT_PATH not set — push notifications are DISABLED'
  ),
  googleWebClientId: process.env.GOOGLE_WEB_CLIENT_ID || '',
  googleClientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
} as const;
