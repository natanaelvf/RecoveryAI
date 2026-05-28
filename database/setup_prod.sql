-- ============================================================================
-- PROD ENVIRONMENT — Full Setup Script
-- Missed-Lead Recovery
--
-- Run this in the Supabase SQL Editor for the PROD project
-- (bgtfryaocodokjqjkffx)
--
-- Contains: clean slate → schema → RLS → indexes → functions → auth trigger
-- NO seed data — contractors are created via the signup flow.
-- ============================================================================

BEGIN;

-- ============================================================================
-- STEP 0: CLEAN SLATE
-- ============================================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.increment_sms_usage(uuid);

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

CREATE TABLE contractors (
  id                            uuid PRIMARY KEY,  -- must equal auth.uid()
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
  locale                        text NOT NULL DEFAULT 'fi'
    CHECK (locale IN ('fi', 'en', 'pt')),
  fcm_token                     text,
  stripe_customer_id            text,
  created_at                    timestamptz DEFAULT now(),
  updated_at                    timestamptz DEFAULT now()
);

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
  locale                    text NOT NULL DEFAULT 'fi'
    CHECK (locale IN ('fi', 'en', 'pt')),
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
  notes                     text,
  called_during_after_hours boolean DEFAULT false,
  created_at                timestamptz DEFAULT now(),
  updated_at                timestamptz DEFAULT now()
);

CREATE TABLE messages (
  id                  uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id             uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  direction           text NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  body                text NOT NULL,
  twilio_message_sid  text,
  sent_at             timestamptz DEFAULT now()
);

CREATE TABLE scheduled_tasks (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id     uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  task_type   text NOT NULL
    CHECK (task_type IN ('dnr_check', 'satisfaction_followup', 'reminder', 'consent_timeout')),
  execute_at  timestamptz NOT NULL,
  executed    boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE audit_log (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  action        text NOT NULL,
  entity_type   text NOT NULL,
  entity_id     uuid,
  performed_by  text DEFAULT 'system',
  performed_at  timestamptz DEFAULT now()
);

CREATE TABLE job_costs (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id     uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  description text NOT NULL,
  amount      decimal NOT NULL CHECK (amount > 0),
  created_at  timestamptz DEFAULT now()
);

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
-- STEP 5: FUNCTIONS
-- ============================================================================

-- Auth trigger: auto-create contractor row on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.contractors (
    id, business_name, contact_name, contact_email, contact_phone, twilio_phone_number
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'business_name', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', ''),
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

-- Atomic SMS cap check-and-increment
CREATE OR REPLACE FUNCTION public.increment_sms_usage(p_contractor_id uuid)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_new_count int;
BEGIN
  UPDATE public.contractors
  SET sms_used_this_month = sms_used_this_month + 1
  WHERE id = p_contractor_id
    AND sms_used_this_month < monthly_sms_cap
  RETURNING sms_used_this_month INTO v_new_count;

  IF NOT FOUND THEN
    RETURN -1;
  END IF;

  RETURN v_new_count;
END;
$$;

COMMIT;

-- ============================================================================
-- ✅ PROD SETUP COMPLETE
-- Tables, RLS, indexes, functions, and auth trigger are in place.
-- No seed data — contractors are created via the signup flow.
-- ============================================================================
