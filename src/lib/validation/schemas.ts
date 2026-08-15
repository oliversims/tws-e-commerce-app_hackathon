import { z } from 'zod';

/**
 * Every route handler parses its request body through one of these before the
 * value reaches Mongoose. Without it, a JSON body such as
 * `{"email": {"$ne": null}}` is passed straight into a query filter as a Mongo
 * operator instead of a value.
 */

export const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

export const registerSchema = z.object({
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(80),
  email: z.string().email('Please provide a valid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters long').max(200),
});

export const addToCartSchema = z.object({
  productId: z.string().min(1, 'productId is required'),
  // `price` is deliberately NOT accepted from the client -- the server reads it
  // from the product catalogue.
  quantity: z.coerce.number().int().min(1).max(99),
});

export const updateCartItemSchema = z.object({
  quantity: z.coerce.number().int().min(1).max(99),
});

export const addressSchema = z.object({
  title: z.string().trim().min(3, 'Name must be at least 3 characters'),
  phone: z.string().trim().min(10, 'Phone number must be at least 10 digits'),
  streetAddress: z.string().trim().min(3, 'Address must be at least 3 characters'),
  city: z.string().trim().min(2, 'City must be at least 2 characters'),
  state: z.string().trim().min(2, 'State must be at least 2 characters'),
  country: z.string().trim().min(2, 'Country must be at least 2 characters'),
  zip: z.string().trim().min(3, 'ZIP code must be at least 3 characters'),
});

export const PAYMENT_METHODS = ['cash on delivery'] as const;

/**
 * An order line states *what* the customer wants, never *what it costs*.
 * The server resolves each `productId` against the catalogue and uses that
 * price; `price` and `total` fields in the request body are ignored entirely.
 */
export const orderItemSchema = z.object({
  productId: z.string().min(1, 'productId is required'),
  quantity: z.coerce.number().int().min(1).max(99),
});

export const createOrderSchema = z.object({
  shippingAddress: addressSchema,
  billingAddress: addressSchema,
  paymentMethod: z.enum(PAYMENT_METHODS, {
    errorMap: () => ({ message: 'Unsupported payment method' }),
  }),
  items: z
    .array(orderItemSchema)
    .min(1, 'Your cart is empty')
    .max(100, 'Too many items in one order'),
});

export const ORDER_STATUSES = [
  'pending',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
] as const;

export const updateOrderStatusSchema = z.object({
  status: z.enum(ORDER_STATUSES, {
    errorMap: () => ({ message: 'Invalid order status' }),
  }),
});

export const productInputSchema = z.object({
  originalId: z.string().min(1),
  title: z.string().min(1),
  description: z.string().min(1),
  price: z.number().nonnegative(),
  oldPrice: z.number().nonnegative().optional(),
  categories: z.array(z.string()).optional(),
  image: z.array(z.string()).optional(),
  rating: z.number().min(0).max(5).optional(),
  sales: z.number().int().nonnegative().optional(),
  amount: z.number().int().nonnegative(),
  shop_category: z.string().min(1),
  unit_of_measure: z.string().optional(),
  colors: z.array(z.string()).optional(),
  sizes: z.array(z.string()).optional(),
});

export const productUpdateSchema = productInputSchema.partial();

export type AddressInput = z.infer<typeof addressSchema>;
