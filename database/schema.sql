-- ============================================================================
-- Missed-Lead Recovery — Supabase Postgres Schema
-- Run this in the Supabase SQL Editor to create all tables, policies, & indexes.
-- ============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE: contractors
-- Each contractor (plumber, HVAC tech, electrician, roofer) has one row.
-- The contractor's Supabase Auth UID is used as the primary key (id).
-- ============================================================================
CREATE TABLE contractors (
  id                            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_name                 text NOT NULL,
  contact_name                  text NOT NULL,
  contact_email                 text NOT NULL,
  contact_phone                 text NOT NULL,             -- contractor's real phone number
  twilio_phone_number           text NOT NULL,             -- Twilio number (forwarding target or new number)
  number_setup_type             text DEFAULT 'forwarding'  -- 'forwarding' | 'new_number'
    CHECK (number_setup_type IN ('forwarding', 'new_number')),
  calendly_url                  text,                      -- their Calendly scheduling link
  trade_type                    text                       -- plumber | hvac | electrician | roofer | other
    CHECK (trade_type IN ('plumber', 'hvac', 'electrician', 'roofer', 'other')),
  default_job_value             decimal,                   -- trade-based default, set during onboarding
  urgency_threshold_urgent_min  int DEFAULT 60,            -- minutes before DNR alert (urgent/emergency)
  urgency_threshold_normal_min  int DEFAULT 1440,          -- minutes before DNR alert (normal) — 24 hours
  working_hours_start           time DEFAULT '08:00',
  working_hours_end             time DEFAULT '18:00',
  working_days                  int[] DEFAULT '{1,2,3,4,5}',  -- 1=Mon … 7=Sun
  after_hours_emergency_policy  text,                      -- contractor's own words on what counts as emergency
  after_hours_ring              boolean DEFAULT false,      -- whether to ring contractor on after-hours emergency
  timezone                      text DEFAULT 'Europe/Helsinki',
  tier                          text DEFAULT 'starter'     -- starter | growth | pro
    CHECK (tier IN ('starter', 'growth', 'pro')),
  monthly_sms_cap               int DEFAULT 50,
  sms_used_this_month           int DEFAULT 0,
  stripe_customer_id            text,
  created_at                    timestamptz DEFAULT now(),
  updated_at                    timestamptz DEFAULT now()
);

COMMENT ON TABLE contractors IS 'Contractor accounts — each represents a home service business.';

-- ============================================================================
-- TABLE: leads
-- Each missed call becomes a lead. Tracks the full lifecycle from missed call
-- through consent, qualification, booking, completion, and follow-up.
-- ============================================================================
CREATE TABLE leads (
  id                        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  contractor_id             uuid NOT NULL REFERENCES contractors(id) ON DELETE CASCADE,
  caller_phone              text NOT NULL,                  -- lead's phone number
  caller_name               text,                           -- collected via SMS
  issue_description         text,                           -- collected via SMS
  urgency                   text DEFAULT 'unknown'          -- unknown | low | medium | high | emergency
    CHECK (urgency IN ('unknown', 'low', 'medium', 'high', 'emergency')),
  email                     text,                           -- optional, collected via SMS
  call_count                int DEFAULT 1,                  -- incremented on duplicate calls within 24hr
  status                    text DEFAULT 'missed'           -- lifecycle status
    CHECK (status IN (
      'missed', 'consent_sent', 'opted_in', 'qualifying',
      'qualifying_issue', 'qualifying_urgency', 'qualifying_name',
      'booking_sent', 'booked', 'completed', 'followed_up',
      'dnr_alert', 'no_consent'
    )),
  consent_given             boolean DEFAULT false,
  consent_given_at          timestamptz,
  booking_time              timestamptz,                    -- from Calendly
  calendly_event_id         text,
  dnr_alert_sent            boolean DEFAULT false,
  dnr_alert_sent_at         timestamptz,
  estimated_value           decimal,                        -- defaults to contractor.default_job_value, overridable
  satisfaction_score        int                             -- 1–5 from follow-up SMS
    CHECK (satisfaction_score IS NULL OR (satisfaction_score >= 1 AND satisfaction_score <= 5)),
  satisfaction_feedback     text,
  called_during_after_hours boolean DEFAULT false,
  created_at                timestamptz DEFAULT now(),
  updated_at                timestamptz DEFAULT now()
);

