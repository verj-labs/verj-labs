import { type SessionPayload } from '../types/session.types';

declare global {
  namespace Express {
    interface Request {
      user?: SessionPayload;
      sessionToken?: string;
    }
  }
}
