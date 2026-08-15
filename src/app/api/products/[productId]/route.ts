import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Product from '@/lib/models/product';
import { requireAdmin } from '@/lib/auth/utils';
import { errorResponse, NotFoundError } from '@/lib/api/errors';
import { productUpdateSchema } from '@/lib/validation/schemas';

/**
 * NOTE: there is deliberately no POST handler here.
 *
 * The previous one created products with no authentication and no role check,
 * ignoring `params.productId` entirely. Product creation belongs to the
 * collection route, POST /api/products, which is admin-guarded.
 */

// Get single product
export async function GET(
  request: NextRequest,
  { params }: { params: { productId: string } }
) {
  try {
    await dbConnect();

    const product = await Product.findOne({ originalId: params.productId });

    if (!product) {
      throw new NotFoundError('Product not found');
    }

    return NextResponse.json(product);
  } catch (error) {
    return errorResponse(error, 'products/[productId]/GET');
  }
}

// Update product (admin only)
export async function PUT(
  request: NextRequest,
  { params }: { params: { productId: string } }
) {
  try {
    await requireAdmin(request);
    await dbConnect();

    const body = productUpdateSchema.parse(await request.json());

    const product = await Product.findOneAndUpdate(
      { originalId: params.productId },
      body,
      { new: true, runValidators: true }
    );

    if (!product) {
      throw new NotFoundError('Product not found');
    }

    return NextResponse.json(product);
  } catch (error) {
    return errorResponse(error, 'products/[productId]/PUT');
  }
}

// Delete product (admin only)
export async function DELETE(
  request: NextRequest,
  { params }: { params: { productId: string } }
) {
  try {
    await requireAdmin(request);
    await dbConnect();

    const product = await Product.findOneAndDelete({ originalId: params.productId });

    if (!product) {
      throw new NotFoundError('Product not found');
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    return errorResponse(error, 'products/[productId]/DELETE');
  }
}
