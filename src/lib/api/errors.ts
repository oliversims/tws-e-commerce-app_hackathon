import { NextResponse } from 'next/server';
import { ZodError } from 'zod';

/**
 * Errors that carry an HTTP status and a message that is safe to return to the
 * client. Anything that is not an ApiError is treated as an internal fault: it
 * is logged server-side and reported to the caller as a generic 500.
 */
export class ApiError extends Error {
  readonly status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

export class AuthenticationError extends ApiError {
  constructor(message = 'Authentication required') {
    super(message, 401);
    this.name = 'AuthenticationError';
  }
}

export class AuthorizationError extends ApiError {
  constructor(message = 'Insufficient permissions') {
    super(message, 403);
    this.name = 'AuthorizationError';
  }
}

export class ValidationError extends ApiError {
  constructor(message = 'Invalid request') {
    super(message, 400);
    this.name = 'ValidationError';
  }
}

export class NotFoundError extends ApiError {
  constructor(message = 'Not found') {
    super(message, 404);
    this.name = 'NotFoundError';
  }
}

/** Turns a ZodError into a short, non-leaking summary of the offending fields. */
function formatZodError(error: ZodError): string {
  const details = error.issues
    .slice(0, 5)
    .map((issue) => {
      const path = issue.path.join('.');
      return path ? `${path}: ${issue.message}` : issue.message;
    })
    .join('; ');

  return details || 'Invalid request';
}

/**
 * Single exit point for route handler failures. Deliberate 4xx errors keep their
 * message; everything else is logged and flattened to a generic 500 so that
 * Mongoose internals (schema paths, index names, duplicate-key values) never
 * reach the client.
 */
export function errorResponse(error: unknown, context: string) {
  if (error instanceof ZodError) {
    return NextResponse.json({ error: formatZodError(error) }, { status: 400 });
  }

  if (error instanceof ApiError) {
    return NextResponse.json({ error: error.message }, { status: error.status });
  }

  console.error(`[${context}]`, error);
  return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
}
