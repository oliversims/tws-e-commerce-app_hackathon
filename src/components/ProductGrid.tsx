import NoProductFound from "./NoProductFound";
import Paginations from "./Paginations";
import ProductCard from "./cards/ProductCard";
import layoutSettings from "@/lib/layoutSettings";
import { queryProducts } from "@/lib/queries/products";

type CategoryPageProps = {
  searchParams: SearchParamsType;
  params: {
    category: string;
    shop: string;
  };
};

const first = (value: string | string[] | undefined) =>
  Array.isArray(value) ? value[0] : value;

const ProductGrid = async ({ params, searchParams }: CategoryPageProps) => {
  try {
    const { shop, category } = params;

    // Queries MongoDB directly. This used to issue an HTTP request from the
    // server back to this same process just to reach the route handler.
    const { products, pagination } = await queryProducts({
      page: first(searchParams?.page) || "1",
      q: first(searchParams?.q),
      sort: first(searchParams?.sort),
      order: first(searchParams?.order),
      color: first(searchParams?.color),
      minPrice: first(searchParams?.minPrice),
      maxPrice: first(searchParams?.maxPrice),
      shop_category: shop,
      categories: category || undefined,
    });

    const settings = layoutSettings?.[shop] || { productCardVariants: 'style-1' };

    if (products.length === 0) {
      return <NoProductFound />;
    }

    return (
      <>
        <div className="grid-layout pt-6">
          {products.map((product) => (
            <ProductCard
              product={product}
              variants={settings.productCardVariants}
              key={product._id}
            />
          ))}
        </div>
        <Paginations
          totalCount={pagination.total}
          currentPage={pagination.page}
          totalPages={pagination.pages}
        />
      </>
    );
  } catch (error) {
    console.error("Error fetching products:", error);
    return <NoProductFound />;
  }
};

export default ProductGrid;
