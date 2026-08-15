"use client";

import { clearCart, removeFromCart } from "@/lib/features/cart/cartSlice";
import { useAppSelector } from "@/lib/hooks";
import { totalPrice } from "@/lib/utils";
import { SHIPPING_FEE, TAX_FEE, roundCurrency } from "@/lib/commerce/pricing";
import { AnimatePresence, motion } from "framer-motion";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { HiMiniXMark } from "react-icons/hi2";
import { useDispatch } from "react-redux";
import Skeleton from "../loader/Skeleton";
import { Button } from "../ui/button";
import { Card, CardHeader, CardTitle } from "../ui/card";
import { useToast } from "../ui/use-toast";
import { useRouter } from "next/navigation";

const paymentMethods = [
  {
    title: "cash on delivery",
  },
];

interface OrderSummeryProps {
  shippingData: any;
  billingData: any;
}

const REQUIRED_ADDRESS_FIELDS = [
  "title",
  "phone",
  "streetAddress",
  "city",
  "state",
  "country",
  "zip",
] as const;

const OrderSummery = ({ shippingData, billingData }: OrderSummeryProps) => {
  const [selectedMethod, setSelectedMethod] = useState("cash on delivery");
  const [isClient, setIsClient] = useState(false);
  const [isPlacingOrder, setIsPlacingOrder] = useState(false);
  const [imageErrors, setImageErrors] = useState<Record<string, boolean>>({});
  const { cartItems } = useAppSelector((state) => state.cartSlice);
  const dispatch = useDispatch();
  const { toast } = useToast();
  const router = useRouter();

  const subtotal = totalPrice(cartItems);
  const orderTotal = roundCurrency(subtotal + SHIPPING_FEE + TAX_FEE);

  const getImageSrc = (item: any) => {
    if (!item.image) return '/placeholder.jpg';
    if (Array.isArray(item.image) && item.image.length > 0) {
      return item.image[0].startsWith('/') ? item.image[0] : `/${item.image[0]}`;
    }
    if (typeof item.image === 'string') {
      return item.image.startsWith('/') ? item.image : `/${item.image}`;
    }
    return '/placeholder.jpg';
  };

  const handleSelectMethod = (title: string) => {
    setSelectedMethod(title);
  };

  const validateAddress = (address: any, type: string) => {
    const missingFields = REQUIRED_ADDRESS_FIELDS.filter(
      (field) => !String(address?.[field] ?? "").trim()
    );

    if (!address || missingFields.length > 0) {
      throw new Error(
        `Please fill in the following ${type} fields: ${
          missingFields.join(", ") || "all fields"
        }`
      );
    }
  };

  const placeOrder = async () => {
    try {
      if (!selectedMethod) {
        throw new Error('Please select a payment method');
      }

      if (cartItems.length <= 0) {
        throw new Error('Your cart is empty');
      }

      const billing = billingData;
      const shipping = shippingData || billingData;

      validateAddress(billing, 'billing');
      validateAddress(shipping, 'shipping');

      // Only the selection is sent. Prices and the order total are resolved
      // server-side from the product catalogue -- anything sent from here would
      // be ignored.
      const orderData = {
        shippingAddress: shipping,
        billingAddress: billing,
        paymentMethod: selectedMethod,
        items: cartItems.map((item) => ({
          productId: String(item._id),
          quantity: item.amount || 1,
        })),
      };

      setIsPlacingOrder(true);

      const response = await fetch('/api/orders', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify(orderData),
      });

      const data = await response.json();

      if (response.status === 401) {
        toast({
          title: "Please log in",
          description: "You need to be signed in to place an order.",
          variant: "destructive",
        });
        router.push('/login?redirect=/checkout');
        return;
      }

      if (!response.ok) {
        throw new Error(data.error || 'Failed to place order');
      }

      dispatch(clearCart());
      router.push('/checkout/success');
    } catch (error: any) {
      toast({
        title: "Could not place order",
        description: error.message || 'Failed to place order',
        variant: "destructive",
      });
    } finally {
      setIsPlacingOrder(false);
    }
  };

  useEffect(() => {
    setIsClient(true);
  }, []);

  return isClient ? (
    <AnimatePresence>
      <div className="order-summery">
        <h2 className="text-2xl font-bold mb-5">Order Summary</h2>
        <div className="pb-4">
          {cartItems.length <= 0 && (
            <div className="text-center py-6">No products selected!</div>
          )}
          {cartItems.map((item) => (
            <motion.div
              layout
              key={item._id}
              className="group flex justify-between items-end py-3 hover:bg-accent px-3 rounded-lg relative"
            >
              <Button
                type="button"
                variant="outline"
                className="absolute top-1 right-2 h-7 w-7 p-0 text-base rounded-full hover:text-primary hover:border-primary hidden group-hover:flex"
                onClick={() => dispatch(removeFromCart(item._id))}
              >
                <HiMiniXMark />
              </Button>
              <div className="flex gap-3">
                <div className="relative w-[50px] h-[50px]">
                  {!imageErrors[item._id] ? (
                    <Image
                      src={getImageSrc(item)}
                      alt={item.title}
                      fill
                      sizes="50px"
                      className="object-cover rounded-md"
                      onError={() => {
                        setImageErrors(prev => ({ ...prev, [item._id]: true }));
                      }}
                      priority
                    />
                  ) : (
                    <div className="w-full h-full bg-gray-200 rounded-md flex items-center justify-center">
                      <span className="text-xs text-gray-500">No image</span>
                    </div>
                  )}
                </div>
                <div>
                  <Link
                    href={`/products/${item._id}`}
                    className="text-sm font-medium hover:text-primary"
                  >
                    {item.title}
                  </Link>
                  <p className="text-sm text-muted-foreground">
                    ${item.price} x {item.amount || 1}
                  </p>
                </div>
              </div>
              <div className="text-right">
                <p className="font-medium">
                  ${((item.price || 0) * (item.amount || 1)).toFixed(2)}
                </p>
              </div>
            </motion.div>
          ))}
        </div>

        {cartItems.length > 0 && (
          <div className="pb-5 pt-3">
            <h3 className="text-xl font-medium text-center">
              Select Payment Method
            </h3>
            <div className="flex gap-4 items-center mt-4">
              {paymentMethods.map((method) => (
                <Card
                  className={`${
                    method.title === selectedMethod
                      ? "text-primary border-primary"
                      : ""
                  } cursor-pointer`}
                  key={method.title}
                  onClick={() => handleSelectMethod(method.title)}
                >
                  <CardHeader>
                    <CardTitle className="text-base">
                      Cash on Delivery
                    </CardTitle>
                  </CardHeader>
                </Card>
              ))}
            </div>
          </div>
        )}
        <div className="flex flex-col gap-5 border-t pt-4">
          <div className="flex justify-between font-semibold">
            <p>Subtotal</p>
            <p>${subtotal.toFixed(2)}</p>
          </div>
          <div className="flex justify-between">
            <p>Shipping</p>
            <p className="text-muted-foreground">${SHIPPING_FEE}</p>
          </div>
          <div className="flex justify-between">
            <p>Tax</p>
            <p className="text-muted-foreground">${TAX_FEE}</p>
          </div>
          <div className="flex justify-between font-semibold">
            <p>Total</p>
            <p>${orderTotal.toFixed(2)}</p>
          </div>
        </div>
        <Button
          type="button"
          disabled={cartItems.length <= 0 || selectedMethod === "" || isPlacingOrder}
          className="w-full mt-5 capitalize"
          onClick={placeOrder}
        >
          {isPlacingOrder ? "Placing order..." : "Place Order"}
        </Button>
      </div>
    </AnimatePresence>
  ) : (
    <div className="flex flex-col gap-4">
      <Skeleton className="h-7 rounded-2xl w-full max-[200px]" />
      {[...Array(5)].map((_, i) => (
        <Skeleton key={i} className="h-14 rounded-lg w-full" />
      ))}

      <Skeleton className="h-7 rounded-lg w-full max-[150px] mx-auto py-4" />

      {[...Array(4)].map((_, i) => (
        <div className="flex justify-between items-center" key={i}>
          <Skeleton className="h-5 rounded-lg w-16" />
          <Skeleton className="h-5 rounded-lg w-10" />
        </div>
      ))}
    </div>
  );
};

export default OrderSummery;
