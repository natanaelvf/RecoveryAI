-- ============================================================================
-- DEV ENVIRONMENT — Full Setup Script
-- Missed-Lead Recovery
--
-- Run this in the Supabase SQL Editor for the DEV project
-- (wuizbznbyvxauavpjrgz)
--
-- Contains: clean slate → schema → RLS → indexes → auth trigger → seed data
-- ============================================================================

BEGIN;

-- ============================================================================
-- STEP 0: CLEAN SLATE
-- Drop everything in reverse dependency order (idempotent)
-- ============================================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

DROP TABLE IF EXISTS job_costs CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS scheduled_tasks CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS leads CASCADE;
DROP TABLE IF EXISTS contractors CASCADE;

-- ============================================================================
-- STEP 1: EXTENSIONS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 2: TABLES
-- ============================================================================

-- contractors — each represents a home service business
CREATE TABLE contractors (
  id                            uuid PRIMARY KEY,  -- must equal auth.uid() — set by signup trigger
  business_name                 text NOT NULL,
  contact_name                  text NOT NULL,
  contact_email                 text NOT NULL,
  contact_phone                 text NOT NULL,
  twilio_phone_number           text NOT NULL,
  number_setup_type             text DEFAULT 'forwarding'
    CHECK (number_setup_type IN ('forwarding', 'new_number')),
  calendly_url                  text,
  trade_type                    text
    CHECK (trade_type IN ('plumber', 'hvac', 'electrician', 'roofer', 'other')),
  default_job_value             decimal,
  urgency_threshold_urgent_min  int DEFAULT 60,
  urgency_threshold_normal_min  int DEFAULT 1440,
  working_hours_start           time DEFAULT '08:00',
  working_hours_end             time DEFAULT '18:00',
  working_days                  int[] DEFAULT '{1,2,3,4,5}',
  after_hours_emergency_policy  text,
  after_hours_ring              boolean DEFAULT false,
  timezone                      text DEFAULT 'Europe/Helsinki',
  tier                          text DEFAULT 'starter'
    CHECK (tier IN ('starter', 'growth', 'pro')),
  monthly_sms_cap               int DEFAULT 50,
  sms_used_this_month           int DEFAULT 0,
  stripe_customer_id            text,
  created_at                    timestamptz DEFAULT now(),
  updated_at                    timestamptz DEFAULT now()
);
COMMENT ON TABLE contractors IS 'Contractor accounts — each represents a home service business.';

-- leads — missed call lifecycle
CREATE TABLE leads (
  id                        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  contractor_id             uuid NOT NULL REFERENCES contractors(id) ON DELETE CASCADE,
  caller_phone              text NOT NULL,
  caller_name               text,
  issue_description         text,
  urgency                   text DEFAULT 'unknown'
    CHECK (urgency IN ('unknown', 'low', 'medium', 'high', 'emergency')),
  email                     text,
  call_count                int DEFAULT 1,
  status                    text DEFAULT 'missed'
    CHECK (status IN (
      'missed', 'consent_sent', 'opted_in', 'qualifying',
      'qualifying_issue', 'qualifying_urgency', 'qualifying_name',
      'booking_sent', 'booked', 'completed', 'followed_up',
      'dnr_alert', 'no_consent'
    )),
  consent_given             boolean DEFAULT false,
  consent_given_at          timestamptz,
  booking_time              timestamptz,
  calendly_event_id         text,
  dnr_alert_sent            boolean DEFAULT false,
  dnr_alert_sent_at         timestamptz,
  estimated_value           decimal,
  satisfaction_score        int
    CHECK (satisfaction_score IS NULL OR (satisfaction_score >= 1 AND satisfaction_score <= 5)),
  satisfaction_feedback     text,
  called_during_after_hours boolean DEFAULT false,
  created_at                timestamptz DEFAULT now(),
  updated_at                timestamptz DEFAULT now()
);
COMMENT ON TABLE leads IS 'Missed-call leads — each row is one caller who did not reach the contractor.';

-- messages — SMS conversation log
CREATE TABLE messages (
  id                  uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id             uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  direction           text NOT NULL
    CHECK (direction IN ('inbound', 'outbound')),
  body                text NOT NULL,
  twilio_message_sid  text,
  sent_at             timestamptz DEFAULT now()
);
COMMENT ON TABLE messages IS 'SMS conversation log — every message sent to or received from a lead.';

-- scheduled_tasks — deferred jobs
CREATE TABLE scheduled_tasks (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id     uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  task_type   text NOT NULL
    CHECK (task_type IN ('dnr_check', 'satisfaction_followup', 'reminder', 'consent_timeout')),
  execute_at  timestamptz NOT NULL,
  executed    boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);
COMMENT ON TABLE scheduled_tasks IS 'Deferred tasks — the cron runner picks these up when execute_at <= now().';

-- audit_log — GDPR compliance
CREATE TABLE audit_log (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  action        text NOT NULL,
  entity_type   text NOT NULL,
  entity_id     uuid,
  performed_by  text DEFAULT 'system',
  performed_at  timestamptz DEFAULT now()
);
COMMENT ON TABLE audit_log IS 'GDPR audit log — records data deletion and anonymization events without PII.';

-- job_costs — per-lead cost entries
CREATE TABLE job_costs (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id     uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  description text NOT NULL,
  amount      decimal NOT NULL CHECK (amount > 0),
  created_at  timestamptz DEFAULT now()
);
COMMENT ON TABLE job_costs IS 'Per-lead cost entries — materials, labour, travel etc.';

-- ============================================================================
-- STEP 3: ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE contractors     ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads           ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages        ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_costs       ENABLE ROW LEVEL SECURITY;

