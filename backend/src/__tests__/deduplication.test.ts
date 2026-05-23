import { describe, it, expect, vi, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mock Supabase using vi.hoisted() to avoid hoisting issues
// ---------------------------------------------------------------------------

const { mockSupabaseFrom } = vi.hoisted(() => ({
  mockSupabaseFrom: vi.fn(),
}));

vi.mock('../config/supabase', () => ({
  supabase: { from: mockSupabaseFrom },
}));

import { findOrCreateLead } from '../services/deduplication';

// ---------------------------------------------------------------------------
// Supabase mock helpers
// ---------------------------------------------------------------------------

function mockChain(data: unknown = null, error: unknown = null) {
  const chain: Record<string, unknown> = {};
  const handler = () => chain;

  for (const method of [
    'select', 'insert', 'update', 'delete',
    'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
    'order', 'limit', 'range', 'filter',
  ]) {
    chain[method] = vi.fn(handler);
  }

  chain['single'] = vi.fn(() => ({ data, error }));
  return chain;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('Lead Deduplication', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('new lead creation', () => {
    it('should create a new lead when no recent lead exists', async () => {
      const contractorId = 'contractor-001';
      const callerPhone = '+358401234567';

      // First query: no existing lead found
      const findChain = mockChain(null, { message: 'Not found', code: 'PGRST116' });
      // Second query: contractor default job value
      const contractorChain = mockChain({ default_job_value: 250 });
      // Third query: insert new lead
      const newLead = {
        id: 'lead-new',
        contractor_id: contractorId,
        caller_phone: callerPhone,
        call_count: 1,
        status: 'missed',
        called_during_after_hours: false,
      };
      const insertChain = mockChain(newLead);

      let callCount = 0;
      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') {
          callCount++;
          if (callCount === 1) return findChain;    // find existing
          if (callCount === 2) return insertChain;   // insert new
        }
        if (table === 'contractors') return contractorChain;
        return mockChain();
      });

      const result = await findOrCreateLead(contractorId, callerPhone, false);

      expect(result.isNew).toBe(true);
      expect(result.lead.id).toBe('lead-new');
    });

    it('should mark lead as after-hours when calledDuringAfterHours is true', async () => {
      const findChain = mockChain(null, { message: 'Not found', code: 'PGRST116' });
      const contractorChain = mockChain({ default_job_value: 200 });
      const insertChain = mockChain({
        id: 'lead-ah',
        called_during_after_hours: true,
        call_count: 1,
        status: 'missed',
      });

      let callCount = 0;
      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') {
          callCount++;
          if (callCount === 1) return findChain;
          if (callCount === 2) return insertChain;
        }
        if (table === 'contractors') return contractorChain;
        return mockChain();
      });

      const result = await findOrCreateLead('contractor-001', '+358401234567', true);

      expect(result.isNew).toBe(true);
      expect(result.lead.called_during_after_hours).toBe(true);
    });

    it('should use contractor default_job_value for estimated_value', async () => {
      const findChain = mockChain(null, { message: 'Not found' });
      const contractorChain = mockChain({ default_job_value: 350 });
      const insertChain = mockChain({
        id: 'lead-val',
        estimated_value: 350,
        call_count: 1,
        status: 'missed',
      });

      let callCount = 0;
      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') {
          callCount++;
          if (callCount === 1) return findChain;
          if (callCount === 2) return insertChain;
        }
        if (table === 'contractors') return contractorChain;
        return mockChain();
      });

      const result = await findOrCreateLead('contractor-001', '+358401234567', false);
      expect(result.lead.estimated_value).toBe(350);
    });
  });

  describe('duplicate detection (same phone within 24h)', () => {
    it('should increment call_count for duplicate caller', async () => {
      const existingLead = {
        id: 'lead-existing',
        contractor_id: 'contractor-001',
        caller_phone: '+358401234567',
        call_count: 1,
        status: 'consent_sent',
      };

      const updatedLead = { ...existingLead, call_count: 2 };

      // First query: existing lead found
      const findChain = mockChain(existingLead);
      // Second query: update call count
      const updateChain = mockChain(updatedLead);

      let callCount = 0;
      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') {
          callCount++;
          if (callCount === 1) return findChain;
          if (callCount === 2) return updateChain;
        }
        return mockChain();
      });

      const result = await findOrCreateLead('contractor-001', '+358401234567', false);

      expect(result.isNew).toBe(false);
      expect(result.lead.call_count).toBe(2);
    });
  });

  describe('error handling', () => {
    it('should throw on insert failure', async () => {
      const findChain = mockChain(null, { message: 'Not found' });
      const contractorChain = mockChain({ default_job_value: 250 });
      const insertChain = mockChain(null, { message: 'Insert failed' });

      let callCount = 0;
      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') {
          callCount++;
          if (callCount === 1) return findChain;
          if (callCount === 2) return insertChain;
        }
        if (table === 'contractors') return contractorChain;
        return mockChain();
      });

      await expect(
        findOrCreateLead('contractor-001', '+358401234567', false)
      ).rejects.toThrow('Failed to create lead');
    });

    it('should throw on update failure for duplicate', async () => {
      const existingLead = {
        id: 'lead-existing',
        call_count: 1,
      };

      const findChain = mockChain(existingLead);
      const updateChain = mockChain(null, { message: 'Update failed' });

      let callCount = 0;
      mockSupabaseFrom.mockImplementation((table: string) => {
        if (table === 'leads') {
          callCount++;
          if (callCount === 1) return findChain;
          if (callCount === 2) return updateChain;
        }
        return mockChain();
      });

      await expect(
        findOrCreateLead('contractor-001', '+358401234567', false)
      ).rejects.toThrow('Failed to update lead call_count');
    });
  });
});
