-- ============================================================================
-- DEV SEED DATA — Comprehensive test data
-- Missed-Lead Recovery
--
-- Run this AFTER setup_dev.sql (or on its own if schema already exists).
-- Clears existing seed data and re-inserts fresh.
--
-- Contractor UUID: a1b2c3d4-0000-4000-8000-000000000001
-- This is a standalone dev contractor — not linked to any auth user.
-- For authenticated testing, use the app's signup flow.
-- ============================================================================

BEGIN;

-- ============================================================================
-- CLEAN: Remove existing seed data (preserves schema)
-- ============================================================================

DELETE FROM job_costs     WHERE lead_id IN (SELECT id FROM leads WHERE contractor_id = 'a1b2c3d4-0000-4000-8000-000000000001');
DELETE FROM messages      WHERE lead_id IN (SELECT id FROM leads WHERE contractor_id = 'a1b2c3d4-0000-4000-8000-000000000001');
DELETE FROM scheduled_tasks WHERE lead_id IN (SELECT id FROM leads WHERE contractor_id = 'a1b2c3d4-0000-4000-8000-000000000001');
DELETE FROM audit_log     WHERE performed_by = 'a1b2c3d4-0000-4000-8000-000000000001';
DELETE FROM leads         WHERE contractor_id = 'a1b2c3d4-0000-4000-8000-000000000001';
DELETE FROM contractors   WHERE id = 'a1b2c3d4-0000-4000-8000-000000000001';

-- ============================================================================
-- CONTRACTOR
-- ============================================================================

INSERT INTO contractors (
  id, business_name, contact_name, contact_email, contact_phone,
  twilio_phone_number, number_setup_type, calendly_url, trade_type,
  default_job_value, urgency_threshold_urgent_min, urgency_threshold_normal_min,
  working_hours_start, working_hours_end, working_days,
  after_hours_emergency_policy, after_hours_ring, timezone,
  tier, monthly_sms_cap, sms_used_this_month
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
  250.00,          -- default job value
  60,              -- urgent threshold: 1 hour
  1440,            -- normal threshold: 24 hours
  '08:00', '17:00',
  '{1,2,3,4,5}',   -- Mon-Fri
  'Flooding, burst pipes, or sewage backup — call immediately. Dripping taps can wait until morning.',
  true,
  'Europe/Helsinki',
  'growth',         -- growth tier for demo
  150,              -- SMS cap
  37                -- some usage this month
);

-- ============================================================================
-- LEAD 1: Fully booked — kitchen sink leak (complete SMS flow)
-- Status: booked | Urgency: high | Has booking
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given, consent_given_at,
  booking_time, calendly_event_id, estimated_value,
  called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000001',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358401111111', 'Anna Korhonen', 'Leaking pipe under the kitchen sink',
  'high', 1, 'booked', true, now() - interval '3 hours',
  now() + interval '1 day', 'evt_calendly_001', 250.00,
  false, now() - interval '3 hours'
);

INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'Hi! You just called Helsinki Plumbing Oy but we couldn''t answer. We''d like to help you via text. Reply YES to continue or STOP to opt out.',
   now() - interval '3 hours'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound', 'YES', now() - interval '2 hours 55 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'Great, thanks for opting in! Can you briefly describe the issue you need help with?',
   now() - interval '2 hours 54 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound',
   'Leaking pipe under the kitchen sink', now() - interval '2 hours 50 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'How urgent is this?\n1 - Not urgent\n2 - Soon, within 24-48h\n3 - Urgent, need help today\n4 - Emergency, need help now',
   now() - interval '2 hours 49 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound', '3', now() - interval '2 hours 45 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'Thanks! What''s your name so we can address you properly?',
   now() - interval '2 hours 44 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'inbound', 'Anna Korhonen', now() - interval '2 hours 40 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'Thanks! Here''s a link to book a time with Helsinki Plumbing Oy: https://calendly.com/helsinki-plumbing/callback',
   now() - interval '2 hours 38 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000001', 'outbound',
   'Your appointment with Helsinki Plumbing Oy is confirmed for tomorrow at 10:00. We look forward to helping you!',
   now() - interval '2 hours');

-- ============================================================================
-- LEAD 2: EMERGENCY — burst pipe, after-hours, repeat caller (3x)
-- Status: booking_sent | Urgency: emergency | After hours
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given, consent_given_at,
  estimated_value, called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000002',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358407778899', 'Jari Mäkinen', 'Water spraying from burst pipe in bathroom, flooding the floor',
  'emergency', 3, 'booking_sent', true, now() - interval '45 minutes',
  350.00, true, now() - interval '50 minutes'
);

INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000002', 'outbound',
   'Hi! You just called Helsinki Plumbing Oy but we couldn''t answer. We''d like to help you via text. Reply YES to continue or STOP to opt out.',
   now() - interval '50 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000002', 'inbound', 'YES', now() - interval '48 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000002', 'outbound',
   'Great, thanks for opting in! Can you briefly describe the issue you need help with?',
   now() - interval '47 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000002', 'inbound',
   'Water spraying from burst pipe in bathroom, flooding the floor', now() - interval '45 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000002', 'outbound',
   'How urgent is this?\n1 - Not urgent\n2 - Soon, within 24-48h\n3 - Urgent, need help today\n4 - Emergency, need help now',
   now() - interval '44 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000002', 'inbound', '4', now() - interval '43 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000002', 'outbound',
   'Thanks! What''s your name so we can address you properly?',
   now() - interval '42 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000002', 'inbound', 'Jari Mäkinen', now() - interval '41 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000002', 'outbound',
   'Thanks! Here''s a link to book a time with Helsinki Plumbing Oy: https://calendly.com/helsinki-plumbing/callback',
   now() - interval '40 minutes');

-- ============================================================================
-- LEAD 3: Completed job with satisfaction score + costs
-- Status: followed_up | Urgency: medium | Has costs + feedback
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given, consent_given_at,
  booking_time, calendly_event_id, estimated_value,
  satisfaction_score, satisfaction_feedback,
  called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000003',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358403334455', 'Liisa Nieminen', 'Toilet won''t stop running, water bill is going up',
  'medium', 1, 'followed_up', true, now() - interval '5 days',
  now() - interval '4 days', 'evt_calendly_002', 180.00,
  5, 'Mikko was great! Fixed it in 30 minutes. Very professional.',
  false, now() - interval '5 days'
);

INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000003', 'outbound',
   'Hi! You just called Helsinki Plumbing Oy but we couldn''t answer. Reply YES to continue or STOP to opt out.',
   now() - interval '5 days'),
  ('b1b2c3d4-0000-4000-8000-000000000003', 'inbound', 'YES', now() - interval '5 days' + interval '3 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000003', 'outbound',
   'Can you briefly describe the issue?', now() - interval '5 days' + interval '4 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000003', 'inbound',
   'Toilet won''t stop running, water bill is going up', now() - interval '5 days' + interval '8 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000003', 'outbound',
   'Your appointment is confirmed for tomorrow at 14:00.',
   now() - interval '5 days' + interval '1 hour'),
  ('b1b2c3d4-0000-4000-8000-000000000003', 'outbound',
   'Hi! How was your experience with Helsinki Plumbing Oy? Reply 1-5 (1=poor, 5=excellent).',
   now() - interval '3 days'),
  ('b1b2c3d4-0000-4000-8000-000000000003', 'inbound',
   '5 Mikko was great! Fixed it in 30 minutes. Very professional.',
   now() - interval '3 days' + interval '2 hours');

-- Job costs for the completed lead
INSERT INTO job_costs (lead_id, description, amount, created_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000003', 'Toilet fill valve replacement (Geberit)', 45.00, now() - interval '4 days'),
  ('b1b2c3d4-0000-4000-8000-000000000003', 'Flapper seal + wax ring', 12.50, now() - interval '4 days'),
  ('b1b2c3d4-0000-4000-8000-000000000003', 'Labour (1 hour)', 85.00, now() - interval '4 days'),
  ('b1b2c3d4-0000-4000-8000-000000000003', 'Travel (Kallio → Töölö)', 25.00, now() - interval '4 days');

-- ============================================================================
-- LEAD 4: Completed with LOW satisfaction (triggers alert)
-- Status: followed_up | Urgency: high | Score: 2/5
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given, consent_given_at,
  booking_time, estimated_value,
  satisfaction_score, satisfaction_feedback,
  called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000004',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358409998877', 'Petri Lahtinen', 'Hot water heater not working, no hot water in the house',
  'high', 1, 'followed_up', true, now() - interval '7 days',
  now() - interval '6 days', 450.00,
  2, 'Took too long to arrive. Had to wait 3 hours past the scheduled time.',
  false, now() - interval '7 days'
);

INSERT INTO job_costs (lead_id, description, amount, created_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000004', 'Thermocouple replacement', 35.00, now() - interval '6 days'),
  ('b1b2c3d4-0000-4000-8000-000000000004', 'Gas valve inspection', 60.00, now() - interval '6 days'),
  ('b1b2c3d4-0000-4000-8000-000000000004', 'Labour (2.5 hours)', 212.50, now() - interval '6 days');

-- ============================================================================
-- LEAD 5: DNR alert — sent booking link, never booked
-- Status: dnr_alert | Urgency: low | DNR alert was sent
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given, consent_given_at,
  estimated_value, dnr_alert_sent, dnr_alert_sent_at,
  called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000005',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358405556677', 'Eero Salonen', 'Dripping faucet in the kitchen, been like this for a week',
  'low', 1, 'dnr_alert', true, now() - interval '2 days',
  250.00, true, now() - interval '1 day',
  false, now() - interval '2 days'
);

INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000005', 'outbound',
   'Hi! You just called Helsinki Plumbing Oy. Reply YES to continue or STOP to opt out.',
   now() - interval '2 days'),
  ('b1b2c3d4-0000-4000-8000-000000000005', 'inbound', 'YES', now() - interval '2 days' + interval '5 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000005', 'outbound',
   'Can you briefly describe the issue?', now() - interval '2 days' + interval '6 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000005', 'inbound',
   'Dripping faucet in the kitchen, been like this for a week', now() - interval '2 days' + interval '12 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000005', 'outbound',
   'How urgent? 1-Not urgent, 2-Soon, 3-Urgent, 4-Emergency', now() - interval '2 days' + interval '13 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000005', 'inbound', '1', now() - interval '2 days' + interval '15 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000005', 'outbound',
   'What''s your name?', now() - interval '2 days' + interval '16 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000005', 'inbound', 'Eero Salonen', now() - interval '2 days' + interval '20 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000005', 'outbound',
   'Here''s a link to book: https://calendly.com/helsinki-plumbing/callback',
   now() - interval '2 days' + interval '21 minutes');

-- ============================================================================
-- LEAD 6: Fresh missed call — consent sent, waiting for reply
-- Status: consent_sent | Urgency: unknown | After hours
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given,
  estimated_value, called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000006',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358402223344', NULL, NULL,
  'unknown', 1, 'consent_sent', false,
  250.00, true, now() - interval '15 minutes'
);

INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000006', 'outbound',
   'Hi! You just called Helsinki Plumbing Oy but we couldn''t answer. Reply YES to continue or STOP to opt out.',
   now() - interval '15 minutes');

-- Consent timeout scheduled
INSERT INTO scheduled_tasks (lead_id, task_type, execute_at, executed) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000006', 'consent_timeout', now() + interval '15 minutes', false);

-- ============================================================================
-- LEAD 7: Opted out — no consent
-- Status: no_consent
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given,
  called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000007',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358408887766', NULL, NULL,
  'unknown', 1, 'no_consent', false,
  false, now() - interval '1 day'
);

INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000007', 'outbound',
   'Hi! You just called Helsinki Plumbing Oy. Reply YES to continue or STOP to opt out.',
   now() - interval '1 day'),
  ('b1b2c3d4-0000-4000-8000-000000000007', 'inbound', 'STOP', now() - interval '1 day' + interval '2 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000007', 'outbound',
   'No problem! We won''t text you again. If you need help in the future, give us a call.',
   now() - interval '1 day' + interval '2 minutes');

-- ============================================================================
-- LEAD 8: Mid-qualification — gave issue, waiting for urgency
-- Status: qualifying_urgency | Has phone + issue, no name yet
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given, consent_given_at,
  estimated_value, called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000008',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358406665544', NULL, 'Shower drain is completely blocked, water not going down at all',
  'unknown', 1, 'qualifying_urgency', true, now() - interval '20 minutes',
  250.00, false, now() - interval '25 minutes'
);

INSERT INTO messages (lead_id, direction, body, sent_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000008', 'outbound',
   'Hi! You just called Helsinki Plumbing Oy. Reply YES to continue or STOP to opt out.',
   now() - interval '25 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000008', 'inbound', 'YES', now() - interval '23 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000008', 'outbound',
   'Can you briefly describe the issue?', now() - interval '22 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000008', 'inbound',
   'Shower drain is completely blocked, water not going down at all', now() - interval '20 minutes'),
  ('b1b2c3d4-0000-4000-8000-000000000008', 'outbound',
   'How urgent? 1-Not urgent, 2-Soon, 3-Urgent, 4-Emergency', now() - interval '19 minutes');

-- ============================================================================
-- LEAD 9: Completed, pending satisfaction follow-up
-- Status: completed | Has scheduled follow-up task
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given, consent_given_at,
  booking_time, estimated_value,
  called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000009',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358401112233', 'Matti Heikkinen', 'Radiator leaking in the living room, staining the carpet',
  'high', 2, 'completed', true, now() - interval '3 days',
  now() - interval '2 days', 320.00,
  false, now() - interval '3 days'
);

