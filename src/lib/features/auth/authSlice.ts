import { createSlice, PayloadAction } from "@reduxjs/toolkit";

// Define a type for the slice state
export type User = {
  id: string;
  name: string;
  email: string;
  role?: string;
};

export interface AuthState {
  isAuthenticated: boolean;
  currentUser: User | null;
}

/**
 * Starts logged-out on both server and client; the stored user is applied by
 * `hydrateUser` from StoreProvider on mount. See the note in cartSlice.
 */
const initialState: AuthState = {
  isAuthenticated: false,
  currentUser: null,
};

export const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    hydrateUser: (state, action: PayloadAction<User | null>) => {
      state.currentUser = action.payload;
    },

    setAuthenticated: (state, action: PayloadAction<boolean>) => {
      state.isAuthenticated = action.payload;
    },

    removeCurrentUser: (state) => {
      state.currentUser = null;
    },

    setCurrentUser: (state, action: PayloadAction<User | null>) => {
      state.currentUser = action.payload;
    },

    /** Clears every trace of the session in one action. */
    signedOut: (state) => {
      state.isAuthenticated = false;
      state.currentUser = null;
    },
  },
});

export const {
  hydrateUser,
  setAuthenticated,
  removeCurrentUser,
  setCurrentUser,
  signedOut,
} = authSlice.actions;
export default authSlice.reducer;
