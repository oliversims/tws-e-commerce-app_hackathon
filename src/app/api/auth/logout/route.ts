import { NextResponse } from "next/server";
import { clearedSessionCookie } from "@/lib/auth/cookies";

export async function POST() {
  const response = NextResponse.json({ success: true });

  // Attributes mirror the ones the cookie was set with; a mismatch on
  // sameSite/path can leave the original cookie in place.
  response.cookies.set(clearedSessionCookie());

  return response;
}
