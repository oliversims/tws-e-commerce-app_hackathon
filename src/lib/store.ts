import { configureStore } from "@reduxjs/toolkit";
import cartSlice from "./features/cart/cartSlice";
import authSlice from "./features/auth/authSlice";
import sidebarSlice from "./features/sidebar/sidebarSlice";
import { persistenceMiddleware } from "./features/cart/persistence";

export const makeStore = () => {
  return configureStore({
    reducer: {
      authSlice,
      cartSlice,
      sidebarSlice,
    },
    // Persistence is a side effect, so it lives in middleware rather than in
    // the reducers themselves.
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware().concat(persistenceMiddleware),
  });
};

export type AppStore = ReturnType<typeof makeStore>;
export type RootState = ReturnType<AppStore["getState"]>;
export type AppDispatch = AppStore["dispatch"];
