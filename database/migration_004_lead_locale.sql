-- Migration 004: Add locale column to leads
-- Tracks caller language preference on a per-lead basis.

ALTER TABLE leads
  ADD COLUMN IF NOT EXISTS locale text NOT NULL DEFAULT 'fi';

ALTER TABLE leads
  DROP CONSTRAINT IF EXISTS leads_locale_check;

ALTER TABLE leads
  ADD CONSTRAINT leads_locale_check CHECK (locale IN ('fi', 'en', 'pt'));

COMMENT ON COLUMN leads.locale IS 'Caller preferred language for SMS and voicemails: fi = Finnish, en = English, pt = Portuguese';

-- Initialize existing leads with their contractor's default locale
UPDATE leads
SET locale = contractors.locale
FROM contractors
WHERE leads.contractor_id = contractors.id;
