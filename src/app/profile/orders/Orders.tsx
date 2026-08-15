"use client";

import OrderDetails from "@/components/profile/OrderDetails";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Variants, motion } from "framer-motion";
import { useEffect, useState } from "react";
import { Order } from "@/types/order";

const item: Variants = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      stiffness: 90,
    },
  },
  exit: {
    opacity: 0,
    x: "100%",
  },
};

const ORDERS_PER_PAGE = 5;

const Orders = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [page, setPage] = useState(1);
  const [reloadToken, setReloadToken] = useState(0);
  const [hasMore, setHasMore] = useState(true);

  // Fetching is driven solely by this effect. Previously "Refresh" both reset
  // `page` and called the fetcher directly, firing two overlapping requests
  // whose responses could land out of order.
  useEffect(() => {
    let cancelled = false;
    const isFirstPage = page === 1;

    const run = async () => {
      if (isFirstPage) {
        setLoading(true);
      } else {
        setIsLoadingMore(true);
      }
      setError(null);

      try {
        const response = await fetch(
          `/api/orders?page=${page}&limit=${ORDERS_PER_PAGE}`
        );
        const data = await response.json();

        if (!response.ok) {
          throw new Error(data.error || "Failed to fetch orders");
        }

        if (cancelled) return;

        const fetched: Order[] = data.orders ?? [];

        if (isFirstPage) {
          setOrders(fetched);
          setSelectedOrder(fetched.length > 0 ? fetched[0] : null);
        } else {
          setOrders((prev) => [...prev, ...fetched]);
        }

        setHasMore(fetched.length === ORDERS_PER_PAGE);
      } catch (err: any) {
        if (!cancelled) setError(err.message);
      } finally {
        if (!cancelled) {
          setLoading(false);
          setIsLoadingMore(false);
        }
      }
    };

    run();

    return () => {
      cancelled = true;
    };
  }, [page, reloadToken]);

  const handleRefresh = () => {
    setHasMore(true);
    if (page === 1) {
      // Already on page 1 -- bump the token so the effect re-runs.
      setReloadToken((token) => token + 1);
    } else {
      setPage(1);
    }
  };

  // Only the initial load blanks the view; "Load More" keeps the list on screen.
  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">Loading orders...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-red-500 text-center">{error}</div>
        <button 
          onClick={handleRefresh}
          className="mt-4 px-4 py-2 bg-primary text-white rounded-md hover:bg-primary/90"
        >
          Try Again
        </button>
      </div>
    );
  }

  if (orders.length === 0 && !loading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">No orders found</div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">My Orders</h1>
        <button 
          onClick={handleRefresh}
          className="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary/90"
        >
          Refresh
        </button>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-4">
          {orders.map((order) => (
            <motion.div
              key={order._id}
              variants={item}
              initial="hidden"
              animate="visible"
              exit="exit"
              onClick={() => setSelectedOrder(order)}
              className={`cursor-pointer ${selectedOrder?._id === order._id ? "ring-2 ring-primary" : ""}`}
            >
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">
                    Order #{order._id.slice(-6)}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="flex flex-col gap-2">
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Status</span>
                      <span className="capitalize">{order.status}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Order Date</span>
                      <span>{new Date(order.createdAt).toLocaleDateString()}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Total</span>
                      <span>${order.total.toFixed(2)}</span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ))}
          
          {hasMore && !isLoadingMore && (
            <button
              onClick={() => setPage(prev => prev + 1)}
              className="w-full py-2 bg-secondary text-primary rounded-md hover:bg-secondary/90"
            >
              Load More Orders
            </button>
          )}

          {isLoadingMore && (
            <div className="text-center py-4">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
            </div>
          )}
        </div>

        <div className="bg-secondary p-6 rounded-lg">
          {selectedOrder ? (
            <OrderDetails order={selectedOrder} />
          ) : (
            <div className="text-center text-muted-foreground">
              Select an order to view details
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Orders;
