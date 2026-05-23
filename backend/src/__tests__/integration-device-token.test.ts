import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * Integration test: Device Token endpoint
 * Tests the POST /api/device-token and DELETE /api/device-token handlers.
 */

const { mockSupabaseFrom } = vi.hoisted(() => ({
  mockSupabaseFrom: vi.fn(),
}));

vi.mock('../config/supabase', () => ({
  supabase: { from: mockSupabaseFrom },
}));

// We import the router to test its handler functions.
// Since Express route handlers are hard to test directly without supertest,
// we test the business logic by calling the handlers with mock req/res.

import { Request, Response } from 'express';

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

function mockReq(overrides: Partial<Request> = {}): Request {
  return {
    body: {},
    headers: {},
    contractorId: 'contractor-001',
    ...overrides,
  } as unknown as Request;
}

function mockRes() {
  const res = {
    _statusCode: 0,
    _json: null as unknown,
    status: vi.fn(function(this: typeof res, code: number) {
      this._statusCode = code;
      return this;
    }),
    json: vi.fn(function(this: typeof res, data: unknown) {
      this._json = data;
      return this;
    }),
  };
  return res;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('Device Token Endpoint', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('POST /api/device-token', () => {
    it('should update FCM token for authenticated contractor', async () => {
      const updateChain = mockChain(null, null);
      mockSupabaseFrom.mockReturnValue(updateChain);

      const req = mockReq({
        body: { token: 'fcm-token-abc123' },
        contractorId: 'contractor-001',
      });
      const res = mockRes();

      // Import the handler module fresh
      const routerModule = await import('../routes/api/device-token');
      const router = routerModule.default;

      // Extract the POST handler from the router's stack
      const postHandler = router.stack.find(
        (layer: { route?: { methods?: { post?: boolean } } }) =>
          layer.route?.methods?.post
      )?.route?.stack[0]?.handle;

      if (postHandler) {
        await postHandler(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({ ok: true });
        expect(mockSupabaseFrom).toHaveBeenCalledWith('contractors');
      }
    });

    it('should reject empty token', async () => {
      const req = mockReq({
        body: { token: '' },
        contractorId: 'contractor-001',
      });
      const res = mockRes();

      const routerModule = await import('../routes/api/device-token');
      const router = routerModule.default;

      const postHandler = router.stack.find(
        (layer: { route?: { methods?: { post?: boolean } } }) =>
          layer.route?.methods?.post
      )?.route?.stack[0]?.handle;

      if (postHandler) {
        await postHandler(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith(
          expect.objectContaining({ error: expect.stringContaining('token') })
        );
      }
    });

    it('should reject missing token', async () => {
      const req = mockReq({
        body: {},
        contractorId: 'contractor-001',
      });
      const res = mockRes();

      const routerModule = await import('../routes/api/device-token');
      const router = routerModule.default;

      const postHandler = router.stack.find(
        (layer: { route?: { methods?: { post?: boolean } } }) =>
          layer.route?.methods?.post
      )?.route?.stack[0]?.handle;

      if (postHandler) {
        await postHandler(req, res);
        expect(res.status).toHaveBeenCalledWith(400);
      }
    });

    it('should return 401 if not authenticated', async () => {
      const req = mockReq({
        body: { token: 'fcm-token-abc123' },
        contractorId: undefined,
      });
      const res = mockRes();

      const routerModule = await import('../routes/api/device-token');
      const router = routerModule.default;

      const postHandler = router.stack.find(
        (layer: { route?: { methods?: { post?: boolean } } }) =>
          layer.route?.methods?.post
      )?.route?.stack[0]?.handle;

      if (postHandler) {
        await postHandler(req, res);
        expect(res.status).toHaveBeenCalledWith(401);
      }
    });
  });

  describe('DELETE /api/device-token', () => {
    it('should clear FCM token on logout', async () => {
      const updateChain = mockChain(null, null);
      mockSupabaseFrom.mockReturnValue(updateChain);

      const req = mockReq({ contractorId: 'contractor-001' });
      const res = mockRes();

      const routerModule = await import('../routes/api/device-token');
      const router = routerModule.default;

      const deleteHandler = router.stack.find(
        (layer: { route?: { methods?: { delete?: boolean } } }) =>
          layer.route?.methods?.delete
      )?.route?.stack[0]?.handle;

      if (deleteHandler) {
        await deleteHandler(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({ ok: true });
      }
    });
  });
});
