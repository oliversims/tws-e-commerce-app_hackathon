import axios from "axios";

// In the browser, always talk to our own origin. On the server this client is
// only used for genuinely external calls -- Server Components query the
// database directly via src/lib/queries rather than looping back over HTTP.
const baseURL =
  typeof window !== "undefined"
    ? `${window.location.origin}/api`
    : process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api";

/**
 * The session cookie is httpOnly and therefore invisible to JavaScript by
 * design. `withCredentials` sends it automatically on same-origin requests, so
 * there is no token for this module to read or attach -- the previous
 * `Authorization: Bearer` path only worked because the cookie had been
 * downgraded to be script-readable.
 */
export const axiosInstance = axios.create({
  baseURL,
  headers: {
    "Content-Type": "application/json",
  },
  withCredentials: true,
});

const fetchData = {
  get: async (url: string, params = {}) => {
    return axiosInstance.get(url, { params });
  },
  post: async (url: string, data = {}) => {
    return axiosInstance.post(url, data);
  },
};

export default fetchData;
