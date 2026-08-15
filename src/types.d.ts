/**
 * Ambient globals only.
 *
 * The product types used to be declared here *and* exported from
 * src/types/product.ts with identical bodies, so consumers were split between
 * the two copies and they were free to drift. src/types/product.ts is now the
 * single definition; these aliases exist so that the components which reference
 * the bare global names keep working.
 */

type SearchParamsType = { [key: string]: string | string[] | undefined };

type GroceryProduct = import("./types/product").GroceryProduct;
type GadgetProduct = import("./types/product").GadgetProduct;
type BakeryProduct = import("./types/product").BakeryProduct;
type ClothingProduct = import("./types/product").ClothingProduct;
type MakeupProduct = import("./types/product").MakeupProduct;
type BagsProduct = import("./types/product").BagsProduct;
type BooksProduct = import("./types/product").BooksProduct;
type MedicineProduct = import("./types/product").MedicineProduct;
type AllProduct = import("./types/product").AllProduct;
type SingleProductType = import("./types/product").SingleProductType;
type ProductResponse = import("./types/product").ProductResponse;
