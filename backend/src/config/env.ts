import dotenv from 'dotenv';

dotenv.config();

function required(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

export const env = {
  port: parseInt(process.env.PORT || '3000', 10),
  supabaseUrl: required('SUPABASE_URL'),
  supabaseServiceKey: required('SUPABASE_SERVICE_KEY'),
  twilioAccountSid: required('TWILIO_ACCOUNT_SID'),
  twilioAuthToken: required('TWILIO_AUTH_TOKEN'),
  twilioPhoneNumber: required('TWILIO_PHONE_NUMBER'),
  calendlyWebhookSecret: required('CALENDLY_WEBHOOK_SECRET'),
  firebaseServiceAccountPath: required('FIREBASE_SERVICE_ACCOUNT_PATH'),
} as const;
