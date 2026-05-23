-- Migration 003: Add locale column to contractors
-- Supports trilingual SMS templates (Finnish, English, Portuguese)

ALTER TABLE contractors
  ADD COLUMN IF NOT EXISTS locale text NOT NULL DEFAULT 'fi';

ALTER TABLE contractors
  ADD CONSTRAINT contractors_locale_check CHECK (locale IN ('fi', 'en', 'pt'));

COMMENT ON COLUMN contractors.locale IS 'SMS language preference: fi = Finnish, en = English, pt = Portuguese';
