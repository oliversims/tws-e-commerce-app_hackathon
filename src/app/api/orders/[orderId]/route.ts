import { NextRequest, NextResponse } from 'next/server';
import mongoose from 'mongoose';
import dbConnect from '@/lib/db';
import Order from '@/lib/models/order';
import { requireAuth, requireAdmin } from '@/lib/auth/utils';
import { errorResponse, NotFoundError, ValidationError } from '@/lib/api/errors';
import { updateOrderStatusSchema } from '@/lib/validation/schemas';
import { populateLineItems } from '@/lib/queries/populate';

/**
 * A non-ObjectId path segment makes Mongoose throw a CastError, which would
 * otherwise surface as a 500 for what is plainly a client error.
 */
function assertValidOrderId(orderId: string) {
  if (!mongoose.Types.ObjectId.isValid(orderId)) {
    throw new ValidationError('Invalid order id');
  }
}

async function orderResponse(order: any) {
  return NextResponse.json({
    ...order.toObject(),
    items: await populateLineItems(order.items),
  });
}

// Get single order
export async function GET(
  request: NextRequest,
  { params }: { params: { orderId: string } }
) {
  try {
    const auth = await requireAuth(request);
    assertValidOrderId(params.orderId);
    await dbConnect();

    const order = await Order.findOne({
      _id: params.orderId,
      user: auth.userId
    });

    if (!order) {
      throw new NotFoundError('Order not found');
    }

    return orderResponse(order);
  } catch (error) {
    return errorResponse(error, 'orders/[orderId]/GET');
  }
}

// Update order status (admin only)
export async function PUT(
  request: NextRequest,
  { params }: { params: { orderId: string } }
) {
  try {
    await requireAdmin(request);
    assertValidOrderId(params.orderId);
    await dbConnect();

    const { status } = updateOrderStatusSchema.parse(await request.json());

    const order = await Order.findByIdAndUpdate(
      params.orderId,
      { status },
      { new: true, runValidators: true }
    );

    if (!order) {
      throw new NotFoundError('Order not found');
    }

    return orderResponse(order);
  } catch (error) {
    return errorResponse(error, 'orders/[orderId]/PUT');
  }
}

// Cancel order
export async function DELETE(
  request: NextRequest,
  { params }: { params: { orderId: string } }
) {
  try {
    const auth = await requireAuth(request);
    assertValidOrderId(params.orderId);
    await dbConnect();

    const order = await Order.findOne({
      _id: params.orderId,
      user: auth.userId
    });

    if (!order) {
      throw new NotFoundError('Order not found');
    }

    if (order.status !== 'pending') {
      throw new ValidationError('Cannot cancel order in current status');
    }

    order.status = 'cancelled';
    await order.save();

    return orderResponse(order);
  } catch (error) {
    return errorResponse(error, 'orders/[orderId]/DELETE');
  }
}
