// --- Enums ---

export enum LeadStatus {
  Missed = 'missed',
  ConsentSent = 'consent_sent',
  Qualifying = 'qualifying',
  QualifyingIssue = 'qualifying_issue',
  QualifyingUrgency = 'qualifying_urgency',
  QualifyingName = 'qualifying_name',
  BookingSent = 'booking_sent',
  Booked = 'booked',
  Completed = 'completed',
  FollowedUp = 'followed_up',
  DnrAlert = 'dnr_alert',
  NoConsent = 'no_consent',
}

export enum Urgency {
  Unknown = 'unknown',
  Low = 'low',
  Medium = 'medium',
  High = 'high',
  Emergency = 'emergency',
}

export type NumberSetupType = 'forwarding' | 'new_number';
export type Tier = 'starter' | 'growth' | 'pro';
export type Locale = 'fi' | 'en';
export type MessageDirection = 'inbound' | 'outbound';
export type ScheduledTaskType = 'dnr_check' | 'satisfaction_followup' | 'reminder' | 'consent_timeout';

// --- Database row interfaces ---

export interface Contractor {
  id: string;
  business_name: string;
  contact_name: string;
  contact_email: string;
  contact_phone: string;
  twilio_phone_number: string;
  number_setup_type: NumberSetupType;
  calendly_url: string;
  trade_type: string;
  default_job_value: number;
  urgency_threshold_urgent_min: number;
  urgency_threshold_normal_min: number;
  working_hours_start: string; // HH:MM
  working_hours_end: string;   // HH:MM
  working_days: number[];      // 0=Sun..6=Sat
  after_hours_emergency_policy: string;
  after_hours_ring: boolean;
  timezone: string;
  tier: Tier;
  locale: Locale;
  monthly_sms_cap: number;
  sms_used_this_month: number;
  stripe_customer_id: string | null;
  fcm_token: string | null;
  created_at: string;
  updated_at: string;
}

export interface Lead {
  id: string;
  contractor_id: string;
  caller_phone: string;
  caller_name: string | null;
  issue_description: string | null;
  urgency: Urgency;
  email: string | null;
  call_count: number;
  status: LeadStatus;
  consent_given: boolean;
  consent_given_at: string | null;
  booking_time: string | null;
  calendly_event_id: string | null;
  dnr_alert_sent: boolean;
  dnr_alert_sent_at: string | null;
  estimated_value: number | null;
  satisfaction_score: number | null;
  satisfaction_feedback: string | null;
  notes: string | null;
  called_during_after_hours: boolean;
  created_at: string;
  updated_at: string;
}

export interface Message {
  id: string;
  lead_id: string;
  direction: MessageDirection;
  body: string;
  twilio_message_sid: string | null;
  sent_at: string;
}

export interface ScheduledTask {
  id: string;
  lead_id: string;
  task_type: ScheduledTaskType;
  execute_at: string;
  executed: boolean;
  created_at: string;
}

// --- Twilio webhook bodies ---

export interface TwilioVoiceWebhookBody {
  CallSid: string;
  AccountSid: string;
  From: string;
  To: string;
  CallStatus: string;
  Direction: string;
  ForwardedFrom?: string;
  CallerName?: string;
  ApiVersion: string;
}

export interface TwilioSmsWebhookBody {
  MessageSid: string;
  AccountSid: string;
  From: string;
  To: string;
  Body: string;
  NumMedia: string;
  NumSegments: string;
}

// --- Express request augmentation ---

declare global {
  namespace Express {
    interface Request {
      contractorId?: string;
    }
  }
}
