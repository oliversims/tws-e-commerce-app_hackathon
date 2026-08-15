import { createSlice, PayloadAction } from "@reduxjs/toolkit";
import type { AllProduct } from "@/types/product";

// Define a type for the slice state
export type CartItem = {
  _id: number | string;
  title: string;
  price: number;
  amount?: number;
  image: string[];
  unit_of_measure: string;
  shop_category: string;
  selectedSize?: string | undefined;
  selectedColor?: string | undefined;
};

export interface CartState {
  cartItems: CartItem[];
  wishlists: AllProduct[];
  isCartOpen: boolean;
  countValue: number;
  selectedSize: string | undefined;
  selectedColor: string | undefined;
}

/**
 * Starts empty on both server and client so the two renders agree. Stored
 * values are applied afterwards by `hydrate`, dispatched from StoreProvider on
 * mount -- reading localStorage here would produce a hydration mismatch.
 */
const initialState: CartState = {
  cartItems: [],
  isCartOpen: false,
  wishlists: [],
  countValue: 1,
  selectedSize: undefined,
  selectedColor: undefined,
};

export const cartSlice = createSlice({
  name: "cart",
  initialState,
  reducers: {
    hydrate: (
      state,
      action: PayloadAction<{ cartItems: CartItem[]; wishlists: AllProduct[] }>
    ) => {
      state.cartItems = action.payload.cartItems;
      state.wishlists = action.payload.wishlists;
    },

    handleCartOpen: (state) => {
      state.isCartOpen = !state.isCartOpen;
    },

    // add to cart
    addToCart: (state, action: PayloadAction<CartItem>) => {
      const item = state.cartItems.find(
        (item) => item._id === action.payload._id
      );

      if (item) {
        item.selectedColor = state.selectedColor;
        item.selectedSize = state.selectedSize;
        return;
      }

      state.cartItems.push(action.payload);
      state.selectedColor = undefined;
      state.selectedSize = undefined;
    },

    // delete
    removeFromCart: (state, action: PayloadAction<number | string>) => {
      state.cartItems = state.cartItems.filter(
        (item) => item._id !== action.payload
      );
      state.countValue = 1;
      state.selectedColor = undefined;
      state.selectedSize = undefined;
    },

    clearCart: (state) => {
      state.cartItems = [];
      state.countValue = 1;
      state.selectedColor = undefined;
      state.selectedSize = undefined;
    },

    incrementAmount: (state, action: PayloadAction<number | string>) => {
      const item = state.cartItems.find((item) => item._id === action.payload);
      if (item) {
        item.amount = item.amount ? item.amount + 1 : 1;
      }
    },

    // decrement amount
    decrementAmount: (state, action: PayloadAction<number | string>) => {
      const item = state.cartItems.find((item) => item._id === action.payload);
      if (!item) return;

      if (item.amount === 1) {
        state.cartItems = state.cartItems.filter(
          (cartItem) => cartItem._id !== action.payload
        );
        return;
      }

      item.amount = item.amount ? item.amount - 1 : 1;
    },

    // add to wishlist
    toggleToWishlists: (state, action: PayloadAction<AllProduct>) => {
      const existingItem = state.wishlists.find(
        (item) => item._id === action.payload._id
      );

      state.wishlists = existingItem
        ? state.wishlists.filter((wishlist) => wishlist._id !== action.payload._id)
        : [...state.wishlists, action.payload];
    },

    // counter
    handleCountValue: (
      state,
      action: PayloadAction<"increment" | "decrement" | "none">
    ) => {
      if (action.payload === "none") {
        state.countValue = 1;
        return;
      }

      state.countValue =
        action.payload === "increment"
          ? state.countValue + 1
          : Math.max(1, state.countValue - 1);
    },

    // selected color
    handleColorChange: (state, action: PayloadAction<string | undefined>) => {
      state.selectedColor = action.payload;
    },

    // selected Sizes
    handleSizeChange: (state, action: PayloadAction<string | undefined>) => {
      state.selectedSize = action.payload;
    },
  },
});

export const {
  hydrate,
  addToCart,
  clearCart,
  handleCountValue,
  incrementAmount,
  removeFromCart,
  decrementAmount,
  handleCartOpen,
  toggleToWishlists,
  handleColorChange,
  handleSizeChange,
} = cartSlice.actions;
export default cartSlice.reducer;
