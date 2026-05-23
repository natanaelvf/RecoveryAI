-- ============================================================================
-- Migration: Add fcm_token to contractors + notes to leads
-- Run this against an existing database to add missing columns.
-- Safe to run multiple times (IF NOT EXISTS / idempotent).
-- ============================================================================

-- FCM device token for push notifications
ALTER TABLE contractors ADD COLUMN IF NOT EXISTS fcm_token text;
COMMENT ON COLUMN contractors.fcm_token IS 'Firebase Cloud Messaging device token — set on mobile app login.';

-- Free-text notes field on leads (editable by contractor in the app)
ALTER TABLE leads ADD COLUMN IF NOT EXISTS notes text;
COMMENT ON COLUMN leads.notes IS 'Contractor-editable notes about this lead/job.';

-- ============================================================================
-- ✅ Migration complete
-- ============================================================================
