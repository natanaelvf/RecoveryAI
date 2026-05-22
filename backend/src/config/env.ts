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

export const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  supabaseUrl: required('SUPABASE_URL'),
  supabaseServiceKey: required('SUPABASE_SERVICE_KEY'),
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || '',
  twilioAccountSid: required('TWILIO_ACCOUNT_SID'),
  twilioAuthToken: required('TWILIO_AUTH_TOKEN'),
  twilioPhoneNumber: required('TWILIO_PHONE_NUMBER'),
  calendlyWebhookSecret: required('CALENDLY_WEBHOOK_SECRET'),
  firebaseServiceAccountPath: required('FIREBASE_SERVICE_ACCOUNT_PATH'),
  googleWebClientId: process.env.GOOGLE_WEB_CLIENT_ID || '',
  googleClientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
} as const;
