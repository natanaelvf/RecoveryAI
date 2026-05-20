-- ============================================================================
-- Missed-Lead Recovery — Seed Data
-- One test contractor and two sample leads for local development.
-- Run AFTER schema.sql. Use the Supabase SQL editor or psql.
-- ============================================================================

-- Use fixed UUIDs so foreign keys are easy to follow during development.
-- In production, UUIDs are auto-generated.

-- ============================================================================
-- 1. Contractor: "Helsinki Plumbing Oy" — a Finnish plumber
-- ============================================================================
INSERT INTO contractors (
  id,
  business_name,
  contact_name,
  contact_email,
  contact_phone,
  twilio_phone_number,
  number_setup_type,
  calendly_url,
  trade_type,
  default_job_value,
  urgency_threshold_urgent_min,
  urgency_threshold_normal_min,
  working_hours_start,
  working_hours_end,
  working_days,
  after_hours_emergency_policy,
  after_hours_ring,
  timezone,
  tier,
  monthly_sms_cap
) VALUES (
  'a1b2c3d4-0000-4000-8000-000000000001',
  'Helsinki Plumbing Oy',
  'Mikko Virtanen',
  'mikko@helsinkiplumbing.fi',
  '+358401234567',
  '+358509999001',
  'forwarding',
  'https://calendly.com/helsinki-plumbing/callback',
  'plumber',
  250.00,
  60,     -- urgent: 1 hour
  1440,   -- normal: 24 hours
  '08:00',
  '17:00',
  '{1,2,3,4,5}',   -- Mon–Fri
  'Flooding, burst pipes, or sewage backup — call immediately. Dripping taps can wait until morning.',
  true,
  'Europe/Helsinki',
  'starter',
  50
);

-- ============================================================================
-- 2. Lead A: "Leaking pipe" — fully booked
-- ============================================================================
INSERT INTO leads (
  id,
  contractor_id,
  caller_phone,
  caller_name,
  issue_description,
  urgency,
  call_count,
  status,
  consent_given,
  consent_given_at,
  booking_time,
  calendly_event_id,
  estimated_value,
  created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000001',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358401111111',
  'Anna Korhonen',
  'Leaking pipe under the kitchen sink',
  'high',
  1,
  'booked',
  true,
  now() - interval '2 hours',
  now() + interval '1 day',
  'evt_calendly_sample_001',
  250.00,
  now() - interval '3 hours'
);

-- Lead A messages (consent → issue → urgency → name → booking confirmation)
INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'Hi, you just tried to reach Helsinki Plumbing Oy. We can help get you connected. Reply YES if you''d like us to arrange a callback, or STOP to opt out.',
   now() - interval '3 hours'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound',
   'YES',
   now() - interval '2 hours 55 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'What issue are you experiencing? (e.g., leaking pipe, broken AC, electrical problem)',
   now() - interval '2 hours 54 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound',
   'Leaking pipe under the kitchen sink',
   now() - interval '2 hours 50 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'How urgent is this? Reply 1-4: 1 — Emergency, 2 — Urgent (today/tomorrow), 3 — This week, 4 — Not urgent',
   now() - interval '2 hours 49 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound',
   '2',
   now() - interval '2 hours 45 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'Got it. What''s your name? And here''s a link to book a callback: https://calendly.com/helsinki-plumbing/callback',
   now() - interval '2 hours 44 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound',
   'Anna Korhonen',
   now() - interval '2 hours 40 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'You''re booked with Helsinki Plumbing Oy on tomorrow at 10:00. They''ll call you at this number.',
   now() - interval '2 hours');

-- ============================================================================
-- 3. Lead B: "No hot water" — consent sent, waiting for reply
-- ============================================================================
INSERT INTO leads (
  id,
  contractor_id,
  caller_phone,
  issue_description,
  urgency,
  call_count,
  status,
  consent_given,
  called_during_after_hours,
  created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000002',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358402222222',
  NULL,         -- not yet collected
  'unknown',
  2,            -- called twice
  'consent_sent',
  false,
  true,         -- called after hours
  now() - interval '30 minutes'
);

-- Lead B messages (consent sent, no reply yet)
INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000002', 'outbound',
   'Hi, you just tried to reach Helsinki Plumbing Oy. We can help get you connected. Reply YES if you''d like us to arrange a callback, or STOP to opt out.',
   now() - interval '30 minutes');
