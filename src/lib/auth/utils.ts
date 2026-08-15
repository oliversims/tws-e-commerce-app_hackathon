import { NextRequest } from 'next/server';
import { jwtVerify, SignJWT } from 'jose';
import { AUTH_COOKIE_NAME } from './cookies';
import { AuthenticationError, AuthorizationError } from '../api/errors';

/**
 * Fail closed: a missing or weak JWT_SECRET must stop the process rather than
 * silently fall back to a shared literal that anyone could use to mint an admin
 * token. Resolved lazily so that importing this module (which the middleware
 * does at build time) does not throw during `next build`.
 */
const MIN_SECRET_LENGTH = 32;

let cachedSecret: Uint8Array | null = null;

function getJwtSecret(): Uint8Array {
  if (cachedSecret) return cachedSecret;

  const secret = process.env.JWT_SECRET;

  if (!secret || secret.length < MIN_SECRET_LENGTH) {
    throw new Error(
      `JWT_SECRET must be set to a value of at least ${MIN_SECRET_LENGTH} characters. ` +
        'Generate one with: openssl rand -hex 32'
    );
  }

  cachedSecret = new TextEncoder().encode(secret);
  return cachedSecret;
}

/** Session lifetime. Kept in step with AUTH_COOKIE_MAX_AGE in ./cookies. */
const TOKEN_EXPIRY = '7d';

export interface JWTPayload {
  userId: string;
  role: string;
  [key: string]: string;
}

export const generateToken = async (payload: JWTPayload): Promise<string> => {
  return new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(TOKEN_EXPIRY)
    .sign(getJwtSecret());
};

export const verifyToken = async (token: string): Promise<JWTPayload | null> => {
  if (!token || token === 'undefined' || token === '[object Object]') {
    return null;
  }

  try {
    const { payload } = await jwtVerify(token, getJwtSecret());

    if (typeof payload.userId !== 'string' || typeof payload.role !== 'string') {
      return null;
    }

    return {
      userId: payload.userId,
      role: payload.role,
    };
  } catch {
    // Expired, malformed and forged tokens are all simply "not authenticated".
    // Deliberately not logged: the token itself must never reach the log sink.
    return null;
  }
};

export const getTokenFromRequest = (request: NextRequest): string | null => {
  const token = request.cookies.get(AUTH_COOKIE_NAME)?.value;

  if (!token || token === 'undefined' || token === '[object Object]') {
    return null;
  }

  return token;
};

export const isAuthenticated = async (request: NextRequest) => {
  const token = getTokenFromRequest(request);
  if (!token) return null;

  return verifyToken(token);
};

export const requireAuth = async (request: NextRequest) => {
  const auth = await isAuthenticated(request);
  if (!auth) {
    throw new AuthenticationError();
  }
  return auth;
};

export const requireRole = async (request: NextRequest, roles: string[]) => {
  const auth = await requireAuth(request);
  if (!roles.includes(auth.role)) {
    throw new AuthorizationError();
  }
  return auth;
};

export const requireAdmin = async (request: NextRequest) => requireRole(request, ['admin']);
