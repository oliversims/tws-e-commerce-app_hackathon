import type { Middleware } from '@reduxjs/toolkit';
import type { CartItem } from './cartSlice';

export const CART_STORAGE_KEY = 'cartItems';
export const WISHLIST_STORAGE_KEY = 'wishlists';
export const USER_STORAGE_KEY = 'currentUser';

/**
 * Reads and parses a localStorage key, tolerating anything that is not valid
 * JSON. Previously an unguarded JSON.parse ran during reducer initialisation,
 * so a single malformed value took the whole app down before any error boundary
 * existed.
 */
export function readStored<T>(key: string, fallback: T): T {
  if (typeof window === 'undefined') return fallback;

  try {
    const raw = window.localStorage.getItem(key);
    if (!raw) return fallback;

    const parsed = JSON.parse(raw);
    return (parsed ?? fallback) as T;
  } catch {
    // Corrupt entry -- discard it rather than crash on every subsequent load.
    try {
      window.localStorage.removeItem(key);
    } catch {
      /* storage unavailable (private mode, quota) -- nothing to do */
    }
    return fallback;
  }
}

export function writeStored(key: string, value: unknown) {
  if (typeof window === 'undefined') return;

  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* storage unavailable or full -- persistence is best effort */
  }
}

export function clearStored(...keys: string[]) {
  if (typeof window === 'undefined') return;

  for (const key of keys) {
    try {
      window.localStorage.removeItem(key);
    } catch {
      /* ignore */
    }
  }
}

type PersistedState = {
  cartSlice?: { cartItems: CartItem[]; wishlists: unknown[] };
  authSlice?: { currentUser: unknown };
};

/**
 * Persistence lives here rather than inside the reducers. Reducers must stay
 * pure: writing to localStorage from within them breaks time-travel debugging,
 * makes them untestable outside a browser, and double-fires under React 18
 * strict mode.
 */
export const persistenceMiddleware: Middleware = (store) => (next) => (action) => {
  const result = next(action);

  if (typeof window === 'undefined') return result;

  const type = (action as { type?: string })?.type ?? '';
  if (!type.startsWith('cart/') && !type.startsWith('auth/')) {
    return result;
  }

  const state = store.getState() as PersistedState;

  if (type.startsWith('cart/')) {
    writeStored(CART_STORAGE_KEY, state.cartSlice?.cartItems ?? []);
    writeStored(WISHLIST_STORAGE_KEY, state.cartSlice?.wishlists ?? []);
  }

  if (type.startsWith('auth/')) {
    const currentUser = state.authSlice?.currentUser;
    if (currentUser) {
      writeStored(USER_STORAGE_KEY, currentUser);
    } else {
      clearStored(USER_STORAGE_KEY);
    }
  }

  return result;
};
