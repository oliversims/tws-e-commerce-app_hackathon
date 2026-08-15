"use server";

import { cookies } from 'next/headers';
import { AUTH_COOKIE_NAME } from '@/lib/auth/cookies';
import { verifyToken } from '@/lib/auth/utils';

/**
 * NOTE: there is deliberately no `createCookies` action here.
 *
 * The session cookie is issued by /api/auth/login and /api/auth/register as an
 * httpOnly, Secure cookie and is applied to the browser by the response itself.
 * The previous client-invoked action re-set the same cookie with
 * `httpOnly: false, secure: false`, which overwrote the hardened cookie and
 * exposed the session token to any script on the origin.
 */

export async function removeCookies() {
  cookies().delete({
    name: AUTH_COOKIE_NAME,
    path: "/",
  });
}

export async function getCookies(name: string) {
  return cookies().get(name);
}

/**
 * Verifies the session token rather than merely checking that a cookie exists,
 * so an expired or forged token no longer renders the logged-in UI.
 */
export async function authenticated() {
  const token = cookies().get(AUTH_COOKIE_NAME)?.value;
  if (!token) return false;

  const payload = await verifyToken(token);
  return payload !== null;
}
