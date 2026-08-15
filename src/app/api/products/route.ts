import { NextResponse, NextRequest } from 'next/server';
import dbConnect from '@/lib/db';
import Product from '@/lib/models/product';
import { requireAdmin } from '@/lib/auth/utils';
import { errorResponse } from '@/lib/api/errors';
import { productInputSchema } from '@/lib/validation/schemas';
import { queryProducts } from '@/lib/queries/products';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);

    // Filtering, sorting and pagination all live in the shared query layer so
    // Server Components get identical behaviour without an HTTP round-trip.
    const result = await queryProducts({
      q: searchParams.get('q') || searchParams.get('search'),
      shop_category: searchParams.get('shop_category'),
      categories: searchParams.get('categories'),
      color: searchParams.get('color'),
      minPrice: searchParams.get('minPrice'),
      maxPrice: searchParams.get('maxPrice'),
      page: searchParams.get('page'),
      limit: searchParams.get('limit'),
      sort: searchParams.get('sort'),
      order: searchParams.get('order'),
    });

    return NextResponse.json(result);
  } catch (error) {
    return errorResponse(error, 'products/GET');
  }
}

export async function POST(request: NextRequest) {
  try {
    await requireAdmin(request);
    await dbConnect();

    // Allowlisted fields only -- an unvalidated body would let a typo write
    // arbitrary keys into the collection.
    const body = productInputSchema.parse(await request.json());
    const product = await Product.create(body);

    return NextResponse.json(product, { status: 201 });
  } catch (error) {
    return errorResponse(error, 'products/POST');
  }
}
