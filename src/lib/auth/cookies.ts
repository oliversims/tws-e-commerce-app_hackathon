/**
 * Single source of truth for the session cookie. Login, register and logout all
 * import from here so the attributes cannot drift apart -- a cookie cleared with
 * different `sameSite`/`path` attributes than it was set with may not be cleared
 * at all.
 */
export const AUTH_COOKIE_NAME = 'token';

/** 7 days, in seconds. */
export const AUTH_COOKIE_MAX_AGE = 7 * 24 * 60 * 60;

const isProduction = process.env.NODE_ENV === 'production';

export const authCookieOptions = {
  name: AUTH_COOKIE_NAME,
  httpOnly: true,
  secure: isProduction,
  sameSite: 'lax',
  path: '/',
} as const;

/** Options for setting a fresh session cookie. */
export function sessionCookie(token: string) {
  return {
    ...authCookieOptions,
    value: token,
    maxAge: AUTH_COOKIE_MAX_AGE,
  };
}

/** Options for clearing the session cookie. Must mirror `authCookieOptions`. */
export function clearedSessionCookie() {
  return {
    ...authCookieOptions,
    value: '',
    expires: new Date(0),
    maxAge: 0,
  };
}
