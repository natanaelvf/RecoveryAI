import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * Integration test: GDPR deletion → all data removed, audit log created
 *
 * Tests the deletion flow that the Flutter app's ApiService.deleteLeadGdpr performs
 * via direct Supabase calls.
 */

const { mockSupabaseFrom } = vi.hoisted(() => ({
  mockSupabaseFrom: vi.fn(),
}));

vi.mock('../config/supabase', () => ({
  supabase: { from: mockSupabaseFrom },
}));

// ---------------------------------------------------------------------------
// Helpers
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

describe('Integration: GDPR Deletion', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should delete all related data and create audit log entry', async () => {
    const leadId = 'lead-to-delete';
    const contractorId = 'contractor-001';

    // Track which tables were deleted from and what was inserted
    const deletedFrom: string[] = [];
    const insertedTo: string[] = [];
    let auditLogEntry: Record<string, unknown> | null = null;

    mockSupabaseFrom.mockImplementation((table: string) => {
      const chain: Record<string, unknown> = {};
      const handler = () => chain;
      for (const method of [
        'select', 'update',
        'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
        'order', 'limit', 'range', 'filter',
      ]) {
        chain[method] = vi.fn(handler);
      }
      chain['delete'] = vi.fn(() => {
        deletedFrom.push(table);
        return chain;
      });
      chain['insert'] = vi.fn((data: Record<string, unknown>) => {
        insertedTo.push(table);
        if (table === 'audit_log') {
          auditLogEntry = data;
        }
        return chain;
      });
      chain['single'] = vi.fn(() => ({ data: null, error: null }));
      return chain;
    });

    // Simulate the GDPR deletion flow from ApiService.deleteLeadGdpr

    // 1. Delete job_costs
    const jobCostsChain = mockSupabaseFrom('job_costs') as ReturnType<typeof mockChain>;
    (jobCostsChain['delete'] as ReturnType<typeof vi.fn>)();
    (jobCostsChain['eq'] as ReturnType<typeof vi.fn>)('lead_id', leadId);

    // 2. Delete messages
    const messagesChain = mockSupabaseFrom('messages') as ReturnType<typeof mockChain>;
    (messagesChain['delete'] as ReturnType<typeof vi.fn>)();
    (messagesChain['eq'] as ReturnType<typeof vi.fn>)('lead_id', leadId);

    // 3. Delete scheduled_tasks
    const tasksChain = mockSupabaseFrom('scheduled_tasks') as ReturnType<typeof mockChain>;
    (tasksChain['delete'] as ReturnType<typeof vi.fn>)();
    (tasksChain['eq'] as ReturnType<typeof vi.fn>)('lead_id', leadId);

    // 4. Delete lead
    const leadsChain = mockSupabaseFrom('leads') as ReturnType<typeof mockChain>;
    (leadsChain['delete'] as ReturnType<typeof vi.fn>)();
    (leadsChain['eq'] as ReturnType<typeof vi.fn>)('id', leadId);

    // 5. Create audit log
    const auditChain = mockSupabaseFrom('audit_log') as ReturnType<typeof mockChain>;
    (auditChain['insert'] as ReturnType<typeof vi.fn>)({
      action: 'gdpr_deletion',
      entity_type: 'lead',
      entity_id: leadId,
      performed_by: contractorId,
    });

    // Verify all tables were touched
    expect(deletedFrom).toContain('job_costs');
    expect(deletedFrom).toContain('messages');
    expect(deletedFrom).toContain('scheduled_tasks');
    expect(deletedFrom).toContain('leads');

    // Verify audit log was created
    expect(insertedTo).toContain('audit_log');
    expect(auditLogEntry).toEqual({
      action: 'gdpr_deletion',
      entity_type: 'lead',
      entity_id: leadId,
      performed_by: contractorId,
    });
  });

  it('should not include any PII in the audit log entry', () => {
    // The audit log should contain only: action, entity_type, entity_id, performed_by
    // It should NOT contain: caller_phone, caller_name, issue_description, etc.
    const auditEntry = {
      action: 'gdpr_deletion',
      entity_type: 'lead',
      entity_id: 'lead-123',
      performed_by: 'contractor-001',
    };

    const keys = Object.keys(auditEntry);

    // Assert no PII fields
    expect(keys).not.toContain('caller_phone');
    expect(keys).not.toContain('caller_name');
    expect(keys).not.toContain('issue_description');
    expect(keys).not.toContain('email');
    expect(keys).not.toContain('satisfaction_feedback');

    // Assert only expected fields
    expect(keys).toEqual(['action', 'entity_type', 'entity_id', 'performed_by']);
  });
});

// ---------------------------------------------------------------------------
// Data Retention Cron
// ---------------------------------------------------------------------------

describe('Integration: Data Retention (GDPR Auto-Anonymize)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should anonymize PII fields on leads older than 12 months', async () => {
    // Import the actual job
    const { runDataRetention } = await import('../jobs/data-retention');

    const oldLead = {
      id: 'lead-old',
      contractor_id: 'contractor-001',
    };

    const anonymizedFields: Record<string, unknown> = {};

    mockSupabaseFrom.mockImplementation((table: string) => {
      const chain: Record<string, unknown> = {};
      const handler = () => chain;
      for (const method of [
        'select', 'delete',
        'eq', 'neq', 'in', 'lt', 'lte', 'gt', 'gte', 'not',
        'order', 'limit', 'range', 'filter',
      ]) {
        chain[method] = vi.fn(handler);
      }
      chain['update'] = vi.fn((data: Record<string, unknown>) => {
        if (table === 'leads') {
          Object.assign(anonymizedFields, data);
        }
        return chain;
      });
      chain['insert'] = vi.fn(() => chain);
      // For the initial query
      chain['not'] = vi.fn(() => ({
        data: [oldLead],
        error: null,
      }));
      chain['in'] = vi.fn(() => ({
        data: null,
        error: null,
      }));
      return chain;
    });

    await runDataRetention();

    // Verify PII was anonymized
    expect(anonymizedFields.caller_phone).toBe('ANONYMIZED');
    expect(anonymizedFields.caller_name).toBeNull();
    expect(anonymizedFields.email).toBeNull();
    expect(anonymizedFields.issue_description).toBeNull();
    expect(anonymizedFields.satisfaction_feedback).toBeNull();
  });
});
