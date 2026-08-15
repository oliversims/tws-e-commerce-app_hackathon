import { motion } from "framer-motion";
import { useState } from "react";
import { Order } from "@/types/order";
import Image from "next/image";

const itemAnimation = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
  },
};

type OrderDetailsProps = {
  order: Order;
};

function getProductImageSrc(product: Order["items"][number]["product"]): string | null {
  if (!product) return null;

  if (Array.isArray(product.images) && product.images[0]) {
    return product.images[0];
  }

  if (Array.isArray(product.image) && product.image[0]) {
    return product.image[0];
  }

  if (typeof product.image === "string" && product.image) {
    return product.image;
  }

  return null;
}

const OrderDetails = ({ order }: OrderDetailsProps) => {
  const [imageError, setImageError] = useState<Record<string, boolean>>({});

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case "completed":
        return "bg-green-200 text-green-600";
      case "processing":
        return "bg-yellow-200 text-yellow-600";
      case "pending":
        return "bg-orange-200 text-orange-600";
      default:
        return "bg-gray-200 text-gray-600";
    }
  };

  return (
    <motion.div variants={itemAnimation} key={order._id} className="order-details mt-10">
      <h1 className="font-medium text-lg md:text-2xl">
        Order #{order._id}
      </h1>
      
      <div className="bg-accent my-4 rounded-lg p-4">
        <div className="flex w-full justify-between md:items-center gap-4 flex-wrap">
          <div className="flex gap-5 items-center">
            <div className={`${getStatusColor(order.status)} rounded-lg py-1 px-2 capitalize text-sm`}>
              {order.status}
            </div>
          </div>
          <div className="flex gap-5 items-center">
            <strong>Payment Method : </strong>
            <div className="bg-green-200 text-green-600 rounded-lg py-1 px-2 capitalize text-sm">
              {order.paymentMethod}
            </div>
          </div>
        </div>
      </div>

      <div className="flex text-sm mt-5 w-full justify-between border-b-2 flex-col gap-3 md:flex-row">
        <div className="basis-1/2 p-4">
          <h4 className="font-medium">Shipping Address</h4>
          <p className="text-muted-foreground mt-2">
            {order.shippingAddress.fullName}<br />
            {order.shippingAddress.address}<br />
            {order.shippingAddress.city}, {order.shippingAddress.postalCode}<br />
            {order.shippingAddress.country}
          </p>
        </div>

        <div className="basis-1/2 p-4 border-l">
          <h4 className="font-medium">Order Summary</h4>
          <div className="mt-2 space-y-2">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Items ({order.items.length})</span>
              <span>${order.items.reduce((sum, item) => sum + item.price * item.quantity, 0).toFixed(2)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Shipping</span>
              <span>$0.00</span>
            </div>
            <div className="flex justify-between border-t pt-2">
              <span className="font-medium">Total</span>
              <span className="font-medium">${order.total.toFixed(2)}</span>
            </div>
          </div>
        </div>
      </div>

      <div className="mt-6 p-4">
        <h4 className="font-medium mb-4">Order Items</h4>
        <div className="space-y-4">
          {order.items.map((item, index) => {
            const productKey = item.product?._id || item._id || String(index);
            const imageSrc = getProductImageSrc(item.product);
            const showImage = Boolean(imageSrc) && !imageError[productKey];

            return (
              <motion.div
                key={productKey}
                variants={itemAnimation}
                className="flex items-center gap-4 p-3 bg-accent rounded-lg"
              >
                <div className="h-16 w-16 flex-shrink-0 relative bg-muted rounded-lg overflow-hidden">
                  {showImage ? (
                    <Image
                      src={imageSrc as string}
                      alt={item.product?.title || "Product"}
                      width={80}
                      height={80}
                      className="h-16 w-16 rounded-lg object-cover"
                      onError={() =>
                        setImageError((prev) => ({ ...prev, [productKey]: true }))
                      }
                    />
                  ) : (
                    <div className="h-full w-full flex items-center justify-center text-[10px] text-muted-foreground">
                      No image
                    </div>
                  )}
                </div>
                <div className="flex-grow">
                  <h5 className="font-medium">
                    {item.product?.title || item.product?.name || "Product Unavailable"}
                  </h5>
                  <p className="text-sm text-muted-foreground">
                    ${(item.price || 0).toFixed(2)} x {item.quantity}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-medium">
                    ${((item.price || 0) * (item.quantity || 0)).toFixed(2)}
                  </p>
                </div>
              </motion.div>
            );
          })}
        </div>
      </div>
    </motion.div>
  );
};

export default OrderDetails;