INSERT INTO job_costs (lead_id, description, amount, created_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000009', 'Radiator valve replacement (Danfoss)', 68.00, now() - interval '2 days'),
  ('b1b2c3d4-0000-4000-8000-000000000009', 'PTFE tape + pipe sealant', 8.50, now() - interval '2 days'),
  ('b1b2c3d4-0000-4000-8000-000000000009', 'Labour (1.5 hours)', 127.50, now() - interval '2 days'),
  ('b1b2c3d4-0000-4000-8000-000000000009', 'Emergency call-out surcharge', 50.00, now() - interval '2 days');

-- Satisfaction follow-up scheduled (upcoming)
INSERT INTO scheduled_tasks (lead_id, task_type, execute_at, executed) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000009', 'satisfaction_followup', now() + interval '6 hours', false);

-- ============================================================================
-- LEAD 10: Just missed — bare minimum, brand new
-- Status: missed | No SMS sent yet (just arrived)
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given,
  estimated_value, called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000010',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358404443322', NULL, NULL,
  'unknown', 1, 'missed', false,
  250.00, false, now() - interval '2 minutes'
);

-- ============================================================================
-- LEAD 11: Old completed job (from 2 weeks ago) — tests historical data
-- Status: followed_up | Urgency: medium | Score: 4/5
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given, consent_given_at,
  booking_time, estimated_value,
  satisfaction_score, satisfaction_feedback,
  called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000011',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358407770011', 'Sari Koskinen', 'Kitchen sink P-trap leaking, water dripping into cabinet below',
  'medium', 1, 'followed_up', true, now() - interval '14 days',
  now() - interval '13 days', 150.00,
  4, 'Good work, but a bit pricey.',
  false, now() - interval '14 days'
);

INSERT INTO job_costs (lead_id, description, amount, created_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000011', 'P-trap assembly (40mm)', 22.00, now() - interval '13 days'),
  ('b1b2c3d4-0000-4000-8000-000000000011', 'Labour (45 minutes)', 63.75, now() - interval '13 days');

-- ============================================================================
-- LEAD 12: Another old completed job (3 weeks ago)
-- Status: followed_up | Urgency: low | Score: 5/5
-- ============================================================================

INSERT INTO leads (
  id, contractor_id, caller_phone, caller_name, issue_description,
  urgency, call_count, status, consent_given, consent_given_at,
  booking_time, estimated_value,
  satisfaction_score, satisfaction_feedback,
  called_during_after_hours, created_at
) VALUES (
  'b1b2c3d4-0000-4000-8000-000000000012',
  'a1b2c3d4-0000-4000-8000-000000000001',
  '+358401239876', 'Timo Järvinen', 'Want to get a quote for replacing bathroom fixtures',
  'low', 1, 'followed_up', true, now() - interval '21 days',
  now() - interval '20 days', 1200.00,
  5, 'Excellent quote, fair price, very knowledgeable.',
  false, now() - interval '21 days'
);

INSERT INTO job_costs (lead_id, description, amount, created_at) VALUES
  ('b1b2c3d4-0000-4000-8000-000000000012', 'Bathroom sink (Oras Signa)', 289.00, now() - interval '19 days'),
  ('b1b2c3d4-0000-4000-8000-000000000012', 'Faucet (Oras Optima)', 195.00, now() - interval '19 days'),
  ('b1b2c3d4-0000-4000-8000-000000000012', 'Toilet (IDO Glow)', 380.00, now() - interval '19 days'),
  ('b1b2c3d4-0000-4000-8000-000000000012', 'Installation labour (full day)', 680.00, now() - interval '19 days'),
  ('b1b2c3d4-0000-4000-8000-000000000012', 'Plumbing supplies + fittings', 95.00, now() - interval '19 days');

-- ============================================================================
-- AUDIT LOG — sample entries
-- ============================================================================

INSERT INTO audit_log (action, entity_type, entity_id, performed_by, performed_at) VALUES
  ('data_retention_anonymize', 'lead', 'c0000000-0000-4000-8000-000000000099', 'system:data_retention_cron', now() - interval '30 days'),
  ('gdpr_deletion', 'lead', 'c0000000-0000-4000-8000-000000000098', 'a1b2c3d4-0000-4000-8000-000000000001', now() - interval '10 days');

COMMIT;

-- ============================================================================
-- ✅ SEED COMPLETE
--
-- Summary:
--   1 contractor  (Helsinki Plumbing Oy)
--  12 leads across all statuses:
--     • booked (1)          — Anna Korhonen, kitchen sink
--     • booking_sent (1)    — Jari Mäkinen, EMERGENCY burst pipe, 3x caller
--     • followed_up (4)     — Liisa (5★), Petri (2★ ⚠️), Sari (4★), Timo (5★)
--     • dnr_alert (1)       — Eero Salonen, dripping faucet
--     • consent_sent (1)    — Unknown, after hours, 15 min ago
--     • no_consent (1)      — Unknown, replied STOP
--     • qualifying_urgency (1) — Unknown, blocked shower drain
--     • completed (1)       — Matti Heikkinen, radiator leak, follow-up pending
--     • missed (1)          — Unknown, just arrived 2 min ago
--  15 job cost entries across 4 leads
--  37+ messages showing full SMS conversations
--   2 scheduled tasks (consent timeout + satisfaction follow-up)
--   2 audit log entries
-- ============================================================================
