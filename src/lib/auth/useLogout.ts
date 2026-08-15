"use client";

import { useCallback } from "react";
import { useRouter } from "next/navigation";
import { useDispatch } from "react-redux";
import { signedOut } from "@/lib/features/auth/authSlice";
import { clearPersonalData } from "@/lib/features/cart/cartSlice";
import {
  CART_STORAGE_KEY,
  USER_STORAGE_KEY,
  WISHLIST_STORAGE_KEY,
  clearStored,
} from "@/lib/features/cart/persistence";

/**
 * One logout path for every entry point. Previously each caller cleared a
 * different subset of state: the session cookie was dropped but `currentUser`
 * survived in localStorage, so the next visitor on a shared browser saw the
 * previous user's name and email rehydrated into Redux.
 */
export function useLogout(redirectTo = "/") {
  const router = useRouter();
  const dispatch = useDispatch();

  return useCallback(async () => {
    try {
      // Clears the httpOnly cookie server-side.
      await fetch("/api/auth/logout", {
        method: "POST",
        credentials: "include",
      });
    } catch {
      // A network failure must not leave the UI in a half-signed-in state --
      // fall through and clear the client regardless.
    }

    // Cart AND wishlist go with the session -- both are personal to the
    // shopper, and leaving either behind exposes them to the next person on a
    // shared browser.
    dispatch(signedOut());
    dispatch(clearPersonalData());
    clearStored(USER_STORAGE_KEY, CART_STORAGE_KEY, WISHLIST_STORAGE_KEY);

    router.push(redirectTo);
    router.refresh();
  }, [dispatch, router, redirectTo]);
}
