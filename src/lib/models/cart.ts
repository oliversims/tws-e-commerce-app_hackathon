import mongoose from 'mongoose';

export interface ICartItem {
  product: string;
  quantity: number;
  price: number;
}

export interface ICart {
  user: string;
  items: ICartItem[];
  total: number;
}

// As with orders, `product` holds Product.originalId as a plain string and
// carries no `ref` -- see src/lib/queries/populate.ts.
const cartItemSchema = new mongoose.Schema<ICartItem>({
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

const cartSchema = new mongoose.Schema<ICart>({
  user: {
    type: String,
    required: true,
    unique: true
  },
  items: [cartItemSchema],
  total: {
    type: Number,
    required: true,
    default: 0
  }
}, {
  timestamps: true
});

// Single source of truth for the cart total.
cartSchema.pre('save', function (next) {
  this.total =
    Math.round(
      this.items.reduce((sum, item) => sum + item.price * item.quantity, 0) * 100
    ) / 100;
  next();
});

export default (mongoose.models.Cart as mongoose.Model<ICart>) ||
  mongoose.model<ICart>('Cart', cartSchema);
