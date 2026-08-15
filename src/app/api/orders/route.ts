import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Order from '@/lib/models/order';
import Cart from '@/lib/models/cart';
import Product from '@/lib/models/product';
import { requireAuth } from '@/lib/auth/utils';
import { errorResponse, ValidationError } from '@/lib/api/errors';
import { createOrderSchema, type AddressInput } from '@/lib/validation/schemas';
import { populateLineItems } from '@/lib/queries/populate';
import { calculateOrderTotal } from '@/lib/commerce/pricing';

const MAX_ORDERS_PER_PAGE = 50;

// Get user's orders
export async function GET(request: NextRequest) {
  try {
    const auth = await requireAuth(request);
    await dbConnect();

    const { searchParams } = new URL(request.url);
    const page = Math.max(1, Number.parseInt(searchParams.get('page') || '1', 10) || 1);
    const limit = Math.min(
      MAX_ORDERS_PER_PAGE,
      Math.max(1, Number.parseInt(searchParams.get('limit') || '5', 10) || 5)
    );
    const skip = (page - 1) * limit;

    const [orders, total] = await Promise.all([
      Order.find({ user: auth.userId }).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Order.countDocuments({ user: auth.userId }),
    ]);

    const populatedOrders = await Promise.all(
      orders.map(async (order) => ({
        ...order.toObject(),
        items: await populateLineItems(order.items),
      }))
    );

    return NextResponse.json({
      orders: populatedOrders,
      total,
      page,
      limit,
    });
  } catch (error) {
    return errorResponse(error, 'orders/GET');
  }
}

function mapAddress(address: AddressInput) {
  return {
    fullName: address.title,
    address: address.streetAddress,
    city: address.city,
    postalCode: address.zip,
    country: address.country,
  };
}

// Create new order
export async function POST(request: NextRequest) {
  try {
    const auth = await requireAuth(request);
    await dbConnect();

    const { shippingAddress, billingAddress, paymentMethod, items } =
      createOrderSchema.parse(await request.json());

    // Collapse duplicate product ids so the same line cannot be submitted twice
    // to inflate quantity past the per-line cap.
    const requestedQuantities = new Map<string, number>();
    for (const item of items) {
      requestedQuantities.set(
        item.productId,
        (requestedQuantities.get(item.productId) ?? 0) + item.quantity
      );
    }

    const productIds = Array.from(requestedQuantities.keys());

    // Every product is resolved against the catalogue in a single query. Any id
    // that does not exist is a hard failure rather than a silently dropped line.
    const products = await Product.find({ originalId: { $in: productIds } })
      .select('originalId price')
      .lean();

    if (products.length !== productIds.length) {
      throw new ValidationError('One or more products in your order are unavailable');
    }

    // Prices come from the catalogue. Anything the client sent is discarded.
    const orderItems = products.map((product: any) => ({
      product: product.originalId,
      quantity: Math.min(99, requestedQuantities.get(product.originalId) as number),
      price: product.price,
    }));

    // The total is computed here, from server-side prices and server-side
    // shipping/tax constants.
    const total = calculateOrderTotal(orderItems);

    const order = await Order.create({
      user: auth.userId,
      items: orderItems,
      total,
      shippingAddress: mapAddress(shippingAddress),
      billingAddress: mapAddress(billingAddress),
      paymentMethod,
      status: 'pending',
      paymentStatus: 'pending',
    });

    // Best-effort clear of the server-side cart. A failure here must not fail
    // the order, but it is logged rather than swallowed.
    try {
      await Cart.findOneAndDelete({ user: auth.userId });
    } catch (cartError) {
      console.error('[orders/POST] could not clear server cart', cartError);
    }

    return NextResponse.json(
      {
        message: 'Order created successfully',
        order: {
          ...order.toObject(),
          items: await populateLineItems(order.items),
        },
      },
      { status: 201 }
    );
  } catch (error) {
    return errorResponse(error, 'orders/POST');
  }
}
