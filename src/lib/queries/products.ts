import dbConnect from '@/lib/db';
import Product from '@/lib/models/product';
import type { AllProduct } from '@/types/product';

export const VALID_SHOPS = new Set([
  'bags',
  'bakery',
  'books',
  'clothing',
  'furniture',
  'gadgets',
  'grocery',
  'makeup',
  'medicine',
]);

const VALID_SORT_FIELDS = new Set(['title', 'price', 'createdAt', 'rating', 'sales']);

export const DEFAULT_PAGE_SIZE = 10;
export const MAX_PAGE_SIZE = 50;

export type ProductQueryOptions = {
  q?: string | null;
  shop_category?: string | null;
  categories?: string | null;
  color?: string | null;
  minPrice?: string | null;
  maxPrice?: string | null;
  page?: string | number | null;
  limit?: string | number | null;
  sort?: string | null;
  order?: string | null;
};

export type ProductQueryResult = {
  products: AllProduct[];
  total: number;
  pagination: {
    total: number;
    page: number;
    limit: number;
    pages: number;
  };
};

function escapeRegex(value: string) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function nonEmpty(value: string | number | null | undefined): string | null {
  if (value === null || value === undefined) return null;
  const str = String(value).trim();
  return str ? str : null;
}

/** Clamps pagination so `?limit=1000000` cannot be used to exhaust the server. */
function parsePagination(page: unknown, limit: unknown) {
  const parsedPage = Math.max(1, Number.parseInt(String(page ?? '1'), 10) || 1);
  const parsedLimit = Math.min(
    MAX_PAGE_SIZE,
    Math.max(1, Number.parseInt(String(limit ?? DEFAULT_PAGE_SIZE), 10) || DEFAULT_PAGE_SIZE)
  );

  return { page: parsedPage, limit: parsedLimit, skip: (parsedPage - 1) * parsedLimit };
}

function buildFilter(options: ProductQueryOptions) {
  const filter: Record<string, unknown> = {};

  const searchTerm = nonEmpty(options.q);
  if (searchTerm) {
    const searchRegex = new RegExp(escapeRegex(searchTerm), 'i');
    filter.$or = [{ title: searchRegex }, { description: searchRegex }];
  }

  const shopCategory = nonEmpty(options.shop_category);
  if (shopCategory && VALID_SHOPS.has(shopCategory)) {
    filter.shop_category = shopCategory;
  }

  const categoriesParam = nonEmpty(options.categories);
  if (categoriesParam) {
    const categories = categoriesParam
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);
    if (categories.length > 0) {
      filter.categories = { $in: categories };
    }
  }

  const color = nonEmpty(options.color);
  if (color) {
    filter.colors = color.toLowerCase();
  }

  const minPriceValue = Number.parseFloat(String(nonEmpty(options.minPrice) ?? ''));
  const maxPriceValue = Number.parseFloat(String(nonEmpty(options.maxPrice) ?? ''));
  if (Number.isFinite(minPriceValue) || Number.isFinite(maxPriceValue)) {
    const price: Record<string, number> = {};
    if (Number.isFinite(minPriceValue)) price.$gte = minPriceValue;
    if (Number.isFinite(maxPriceValue)) price.$lte = maxPriceValue;
    filter.price = price;
  }

  return filter;
}

function buildSort(options: ProductQueryOptions): Record<string, 1 | -1> {
  const sortParam = nonEmpty(options.sort);
  if (!sortParam) return { createdAt: -1 };

  const [rawField, rawOrderFromSort] = sortParam.split(':');
  const field = rawField?.trim();
  const orderParam = nonEmpty(options.order) || rawOrderFromSort || 'asc';

  if (field && VALID_SORT_FIELDS.has(field)) {
    return { [field]: orderParam === 'desc' ? -1 : 1 };
  }

  return { createdAt: -1 };
}

/**
 * Shared by the /api/products route handler and by Server Components, so that
 * server-rendered pages query MongoDB directly instead of issuing an HTTP
 * request back to this same process.
 */
export async function queryProducts(
  options: ProductQueryOptions
): Promise<ProductQueryResult> {
  await dbConnect();

  const filter = buildFilter(options);
  const sort = buildSort(options);
  const { page, limit, skip } = parsePagination(options.page, options.limit);

  const [products, total] = await Promise.all([
    Product.find(filter).sort(sort).skip(skip).limit(limit).lean(),
    Product.countDocuments(filter),
  ]);

  return {
    products: JSON.parse(JSON.stringify(products)) as AllProduct[],
    total,
    pagination: {
      total,
      page,
      limit,
      pages: Math.ceil(total / limit),
    },
  };
}

/** Best sellers in the books shop, for the home page section. */
export async function findBooks(limit = 10) {
  await dbConnect();

  const books = await Product.find({ shop_category: 'books' })
    .sort({ createdAt: -1 })
    .limit(limit)
    .lean();

  return JSON.parse(JSON.stringify(books)) as AllProduct[];
}

/** Looks a product up by its `originalId`, falling back to `_id` for ObjectIds. */
export async function findProductBySlug(slug: string) {
  await dbConnect();

  let product = await Product.findOne({ originalId: slug }).lean();

  if (!product && /^[0-9a-fA-F]{24}$/.test(slug)) {
    product = await Product.findById(slug).lean();
  }

  return product ? (JSON.parse(JSON.stringify(product)) as AllProduct) : null;
}
