import { NextRequest, NextResponse } from 'next/server';
import dbConnect from '@/lib/db';
import Product from '@/lib/models/product';
import { errorResponse } from '@/lib/api/errors';

// Map frontend categories to database categories
const categoryMap: { [key: string]: string } = {
  electronics: 'gadgets',
  gadgets: 'gadgets',
  medicine: 'medicine',
  grocery: 'grocery',
  clothing: 'clothing',
  furniture: 'furniture',
  books: 'books',
  beauty: 'makeup',
  makeup: 'makeup',
  bags: 'bags',
  snacks: 'grocery',
  bakery: 'bakery'
};

export async function GET(request: NextRequest) {
  try {
    await dbConnect();

    const { searchParams } = new URL(request.url);
    const requestedCategory = searchParams.get('category') || 'electronics';
    const category = categoryMap[requestedCategory] || requestedCategory;

    const match: Record<string, unknown> = {};
    if (category !== 'all') {
      // Only ever a plain string, so it cannot carry a Mongo operator.
      match.shop_category = String(category);
    }

    // Best sellers: rating weighted by sales.
    const products = await Product.aggregate([
      { $match: match },
      {
        $addFields: {
          score: {
            $multiply: [
              { $ifNull: ['$rating', 0] },
              { $add: [{ $ifNull: ['$sales', 0] }, 1] }
            ]
          }
        }
      },
      { $sort: { score: -1 } },
      { $limit: 8 }
    ]);

    return NextResponse.json(products);
  } catch (error) {
    return errorResponse(error, 'products/featured/GET');
  }
}
