import { NextRequest, NextResponse } from "next/server";
import User from "@/lib/models/user";
import dbConnect from "@/lib/db";
import { generateToken } from "@/lib/auth/utils";
import { sessionCookie } from "@/lib/auth/cookies";
import { errorResponse } from "@/lib/api/errors";
import { registerSchema } from "@/lib/validation/schemas";

export async function POST(request: NextRequest) {
  try {
    await dbConnect();

    const { name, email, password } = registerSchema.parse(await request.json());

    const userExists = await User.findOne({ email });
    if (userExists) {
      return NextResponse.json({ error: "User already exists" }, { status: 400 });
    }

    // Fields are listed explicitly so a `role: "admin"` in the request body
    // cannot be mass-assigned; the schema default of "user" applies.
    const user = await User.create({ name, email, password });

    const token = await generateToken({
      userId: user._id.toString(),
      role: user.role,
    });

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
    return errorResponse(error, 'auth/register');
  }
}
