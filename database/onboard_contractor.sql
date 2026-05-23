-- Onboard a new contractor
-- Usage: Replace the placeholder values below, then run in Supabase SQL Editor.
--
-- IMPORTANT: The contractor's `id` MUST match their Supabase Auth user UUID.
-- Create the Auth user first, get the UUID, then use it here.

-- Step 1: Get the user UUID from Supabase Auth (replace with actual value)
-- You can find this in Supabase Dashboard → Authentication → Users

DO $$
DECLARE
  -- ┌──────────────────────────────────────────────────────────────┐
  -- │  FILL IN THESE VALUES FOR EACH NEW CONTRACTOR              │
  -- └──────────────────────────────────────────────────────────────┘
  v_auth_user_id     uuid    := 'REPLACE_WITH_AUTH_USER_UUID';
  v_business_name    text    := 'Example Plumbing Oy';
  v_contact_name     text    := 'Matti Meikäläinen';
  v_contact_email    text    := 'matti@example.fi';
  v_contact_phone    text    := '+358401234567';
  v_twilio_number    text    := '+358XXXXXXXXXX';  -- Twilio number
  v_setup_type       text    := 'forwarding';       -- 'forwarding' or 'new_number'
  v_calendly_url     text    := 'https://calendly.com/example-plumbing';
  v_trade_type       text    := 'plumber';          -- plumber | hvac | electrician | roofer | other
  v_default_job_val  decimal := 250.00;             -- typical job value in EUR
  v_urgent_min       int     := 60;                 -- DNR alert threshold for urgent (minutes)
  v_normal_min       int     := 1440;               -- DNR alert threshold for normal (minutes)
  v_hours_start      time    := '08:00';
  v_hours_end        time    := '18:00';
  v_working_days     int[]   := '{1,2,3,4,5}';     -- 1=Mon..7=Sun
  v_emergency_policy text    := 'Vesivahingot ja putkivuodot ovat hätätilanteita.';
  v_after_hours_ring boolean := false;
  v_timezone         text    := 'Europe/Helsinki';
  v_tier             text    := 'starter';
  v_sms_cap          int     := 50;
  v_locale           text    := 'fi';               -- 'fi' for Finnish, 'en' for English
BEGIN
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
    monthly_sms_cap,
    sms_used_this_month,
    locale,
    created_at,
    updated_at
  ) VALUES (
    v_auth_user_id,
    v_business_name,
    v_contact_name,
    v_contact_email,
    v_contact_phone,
    v_twilio_number,
    v_setup_type,
    v_calendly_url,
    v_trade_type,
    v_default_job_val,
    v_urgent_min,
    v_normal_min,
    v_hours_start,
    v_hours_end,
    v_working_days,
    v_emergency_policy,
    v_after_hours_ring,
    v_timezone,
    v_tier,
    v_sms_cap,
    0,
    v_locale,
    now(),
    now()
  );

  RAISE NOTICE 'Contractor "%" created with ID %', v_business_name, v_auth_user_id;
END $$;
