import { NextRequest, NextResponse } from "next/server";
import User from "@/lib/models/user";
import dbConnect from "@/lib/db";
import { generateToken } from "@/lib/auth/utils";
import { sessionCookie } from "@/lib/auth/cookies";
import { errorResponse } from "@/lib/api/errors";
import { loginSchema } from "@/lib/validation/schemas";

export async function POST(request: NextRequest) {
  try {
    await dbConnect();

    // Parsed before it reaches Mongoose so a body such as
    // `{"email": {"$ne": null}}` is rejected rather than treated as an operator.
    const { email, password } = loginSchema.parse(await request.json());

    const user = await User.findOne({ email }).select("+password");
    if (!user) {
      return NextResponse.json({ error: "Invalid credentials" }, { status: 401 });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return NextResponse.json({ error: "Invalid credentials" }, { status: 401 });
    }

    const token = await generateToken({
      userId: user._id.toString(),
      role: user.role,
    });

    // The token is returned in the httpOnly cookie only -- never in the body,
    // where client code could copy it somewhere script-readable.
    const response = NextResponse.json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });

    response.cookies.set(sessionCookie(token));

    return response;
  } catch (error) {
    return errorResponse(error, 'auth/login');
  }
}