CREATE POLICY "contractors_own_data" ON contractors
  FOR ALL USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY "leads_own_data" ON leads
  FOR ALL USING (contractor_id = auth.uid()) WITH CHECK (contractor_id = auth.uid());

CREATE POLICY "messages_own_data" ON messages
  FOR ALL
  USING (EXISTS (SELECT 1 FROM leads WHERE leads.id = messages.lead_id AND leads.contractor_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM leads WHERE leads.id = messages.lead_id AND leads.contractor_id = auth.uid()));

CREATE POLICY "scheduled_tasks_own_data" ON scheduled_tasks
  FOR ALL
  USING (EXISTS (SELECT 1 FROM leads WHERE leads.id = scheduled_tasks.lead_id AND leads.contractor_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM leads WHERE leads.id = scheduled_tasks.lead_id AND leads.contractor_id = auth.uid()));

CREATE POLICY "job_costs_own_data" ON job_costs
  FOR ALL
  USING (EXISTS (SELECT 1 FROM leads WHERE leads.id = job_costs.lead_id AND leads.contractor_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM leads WHERE leads.id = job_costs.lead_id AND leads.contractor_id = auth.uid()));

-- ============================================================================
-- STEP 4: INDEXES
-- ============================================================================

CREATE INDEX idx_leads_contractor_status ON leads (contractor_id, status);
CREATE INDEX idx_leads_dedup ON leads (caller_phone, contractor_id, created_at DESC);
CREATE INDEX idx_messages_lead ON messages (lead_id);
CREATE INDEX idx_scheduled_tasks_pending ON scheduled_tasks (execute_at, executed) WHERE executed = false;
CREATE INDEX idx_job_costs_lead ON job_costs (lead_id);

-- ============================================================================
-- STEP 5: AUTH TRIGGER
-- Auto-create a contractors row when a new user signs up
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.contractors (
    id,
    business_name,
    contact_name,
    contact_email,
    contact_phone,
    twilio_phone_number
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'business_name', ''),
    COALESCE(
      NEW.raw_user_meta_data ->> 'full_name',
      NEW.raw_user_meta_data ->> 'name',
      ''
    ),
    COALESCE(NEW.email, ''),
    '',
    ''
  )
  ON CONFLICT (id) DO UPDATE
  SET contact_email = EXCLUDED.contact_email,
      contact_name  = CASE
        WHEN public.contractors.contact_name = '' THEN EXCLUDED.contact_name
        ELSE public.contractors.contact_name
      END;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- STEP 6: DEV SEED DATA
-- Test contractor + sample leads (uses hardcoded UUIDs — dev only)
-- NOTE: This contractor won't match any auth user. That's fine for dev —
-- use the app's signup flow to create real auth-linked contractors.
-- ============================================================================

INSERT INTO contractors (
  id, business_name, contact_name, contact_email, contact_phone,
  twilio_phone_number, number_setup_type, calendly_url, trade_type,
  default_job_value, urgency_threshold_urgent_min, urgency_threshold_normal_min,
  working_hours_start, working_hours_end, working_days,
  after_hours_emergency_policy, after_hours_ring, timezone, tier, monthly_sms_cap
) VALUES (
  'a1b2c3d4-0000-4000-8000-000000000001',
  'Helsinki Plumbing Oy', 'Mikko Virtanen', 'mikko@helsinkiplumbing.fi',
  '+358401234567', '+358509999001', 'forwarding',
  'https://calendly.com/helsinki-plumbing/callback', 'plumber',
  250.00, 60, 1440, '08:00', '17:00', '{1,2,3,4,5}',
  'Flooding, burst pipes, or sewage backup — call immediately. Dripping taps can wait until morning.',
  true, 'Europe/Helsinki', 'starter', 50
);

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given, consent_given_at,
  booking_time, calendly_event_id, estimated_value, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000001',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358401111111', 'Anna Korhonen', 'Leaking pipe under the kitchen sink',
  'high', 1, 'booked', true, now() - interval '2 hours',
  now() + interval '1 day', 'evt_calendly_sample_001', 250.00,
  now() - interval '3 hours'
);

INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'Hi, you just tried to reach Helsinki Plumbing Oy. We can help get you connected. Reply YES if you''d like us to arrange a callback, or STOP to opt out.',
   now() - interval '3 hours'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound', 'YES', now() - interval '2 hours 55 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'What issue are you experiencing? (e.g., leaking pipe, broken AC, electrical problem)',
   now() - interval '2 hours 54 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound',
   'Leaking pipe under the kitchen sink', now() - interval '2 hours 50 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'How urgent is this? Reply 1-4: 1 — Emergency, 2 — Urgent (today/tomorrow), 3 — This week, 4 — Not urgent',
   now() - interval '2 hours 49 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound', '2', now() - interval '2 hours 45 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'Got it. What''s your name? And here''s a link to book a callback: https://calendly.com/helsinki-plumbing/callback',
   now() - interval '2 hours 44 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound', 'Anna Korhonen', now() - interval '2 hours 40 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'You''re booked with Helsinki Plumbing Oy on tomorrow at 10:00. They''ll call you at this number.',
   now() - interval '2 hours');

INSERT INTO leads (
  id, contractor_id, caller_phone, issue_description, urgency,
  call_count, status, consent_given, called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000002',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358402222222', NULL, 'unknown', 2, 'consent_sent', false, true,
  now() - interval '30 minutes'
);

INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000002', 'outbound',
   'Hi, you just tried to reach Helsinki Plumbing Oy. We can help get you connected. Reply YES if you''d like us to arrange a callback, or STOP to opt out.',
   now() - interval '30 minutes');

COMMIT;

-- ============================================================================
-- ✅ DEV SETUP COMPLETE
-- Tables, RLS, indexes, auth trigger, and seed data are all in place.
-- ============================================================================
