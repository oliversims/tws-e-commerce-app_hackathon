import { NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Product from '@/lib/models/product';
import { errorResponse } from '@/lib/api/errors';

export async function GET() {
  try {
    await dbConnect();

    const products = await Product.find({ shop_category: 'books' })
      .sort({ createdAt: -1 })
      .limit(10);

    return NextResponse.json({ products });
  } catch (error) {
    return errorResponse(error, 'products/books/GET');
  }
}
