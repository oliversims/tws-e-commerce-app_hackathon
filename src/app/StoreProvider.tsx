"use client";
import { useEffect, useRef } from "react";
import { Provider } from "react-redux";
import { makeStore, AppStore } from "../lib/store";
import { hydrate, type CartItem } from "../lib/features/cart/cartSlice";
import { hydrateUser, type User } from "../lib/features/auth/authSlice";
import {
  CART_STORAGE_KEY,
  USER_STORAGE_KEY,
  WISHLIST_STORAGE_KEY,
  readStored,
} from "../lib/features/cart/persistence";
import type { AllProduct } from "@/types/product";

export default function StoreProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const storeRef = useRef<AppStore>();
  if (!storeRef.current) {
    storeRef.current = makeStore();
  }

  // Stored state is applied after the first render so that server and client
  // markup match; hydrating inside the reducer's initialState would not.
  useEffect(() => {
    const store = storeRef.current;
    if (!store) return;

    store.dispatch(
      hydrate({
        cartItems: readStored<CartItem[]>(CART_STORAGE_KEY, []),
        wishlists: readStored<AllProduct[]>(WISHLIST_STORAGE_KEY, []),
      })
    );

    store.dispatch(hydrateUser(readStored<User | null>(USER_STORAGE_KEY, null)));
  }, []);

  return <Provider store={storeRef.current}>{children}</Provider>;
}
