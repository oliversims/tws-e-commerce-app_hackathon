import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Cart from '@/lib/models/cart';
import Product from '@/lib/models/product';
import { requireAuth } from '@/lib/auth/utils';
import { errorResponse, NotFoundError } from '@/lib/api/errors';
import { updateCartItemSchema } from '@/lib/validation/schemas';
import { populateLineItems } from '@/lib/queries/populate';

async function cartResponse(cart: any) {
  const items = await populateLineItems(cart.items);
  return NextResponse.json({ ...cart.toObject(), items });
}

// Update cart item quantity
export async function PUT(
  request: NextRequest,
  { params }: { params: { productId: string } }
) {
  try {
    const auth = await requireAuth(request);
    await dbConnect();

    const { quantity } = updateCartItemSchema.parse(await request.json());

    const cart = await Cart.findOne({ user: auth.userId });
    if (!cart) {
      throw new NotFoundError('Cart not found');
    }

    const itemIndex = cart.items.findIndex(
      (item) => item.product === params.productId
    );

    if (itemIndex === -1) {
      throw new NotFoundError('Item not found in cart');
    }

    // Re-price from the catalogue on every mutation so a stale line price
    // cannot be carried forward.
    const product = await Product.findOne({ originalId: params.productId });
    if (!product) {
      throw new NotFoundError('Product not found');
    }

    cart.items[itemIndex].quantity = quantity;
    cart.items[itemIndex].price = product.price;

    await cart.save();

    return cartResponse(cart);
  } catch (error) {
    return errorResponse(error, 'cart/[productId]/PUT');
  }
}

// Remove item from cart
export async function DELETE(
  request: NextRequest,
  { params }: { params: { productId: string } }
) {
  try {
    const auth = await requireAuth(request);
    await dbConnect();

    const cart = await Cart.findOne({ user: auth.userId });
    if (!cart) {
      throw new NotFoundError('Cart not found');
    }

    cart.items = cart.items.filter((item) => item.product !== params.productId);

    await cart.save();

    return cartResponse(cart);
  } catch (error) {
    return errorResponse(error, 'cart/[productId]/DELETE');
  }
}
