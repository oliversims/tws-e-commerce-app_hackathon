import mongoose from 'mongoose';

export interface IOrderItem {
  product: string;
  quantity: number;
  price: number;
}

export interface IOrderAddress {
  fullName: string;
  address: string;
  city: string;
  postalCode: string;
  country: string;
}

export interface IOrder {
  user: string;
  items: IOrderItem[];
  total: number;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  shippingAddress: IOrderAddress;
  billingAddress?: IOrderAddress;
  paymentMethod: string;
  paymentStatus: string;
}

// `product` stores Product.originalId as a plain string, not an ObjectId, so it
// deliberately carries no `ref`: Mongoose's populate() would resolve it against
// Product._id and silently yield null. Use populateLineItems() from
// src/lib/queries/populate.ts instead.
const orderItemSchema = new mongoose.Schema<IOrderItem>({
  product: {
    type: String,
    required: true
  },
  quantity: {
    type: Number,
    required: true,
    min: 1
  },
  price: {
    type: Number,
    required: true,
    min: 0
  }
}, { _id: false });

const addressSchema = {
  fullName: { type: String, required: true },
  address: { type: String, required: true },
  city: { type: String, required: true },
  postalCode: { type: String, required: true },
  country: { type: String, required: true }
};

const orderSchema = new mongoose.Schema<IOrder>({
  user: {
    type: String,
    required: true,
    index: true
  },
  items: [orderItemSchema],
  total: {
    type: Number,
    required: true,
    min: 0
  },
  shippingAddress: addressSchema,
  billingAddress: addressSchema,
  paymentMethod: {
    type: String,
    required: true
  },
  status: {
    type: String,
    required: true,
    enum: ['pending', 'processing', 'shipped', 'delivered', 'cancelled'],
    default: 'pending'
  },
  paymentStatus: {
    type: String,
    required: true,
    enum: ['pending', 'paid', 'failed'],
    default: 'pending'
  }
}, {
  timestamps: true
});

// Reuse the compiled model across hot reloads. Deleting and re-registering
// discards compiled schema state, hooks and indexes on every module evaluation.
export default (mongoose.models.Order as mongoose.Model<IOrder>) ||
  mongoose.model<IOrder>('Order', orderSchema);
