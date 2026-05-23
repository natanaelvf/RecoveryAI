-- ============================================================================
-- Migration: Atomic SMS cap check-and-increment
--
-- Prevents race conditions where two concurrent SMS sends both read the
-- same sms_used_this_month value, both pass the cap check, and both send.
--
-- Returns the NEW count on success, or -1 if the cap is already reached.
-- ============================================================================

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
    -- Cap already reached (or contractor not found)
    RETURN -1;
  END IF;

  RETURN v_new_count;
END;
$$;

COMMENT ON FUNCTION public.increment_sms_usage IS
  'Atomically increment sms_used_this_month if under monthly_sms_cap. Returns new count or -1 if cap reached.';

-- ============================================================================
-- ✅ Migration complete
-- ============================================================================
