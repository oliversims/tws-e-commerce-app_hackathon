import {
  Table,
  TableBody,
  TableCell,
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Order } from "@/types/order";
import Image from "next/image";
import Link from "next/link";

type OrderTableProps = {
  items: Order['items'];
};

function getImageSrc(image: string | string[] | undefined): string | null {
  if (Array.isArray(image) && image[0]) return image[0];
  if (typeof image === "string" && image) return image;
  return null;
}

export function OrderTable({ items }: OrderTableProps) {
  return (
    <Table className="mt-5 table-auto">
      <TableHeader className="bg-accent w-full">
        <TableRow className="w-full">
          <TableHead>Item</TableHead>
          <TableHead className="text-center">Quantity</TableHead>
          <TableHead className="text-right">Price</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {items.map((item, index) => {
          const product = item.product;
          const imageSrc = getImageSrc(product?.image);
          const key = product?._id || item._id || String(index);

          return (
            <TableRow key={key}>
              <TableCell className="font-medium">
                <div className="flex gap-3">
                  {imageSrc ? (
                    <Image
                      src={imageSrc}
                      width={40}
                      height={40}
                      alt={product?.title || "Product"}
                      className="rounded-lg"
                    />
                  ) : (
                    <div className="h-10 w-10 rounded-lg bg-muted" />
                  )}
                  <div>
                    {product ? (
                      <Link
                        href={`/products/${product._id}`}
                        className="hover:text-primary hover:underline"
                      >
                        {product.title}
                      </Link>
                    ) : (
                      <span>Product Unavailable</span>
                    )}
                    <p className="text-xs text-primary mt-1">
                      <span>${item.price.toFixed(2)}</span>
                    </p>
                  </div>
                </div>
              </TableCell>
              <TableCell className="text-center">{item.quantity}</TableCell>
              <TableCell className="text-right">${(item.price * item.quantity).toFixed(2)}</TableCell>
            </TableRow>
          );
        })}
      </TableBody>
      <TableFooter>
        <TableRow>
          <TableCell>Total</TableCell>
          <TableCell></TableCell>
          <TableCell className="text-right">${items.reduce((total, item) => total + (item.price * item.quantity), 0).toFixed(2)}</TableCell>
        </TableRow>
      </TableFooter>
    </Table>
  );
}
