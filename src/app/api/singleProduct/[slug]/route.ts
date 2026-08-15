import { NextResponse } from 'next/server';
import { errorResponse, NotFoundError } from '@/lib/api/errors';
import { findProductBySlug } from '@/lib/queries/products';

export async function GET(
  request: Request,
  { params }: { params: { slug: string } }
) {
  try {
    const product = await findProductBySlug(params.slug);

    if (!product) {
      throw new NotFoundError('Product not found');
    }

    return NextResponse.json(product);
  } catch (error) {
    return errorResponse(error, 'singleProduct/[slug]/GET');
  }
}
