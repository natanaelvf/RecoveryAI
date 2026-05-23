import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { isWithinWorkingHours } from '../utils/working-hours';
import { Contractor } from '../types';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

function makeContractor(overrides: Partial<Contractor> = {}): Contractor {
  return {
    id: 'contractor-001',
    business_name: 'Test Oy',
    contact_name: 'Matti',
    contact_email: 'matti@test.fi',
    contact_phone: '+358501234567',
    twilio_phone_number: '+358800123456',
    number_setup_type: 'forwarding',
    calendly_url: 'https://calendly.com/test',
    trade_type: 'plumber',
    default_job_value: 250,
    urgency_threshold_urgent_min: 60,
    urgency_threshold_normal_min: 1440,
    working_hours_start: '08:00',
    working_hours_end: '18:00',
    working_days: [1, 2, 3, 4, 5], // Mon-Fri
    after_hours_emergency_policy: '',
    after_hours_ring: false,
    timezone: 'Europe/Helsinki',
    tier: 'starter',
    monthly_sms_cap: 50,
    sms_used_this_month: 0,
    stripe_customer_id: null,
    fcm_token: null,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('Working Hours', () => {
  // We use vi.useFakeTimers to control the clock
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  describe('normal schedule (08:00–18:00)', () => {
    it('should return true during working hours on a working day', () => {
      // Wednesday 2024-01-10 at 12:00 Helsinki time (10:00 UTC)
      vi.setSystemTime(new Date('2024-01-10T10:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '08:00',
        working_hours_end: '18:00',
        working_days: [1, 2, 3, 4, 5],
      });

      expect(isWithinWorkingHours(contractor)).toBe(true);
    });

    it('should return false before working hours', () => {
      // Wednesday 2024-01-10 at 06:00 Helsinki time (04:00 UTC)
      vi.setSystemTime(new Date('2024-01-10T04:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '08:00',
        working_hours_end: '18:00',
        working_days: [1, 2, 3, 4, 5],
      });

      expect(isWithinWorkingHours(contractor)).toBe(false);
    });

    it('should return false after working hours', () => {
      // Wednesday 2024-01-10 at 20:00 Helsinki time (18:00 UTC)
      vi.setSystemTime(new Date('2024-01-10T18:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '08:00',
        working_hours_end: '18:00',
        working_days: [1, 2, 3, 4, 5],
      });

      expect(isWithinWorkingHours(contractor)).toBe(false);
    });

    it('should return true at exactly start time', () => {
      // Wednesday 2024-01-10 at 08:00 Helsinki time (06:00 UTC)
      vi.setSystemTime(new Date('2024-01-10T06:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '08:00',
        working_hours_end: '18:00',
        working_days: [1, 2, 3, 4, 5],
      });

      expect(isWithinWorkingHours(contractor)).toBe(true);
    });

    it('should return false at exactly end time (exclusive)', () => {
      // Wednesday 2024-01-10 at 18:00 Helsinki time (16:00 UTC)
      vi.setSystemTime(new Date('2024-01-10T16:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '08:00',
        working_hours_end: '18:00',
        working_days: [1, 2, 3, 4, 5],
      });

      expect(isWithinWorkingHours(contractor)).toBe(false);
    });
  });

  describe('overnight schedule (20:00–06:00)', () => {
    it('should return true during late-night hours', () => {
      // Wednesday 2024-01-10 at 23:00 Helsinki time (21:00 UTC)
      vi.setSystemTime(new Date('2024-01-10T21:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '20:00',
        working_hours_end: '06:00',
        working_days: [1, 2, 3, 4, 5],
      });

      expect(isWithinWorkingHours(contractor)).toBe(true);
    });

    it('should return true during early-morning hours', () => {
      // Thursday 2024-01-11 at 03:00 Helsinki time (01:00 UTC)
      vi.setSystemTime(new Date('2024-01-11T01:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '20:00',
        working_hours_end: '06:00',
        working_days: [1, 2, 3, 4, 5], // Thursday is working day
      });

      expect(isWithinWorkingHours(contractor)).toBe(true);
    });

    it('should return false during daytime', () => {
      // Wednesday 2024-01-10 at 12:00 Helsinki time (10:00 UTC)
      vi.setSystemTime(new Date('2024-01-10T10:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '20:00',
        working_hours_end: '06:00',
        working_days: [1, 2, 3, 4, 5],
      });

      expect(isWithinWorkingHours(contractor)).toBe(false);
    });
  });

  describe('non-working days', () => {
    it('should return false on Saturday when working days are Mon-Fri', () => {
      // Saturday 2024-01-13 at 12:00 Helsinki time (10:00 UTC)
      vi.setSystemTime(new Date('2024-01-13T10:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '08:00',
        working_hours_end: '18:00',
        working_days: [1, 2, 3, 4, 5], // Mon-Fri only
      });

      expect(isWithinWorkingHours(contractor)).toBe(false);
    });

    it('should return false on Sunday', () => {
      // Sunday 2024-01-14 at 12:00 Helsinki time (10:00 UTC)
      vi.setSystemTime(new Date('2024-01-14T10:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '08:00',
        working_hours_end: '18:00',
        working_days: [1, 2, 3, 4, 5],
      });

      expect(isWithinWorkingHours(contractor)).toBe(false);
    });

    it('should return true on Saturday when working days include Saturday', () => {
      // Saturday 2024-01-13 at 12:00 Helsinki time (10:00 UTC)
      vi.setSystemTime(new Date('2024-01-13T10:00:00Z'));

      const contractor = makeContractor({
        timezone: 'Europe/Helsinki',
        working_hours_start: '08:00',
        working_hours_end: '18:00',
        working_days: [1, 2, 3, 4, 5, 6], // Mon-Sat
      });

      expect(isWithinWorkingHours(contractor)).toBe(true);
    });
  });

  describe('timezone handling', () => {
    it('should correctly handle UTC timezone', () => {
      // 2024-01-10 at 12:00 UTC
      vi.setSystemTime(new Date('2024-01-10T12:00:00Z'));

      const contractor = makeContractor({
        timezone: 'UTC',
        working_hours_start: '08:00',
        working_hours_end: '18:00',
        working_days: [1, 2, 3, 4, 5],
      });

      expect(isWithinWorkingHours(contractor)).toBe(true);
    });

    it('should correctly handle US Eastern timezone', () => {
      // 2024-01-10 at 20:00 UTC = 15:00 US Eastern (within hours)
      vi.setSystemTime(new Date('2024-01-10T20:00:00Z'));

      const contractor = makeContractor({
        timezone: 'America/New_York',
        working_hours_start: '08:00',
        working_hours_end: '18:00',
        working_days: [1, 2, 3, 4, 5],
      });

      expect(isWithinWorkingHours(contractor)).toBe(true);
    });
  });
});
