import layoutSettings from "@/lib/layoutSettings";
import ProductCard from "./cards/ProductCard";
import { queryProducts } from "@/lib/queries/products";

type RelatedProductsProps = {
  category: string;
  shop_category: string;
};

const RelatedProducts = async ({
  category,
  shop_category,
}: RelatedProductsProps) => {
  try {
    const { products } = await queryProducts({
      shop_category,
      categories: category,
      limit: 5,
    });

    const settings = layoutSettings?.[shop_category];

    return (
      <>
        {products.map((product) => (
          <ProductCard
            product={product}
            variants={settings?.productCardVariants}
            key={product._id}
          />
        ))}
      </>
    );
  } catch (error) {
    console.error("Error fetching related products:", error);
    return null;
  }
};

export default RelatedProducts;
