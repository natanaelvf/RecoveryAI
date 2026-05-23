-- Migration 003: Add locale column to contractors
-- Supports bilingual SMS templates (Finnish default for +358 market)

ALTER TABLE contractors
  ADD COLUMN IF NOT EXISTS locale text NOT NULL DEFAULT 'fi';

COMMENT ON COLUMN contractors.locale IS 'SMS language preference: fi = Finnish, en = English';
