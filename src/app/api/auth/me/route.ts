import { NextRequest, NextResponse } from "next/server";
import { requireAuth } from "@/lib/auth/utils";
import User from "@/lib/models/user";
import dbConnect from "@/lib/db";
import { errorResponse } from "@/lib/api/errors";

export async function GET(request: NextRequest) {
  try {
    const auth = await requireAuth(request);

    await dbConnect();
    const user = await User.findById(auth.userId).select("-password");

    if (!user) {
      return NextResponse.json({ error: "User not found" }, { status: 404 });
    }

    return NextResponse.json(user);
  } catch (error) {
    return errorResponse(error, 'auth/me');
  }
}
