import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Cart from '@/lib/models/cart';
import Product from '@/lib/models/product';
import { requireAuth } from '@/lib/auth/utils';
import { errorResponse, NotFoundError } from '@/lib/api/errors';
import { addToCartSchema } from '@/lib/validation/schemas';
import { populateLineItems } from '@/lib/queries/populate';

async function cartResponse(cart: any) {
  const items = await populateLineItems(cart.items);
  return NextResponse.json({ ...cart.toObject(), items });
}

// Get user's cart
export async function GET(request: NextRequest) {
  try {
    const auth = await requireAuth(request);
    await dbConnect();

    const cart = await Cart.findOne({ user: auth.userId });

    if (!cart) {
      return NextResponse.json({ items: [], total: 0 });
    }

    return cartResponse(cart);
  } catch (error) {
    return errorResponse(error, 'cart/GET');
  }
}

// Add/Update cart item
export async function POST(request: NextRequest) {
  try {
    const auth = await requireAuth(request);
    await dbConnect();

    const { productId, quantity } = addToCartSchema.parse(await request.json());

    const product = await Product.findOne({ originalId: productId });
    if (!product) {
      throw new NotFoundError('Product not found');
    }

    let cart = await Cart.findOne({ user: auth.userId });
    if (!cart) {
      cart = new Cart({ user: auth.userId, items: [], total: 0 });
    }

    const existingItemIndex = cart.items.findIndex(
      (item) => item.product === product.originalId
    );

    // The price always comes from the catalogue, never from the request body.
    if (existingItemIndex > -1) {
      cart.items[existingItemIndex].quantity = quantity;
      cart.items[existingItemIndex].price = product.price;
    } else {
      cart.items.push({
        product: product.originalId,
        quantity,
        price: product.price,
      });
    }

    // `total` is recomputed by the schema's pre('save') hook.
    await cart.save();

    return cartResponse(cart);
  } catch (error) {
    return errorResponse(error, 'cart/POST');
  }
}

// Clear cart
export async function DELETE(request: NextRequest) {
  try {
    const auth = await requireAuth(request);
    await dbConnect();

    await Cart.findOneAndDelete({ user: auth.userId });

    return NextResponse.json({ success: true });
  } catch (error) {
    return errorResponse(error, 'cart/DELETE');
  }
}
