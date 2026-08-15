import Product from '@/lib/models/product';

type LineItem = {
  product: string;
  quantity: number;
  price: number;
};

type PopulatedProduct = {
  _id: string;
  originalId: string;
  title: string;
  price: number;
  image: string[];
};

export type PopulatedLineItem = Omit<LineItem, 'product'> & {
  product: PopulatedProduct | null;
};

function toPlain(item: unknown): LineItem {
  const candidate = item as { toObject?: () => LineItem };
  return typeof candidate?.toObject === 'function' ? candidate.toObject() : (item as LineItem);
}

/**
 * Resolves every line item's product in a single query.
 *
 * Cart and order items store `Product.originalId` as a plain string, not an
 * ObjectId, so Mongoose's `populate()` cannot resolve them -- it would look the
 * value up against `Product._id` and silently yield null. This is the one place
 * that mapping lives.
 */
export async function populateLineItems(items: unknown[]): Promise<PopulatedLineItem[]> {
  const plainItems = (items ?? []).map(toPlain);

  if (plainItems.length === 0) return [];

  const originalIds = Array.from(new Set(plainItems.map((item) => item.product)));

  const products = await Product.find({ originalId: { $in: originalIds } })
    .select('_id originalId title price image')
    .lean();

  const byOriginalId = new Map(
    products.map((product: any) => [
      product.originalId,
      {
        _id: String(product._id),
        originalId: product.originalId,
        title: product.title,
        price: product.price,
        image: product.image,
      } as PopulatedProduct,
    ])
  );

  return plainItems.map((item) => ({
    ...item,
    product: byOriginalId.get(item.product) ?? null,
  }));
}