COMMENT ON TABLE leads IS 'Missed-call leads — each row is one caller who did not reach the contractor.';

-- ============================================================================
-- TABLE: messages
-- Full SMS conversation log between the system and the lead.
-- ============================================================================
CREATE TABLE messages (
  id                  uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id             uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  direction           text NOT NULL                        -- inbound | outbound
    CHECK (direction IN ('inbound', 'outbound')),
  body                text NOT NULL,
  twilio_message_sid  text,
  sent_at             timestamptz DEFAULT now()
);

COMMENT ON TABLE messages IS 'SMS conversation log — every message sent to or received from a lead.';

-- ============================================================================
-- TABLE: scheduled_tasks
-- Deferred jobs: DNR checks, satisfaction follow-ups, reminders.
-- ============================================================================
CREATE TABLE scheduled_tasks (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id     uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  task_type   text NOT NULL                                -- dnr_check | satisfaction_followup | reminder | consent_timeout
    CHECK (task_type IN ('dnr_check', 'satisfaction_followup', 'reminder', 'consent_timeout')),
  execute_at  timestamptz NOT NULL,
  executed    boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

COMMENT ON TABLE scheduled_tasks IS 'Deferred tasks — the cron runner picks these up when execute_at <= now().';

-- ============================================================================
-- TABLE: audit_log
-- GDPR compliance: records data deletion/anonymization events.
-- No PII is stored — only the action, entity reference, and timestamp.
-- ============================================================================
CREATE TABLE audit_log (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  action        text NOT NULL,                              -- e.g. 'data_retention_anonymize', 'gdpr_deletion'
  entity_type   text NOT NULL,                              -- e.g. 'lead'
  entity_id     uuid,                                       -- the ID of the affected entity
  performed_by  text DEFAULT 'system',                      -- 'system:cron_name' or contractor ID
  performed_at  timestamptz DEFAULT now()
);

COMMENT ON TABLE audit_log IS 'GDPR audit log — records data deletion and anonymization events without PII.';


-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- Each contractor can only read/write their own data. Mandatory for GDPR.
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE contractors     ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads           ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages        ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_tasks ENABLE ROW LEVEL SECURITY;

-- contractors: a contractor can only see/edit their own row
CREATE POLICY "contractors_own_data"
  ON contractors
  FOR ALL
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- leads: a contractor can only see/edit leads belonging to them
CREATE POLICY "leads_own_data"
  ON leads
  FOR ALL
  USING (contractor_id = auth.uid())
  WITH CHECK (contractor_id = auth.uid());

-- messages: a contractor can only see messages for their leads
-- (join through leads to check ownership)
CREATE POLICY "messages_own_data"
  ON messages
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = messages.lead_id
        AND leads.contractor_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = messages.lead_id
        AND leads.contractor_id = auth.uid()
    )
  );

-- scheduled_tasks: a contractor can only see tasks for their leads
CREATE POLICY "scheduled_tasks_own_data"
  ON scheduled_tasks
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = scheduled_tasks.lead_id
        AND leads.contractor_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = scheduled_tasks.lead_id
        AND leads.contractor_id = auth.uid()
    )
  );


-- ============================================================================
-- INDEXES
-- Optimise the queries that the backend runs most frequently.
-- ============================================================================

-- Lead lookups by contractor + status (lead list screen, filtered views)
CREATE INDEX idx_leads_contractor_status
  ON leads (contractor_id, status);

-- Deduplication check: same caller + contractor within 24 hours
CREATE INDEX idx_leads_dedup
  ON leads (caller_phone, contractor_id, created_at DESC);

-- Conversation log: messages for a specific lead
CREATE INDEX idx_messages_lead
  ON messages (lead_id);

-- Cron runner: find tasks that are due and not yet executed
CREATE INDEX idx_scheduled_tasks_pending
  ON scheduled_tasks (execute_at, executed)
  WHERE executed = false;
