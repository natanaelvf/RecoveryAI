import { Request, Response, NextFunction } from 'express';
import { supabase } from '../config/supabase';

/**
 * Express middleware that validates a Supabase JWT from the Authorization header
 * and attaches the contractor_id to the request.
 */
export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header' });
    return;
  }

  const token = authHeader.slice(7);

  try {
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser(token);

    if (error || !user) {
      res.status(401).json({ error: 'Invalid or expired token' });
      return;
    }

    // The contractor_id is stored in the user's metadata or equals the user id.
    // TODO: Adjust this mapping if contractor_id differs from auth user id
    req.contractorId = user.id;
    next();
  } catch (err) {
    res.status(500).json({ error: 'Authentication check failed' });
  }
}
