import { findBooks } from "@/lib/queries/products";
import Link from "next/link";
import BooksSlider from "./sliders/BooksSlider";

const BooksCategory = async () => {
  try {
    // Queries MongoDB directly rather than issuing an HTTP request from the
    // server back to our own /api/products/books route.
    const books = (await findBooks()) as unknown as BooksProduct[];

    return (
      <section className="books-category pt-20">
        <div className="container">
          <div className="flex justify-between items-center gap-4 flex-wrap mb-6">
            <h1 className="text-2xl md:text-4xl font-semibold">
              Best Sellers in Books
            </h1>
            <Link
              href={"/shops/books"}
              className="hover:underline text-primary"
            >
              View Shop
            </Link>
          </div>

          <BooksSlider books={books} />
        </div>
      </section>
    );
  } catch (error) {
    console.error("Error:", error);
    return <div>Error loading books</div>;
  }
};

export default BooksCategory;
