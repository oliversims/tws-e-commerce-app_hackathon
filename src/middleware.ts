import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { getTokenFromRequest, verifyToken } from "./lib/auth/utils";
import { safeRedirectPath } from "./lib/auth/safeRedirect";

export async function middleware(request: NextRequest) {
  // Read the cookie once and verify it once.
  const token = getTokenFromRequest(request);
  const isAuth = token ? await verifyToken(token) : null;

  const isAuthPage =
    request.nextUrl.pathname.startsWith("/login") ||
    request.nextUrl.pathname.startsWith("/register");
  const protectedRoutes = ["/checkout", "/profile", "/admin"];
  const isProtectedRoute = protectedRoutes.some((route) =>
    request.nextUrl.pathname.startsWith(route)
  );

  // If trying to access protected routes without authentication
  if (isProtectedRoute && !isAuth) {
    const redirectUrl = new URL("/login", request.url);
    redirectUrl.searchParams.set("redirect", request.nextUrl.pathname);
    return NextResponse.redirect(redirectUrl);
  }

  // If trying to access auth pages while logged in
  if (isAuthPage && isAuth) {
    const redirectTo = safeRedirectPath(
      request.nextUrl.searchParams.get("redirect")
    );
    return NextResponse.redirect(new URL(redirectTo, request.url));
  }

  // If trying to access admin pages without admin role
  if (request.nextUrl.pathname.startsWith("/admin") && isAuth?.role !== "admin") {
    return NextResponse.redirect(new URL("/", request.url));
  }

  // Forward the verified identity downstream. The headers are cleared first so
  // that client-supplied `x-user-id` / `x-user-role` values can never survive
  // into a route handler on an unauthenticated request.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.delete("x-user-id");
  requestHeaders.delete("x-user-role");

  if (isAuth) {
    requestHeaders.set("x-user-id", isAuth.userId);
    requestHeaders.set("x-user-role", isAuth.role);
  }

  return NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  });
}

export const config = {
  matcher: [
    '/checkout',
    '/checkout/:path*',
    '/profile/:path*',
    '/admin/:path*',
    '/login',
    '/register'
  ]
};
