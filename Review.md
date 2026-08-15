# EasyShop — Application Source Code Review

> **STATUS: REMEDIATED — 2026-08-15.**
> All 6 Critical, 8 High and 12 Medium findings below have been fixed and verified.
> `tsc --noEmit` clean · `next lint` clean · `next build` clean · **54/54 runtime security assertions passing**
> against a live instance backed by MongoDB. Remaining open items are the Low-severity
> entries in §5 — see **§8. Remediation Record** at the end for exactly what changed,
> what was verified, and what is still outstanding.

**Date:** 2026-08-15
**Scope:** Application source only — `src/**`, `scripts/**`, and app-level build config (`package.json`, `tsconfig*.json`, `next.config.*`, `.eslintrc.json`, `.env`, `Dockerfile`).
**Explicitly out of scope (untouched, not reviewed):** `terraform/**`, `kubernetes/**`, `helm-values/**`, `argocd/**`, `Jenkinsfile`, `docker-compose.yml`, and all YAML.

**Stack:** Next.js 14.1.0 (App Router) · React 18 · TypeScript 5 (strict) · MongoDB/Mongoose 8 · Redux Toolkit · Tailwind + shadcn/ui · hand-rolled JWT auth (`jose`).

**No code was modified.** This document is analysis and recommended remediation only.

---

## 1. Executive Summary

The codebase is a functional, well-styled storefront with a clean component structure and a sensible App Router layout. `tsc --noEmit` passes cleanly under `strict: true`, which is a genuine strength.

However, the **security posture of the authentication and commerce layers is not production-safe**, and the **order/cart pricing path trusts the client completely**. There are also several outright broken features shipping in the UI.

### Findings by severity

| Severity | Count | Theme |
|---|---|---|
| 🔴 Critical | 6 | Secrets in VCS, auth token exposed to JS, unauthenticated write endpoint, client-controlled pricing |
| 🟠 High | 8 | Open redirect, NoSQL operator injection, sensitive logging, broken pages, unprotected route |
| 🟡 Medium | 12 | Model re-registration, broken `populate`, state/persistence bugs, SSR self-HTTP calls |
| 🔵 Low / Nit | 10 | Dead code, duplicate types, unused deps, placeholder data, console noise |

### The five things to fix first

1. **Rotate the secrets in the committed `.env` file** and purge it from git history (§2.1).
2. **Delete `createCookies()`** — it overwrites the server's `httpOnly` cookie with a JS-readable, non-`Secure` one (§2.2).
3. **Add an auth + admin guard to `POST /api/products/[productId]`** — it is currently fully open (§2.3).
4. **Recompute all prices and totals server-side** in the cart and order routes (§2.4, §2.5).
5. **Remove the hardcoded `JWT_SECRET` fallback** — fail closed instead (§2.6).

---

## 2. 🔴 Critical Findings

### 2.1 Live secrets committed to version control
**File:** `.env` (tracked — confirmed via `git ls-files .env`)

`.gitignore` lists `.env`, but the file was committed **before** that rule was added, so the ignore rule has no effect. At the time of review it held live values for:

```
NEXTAUTH_SECRET=<44-char base64 secret — REDACTED>
JWT_SECRET=<64-char hex secret — REDACTED>
MONGODB_URI=mongodb://easyshop-mongodb:27017/easyshop
```

> The literal values are deliberately **not** reproduced here — this document is
> committed, and quoting them would republish the very secrets §8.3 asks you to
> purge. Recover them from the pre-remediation git history if you need to
> confirm what was exposed.

Anyone with repo read access can forge a valid session token for **any user id and any role**, including `role: "admin"`.

**Remediation**
1. Treat both secrets as compromised. Generate new ones (`openssl rand -hex 32`) and load them from the deployment's secret store.
2. `git rm --cached .env` and commit — the `.gitignore` rule then takes effect.
3. Purge from history with `git filter-repo` (or BFG). Coordinate the force-push with anyone holding a clone.
4. Commit a `.env.example` with empty placeholder values so onboarding still works.
5. Note the `.gitignore` rule `*.txt` (with only `!**/requirements.txt` unignored) is unusually broad and will silently exclude legitimate text files — worth narrowing.

---

### 2.2 Auth token deliberately downgraded to a JS-readable, insecure cookie
**Files:** `src/app/actions.ts:5-21`, `src/components/forms/LoginForm.tsx:62`, `src/components/forms/SignupForm.tsx:62`

`POST /api/auth/login` correctly sets a hardened cookie (`login/route.ts:55-63`):

```ts
httpOnly: true, secure: process.env.NODE_ENV === "production", sameSite: "lax"
```

The client then immediately throws that protection away by calling the `createCookies` server action with the same token:

```ts
// src/app/actions.ts:11-20
cookies().set({
  name: "token",
  value: token,
  httpOnly: false, // Allow client-side access
  secure: false,   // Set to false for HTTP on EC2
  ...
});
```

Because the cookie name is identical, this **overwrites** the hardened cookie. Net result:

- Any XSS anywhere on the origin can read the session token via `document.cookie` and exfiltrate it. The token is valid for **30 days** and is not revocable (no server-side session store, no `jti` denylist).
- `secure: false` means the token is transmitted in cleartext over plain HTTP.

`src/lib/fetchDataFromApi.ts:8-20` (`getAuthToken`) reads `document.cookie` and therefore *depends* on this downgrade — that function is why the weakening was introduced.

**Remediation**
1. Delete `createCookies` and both call sites. The API route's `Set-Cookie` is already applied to the browser by the `fetch`/axios response; the extra server action is redundant as well as harmful.
2. Delete `getAuthToken` and the `Authorization` header logic in `fetchDataFromApi.ts`. `axiosInstance` already sets `withCredentials: true`, so the `httpOnly` cookie is sent automatically — the header path is pure attack surface.
3. Keep `secure: true` in production unconditionally and terminate TLS at the load balancer.
4. Shorten token lifetime to ~1 hour and add a refresh mechanism, or move to a server-side session store so logout can actually revoke.

---

### 2.3 `POST /api/products/[productId]` has no authentication at all
**File:** `src/app/api/products/[productId]/route.ts:34-53`

`GET`, `PUT` and `DELETE` in this file all guard correctly. `POST` does not:

```ts
export async function POST(request: NextRequest, { params }) {
  try {
    await dbConnect();
    const body = await request.json();
    const product = await Product.create(body);   // no requireAuth, no role check
    return NextResponse.json(product);
  } ...
}
```

Any unauthenticated caller can inject arbitrary products into the catalog — including entries with attacker-chosen `price`, `title`, `description`, and `image` paths. This is unauthenticated write access to the product database, usable for storefront defacement or as a spam/SEO vector.

Two secondary problems in the same handler:
- It ignores `params.productId` entirely, so the route's own contract is meaningless. `POST /api/products` (`route.ts:125`) already exists and *is* guarded — this handler is a redundant duplicate.
- It passes the raw request body straight into `Product.create(body)` with no field allowlist.

**Remediation**
- Delete this `POST` handler. The guarded collection-level `POST /api/products` covers the use case.
- If it must stay, mirror the `PUT` guard (`requireAuth` + `auth.role !== 'admin'` → 403) and validate the body against a Zod schema before `create`.

---

### 2.4 Cart accepts the item price from the client
**File:** `src/app/api/cart/route.ts:62, 90-115`

```ts
const { productId, quantity, price } = body;
const product = await Product.findOne({ originalId: productId });   // product IS looked up
...
const cartItem = { product: product.originalId, quantity, price };  // ...but client price is used
cart.total = cart.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
```

The product is fetched from the database and then its authoritative `product.price` is discarded in favour of the client-supplied `price`. A trivial `curl` sets any item to `0.01`, or negative.

`quantity` is likewise unvalidated at the route level. The schema's `min: 1` (`cart.ts:24`) catches negatives on save, but non-integers and absurd values (`1e9`) pass through.

**Remediation**
- Ignore `price` from the request body entirely; use `product.price`.
- Validate `quantity` with Zod: `z.number().int().min(1).max(99)`.
- Keep total computation in the `pre('save')` hook (`cart.ts:49-52`) and delete the duplicate calculation at `route.ts:115` — having both invites divergence.

---

### 2.5 Orders are created entirely from client-supplied data
**File:** `src/app/api/orders/route.ts:70-133`; caller `src/components/checkout/OrderSummery.tsx:84-105`

`POST /api/orders` accepts `items[]` (each with `productId`, `quantity`, `price`) and `total` from the request body and persists them verbatim:

```ts
const { shippingAddress, billingAddress, paymentMethod, items, total } = body;
...
const order = await Order.create({
  user: auth.userId,
  items: items.map((item) => ({ product: String(item.productId), quantity: item.quantity, price: item.price })),
  total,   // client-supplied
  ...
});
```

There is **no** verification that:
- the `productId` values exist in the catalog,
- the `price` values match the catalog,
- `total` equals the sum of the line items,
- the items correspond to anything in the user's server-side cart (the `Cart` collection is only *deleted* afterwards at line 125, never *read*).

An authenticated user can place an order for any product at any price, including `total: 0`. The `+ 20` shipping/tax added client-side (`OrderSummery.tsx:93`) is equally trivial to strip.

This is the highest-impact business-logic flaw in the codebase. It is only mitigated today by the fact that the sole payment method is cash-on-delivery.

**Remediation**
1. Server-side, load the authoritative `Cart` for `auth.userId` and build the order from **that**, ignoring `items` in the body.
2. Re-fetch each `Product` and use `product.price` for every line.
3. Compute `total` server-side; define shipping/tax as server constants (currently duplicated as `+ 20` in the order payload and `+ 10 + 10` in the summary display).
4. Reject the request if the server-side cart is empty rather than trusting a client-supplied array.
5. Validate `shippingAddress`/`billingAddress` with Zod before the ad-hoc field mapping at lines 99-107.
6. Wrap order-create + cart-delete in a transaction (or at minimum stop swallowing the cart-delete failure at line 126-128 — right now a failed clear leaves a stale cart and is only logged).

---

### 2.6 JWT secret falls back to a hardcoded literal
**File:** `src/lib/auth/utils.ts:5-7`

```ts
const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || 'your-jwt-secret-key'
);
```

If `JWT_SECRET` is unset or empty in any environment, the app silently signs and verifies tokens with a publicly-known string. Anyone can then mint an admin token. The failure is completely silent — no warning, no startup error.

The same anti-pattern appears in `src/lib/db.ts:12-16`, where `MONGODB_URI` defaults to `mongodb://localhost:27017/easyshop` and the subsequent `if (!MONGODB_URI) throw` is therefore **dead code that can never fire**.

**Remediation**
```ts
const secret = process.env.JWT_SECRET;
if (!secret || secret.length < 32) {
  throw new Error('JWT_SECRET must be set to a value of at least 32 characters');
}
const JWT_SECRET = new TextEncoder().encode(secret);
```
Apply the same fail-closed pattern to `MONGODB_URI` and remove the unreachable guard in `db.ts`.

---

## 3. 🟠 High-Severity Findings

### 3.1 Open redirect in middleware
**File:** `src/middleware.ts:26-32`

```ts
if (isAuthPage && isAuth) {
  const redirectTo = request.nextUrl.searchParams.get('redirect');
  if (redirectTo) {
    return NextResponse.redirect(new URL(redirectTo, request.url));
  }
```

`new URL()` with an absolute input **ignores the base**. A logged-in user visiting `/login?redirect=https://evil.example/phish` is redirected off-site by your own domain. `LoginForm.tsx:76-87` has the same flaw via `router.replace(redirectTo)`.

**Remediation** — allow only same-origin relative paths in both places:
```ts
const isSafe = redirectTo.startsWith('/') && !redirectTo.startsWith('//');
return NextResponse.redirect(new URL(isSafe ? redirectTo : '/', request.url));
```
Reject `//` explicitly — it is protocol-relative and resolves off-origin.

---

### 3.2 NoSQL operator injection in the login handler
**File:** `src/app/api/auth/login/route.ts:9-15`

```ts
const { email, password } = body;
const user = await User.findOne({ email }).select("+password");
```

`email` is not type-checked, so `{"email": {"$ne": null}, "password": "..."}` makes Mongoose match the *first user in the collection* rather than a specific address. Full account takeover still requires the bcrypt comparison to succeed, so this is not directly exploitable for login bypass — but it is a working oracle for probing account existence and ordering, and the same unvalidated pattern would be fatal if the comparison logic ever changes.

`mongoose@8` is also flagged HIGH in `npm audit` for *"Improper Sanitization of `$nor` in `sanitizeFilter`"*, which compounds this.

**Remediation** — validate the body with Zod before touching the database:
```ts
const schema = z.object({ email: z.string().email(), password: z.string().min(8) });
const { email, password } = schema.parse(await request.json());
```
Apply the same to `register/route.ts` (which currently hand-rolls a regex at line 21) and every other route that reads `request.json()`. Consider enabling `mongoose.set('sanitizeFilter', true)` as defence in depth.

---

### 3.3 Tokens and payloads written to application logs
**File:** `src/lib/auth/utils.ts:31, 37, 61, 68`; also `login/route.ts:12, 27, 39`

```ts
console.log('Invalid token format:', token);       // logs the raw JWT
console.log('Token verified successfully:', payload);
console.log('Generating token with payload:', tokenPayload);
console.log('Invalid password for user:', email);  // logs the email on failed login
```

These land in stdout, which in this deployment is shipped to Elasticsearch. Session tokens in a searchable log index are effectively long-lived credentials sitting in a system with a different access-control model than the app.

`src/app/api/cart/route.ts` alone has 17 `console.*` calls, several dumping full cart objects. Project-wide: **83** `console.*` statements.

**Remediation**
- Remove every log line that prints a token, a JWT payload, a password-adjacent value, or a user email.
- Introduce a small logger with levels and gate debug output behind `NODE_ENV !== 'production'`.
- Add `no-console` (with a `warn`/`error` allowlist) to `.eslintrc.json` to prevent regressions.

---

### 3.4 `/orders` page crashes on load
**File:** `src/app/orders/page.tsx:43-50`

```ts
const response = await fetch('/api/orders');
const data = await response.json();
setOrders(data);          // API returns { orders, page, limit } — not an array
```

`orders` is then an object. `orders.length === 0` evaluates `undefined === 0` → `false`, so the empty-state guard is skipped and `orders.map(...)` at line 89 throws `TypeError: orders.map is not a function`. The page never renders.

Three further defects in the same file:
- `item.product.image` is typed `string` (line 12) but the API returns `string[]`. Passing an array to `next/image`'s `src` is invalid.
- The route is **not** in the middleware matcher (`middleware.ts:53-61` covers `/checkout`, `/profile/*`, `/admin/*`, `/login`, `/register`). Unauthenticated users reach the page, get a 401, and see a raw error string.
- The whole file duplicates `/profile/orders` (`src/app/profile/orders/Orders.tsx`), which is the version actually linked from the nav (`Navbar.tsx` "Orders" → `/profile/orders`) and from `checkout/success`.

**Remediation** — delete `src/app/orders/page.tsx` as dead, broken duplication. If it is meant to stay, use `setOrders(data.orders)`, fix the image type, and add `/orders` to the middleware matcher.

---

### 3.5 `populate()` on a non-ObjectId ref silently returns nothing
**Files:** `src/app/api/orders/[orderId]/route.ts:18, 58`; schema at `src/lib/models/order.ts:26-31`

```ts
// schema — product is a String holding Product.originalId
product: { type: String, ref: 'Product', required: true }

// route — populate expects the string to be a Product _id
.populate('items.product', 'title price image')
```

Mongoose resolves `ref: 'Product'` against `Product._id`, but the stored value is `originalId`. Because `migrate-data.ts:97-98` happens to set `_id === originalId` for migrated rows, this *accidentally* works for seeded products — and will break for any product created through `POST /api/products`, which generates a normal ObjectId `_id`.

Note the collection routes (`orders/route.ts:29`, `cart/route.ts:24`) sidestep this with manual `Product.findOne({ originalId })` lookups, so the two paths behave differently for the same data.

**Remediation** — pick one convention. Either store a real `ObjectId` ref and use `populate` everywhere, or drop `ref:` from the schema and use the manual-lookup approach consistently. The manual lookups also need fixing for N+1 (§4.5).

---

### 3.6 Middleware forwards attacker-controlled identity headers
**File:** `src/middleware.ts:40-44`

```ts
const requestHeaders = new Headers(request.headers);   // copies inbound headers verbatim
if (isAuth) {
  requestHeaders.set("x-user-id", isAuth.userId);
  requestHeaders.set("x-user-role", isAuth.role);
}
```

When the request is *not* authenticated, an inbound `x-user-id: <victim>` / `x-user-role: admin` header supplied by the client passes straight through to the downstream handler untouched.

No route reads these headers today (verified — zero consumers outside `middleware.ts`), so this is currently latent rather than exploitable. It is a trap for the next person who reaches for `headers().get('x-user-id')` as a convenient auth shortcut.

**Remediation** — always `delete` both headers before conditionally setting them:
```ts
requestHeaders.delete('x-user-id');
requestHeaders.delete('x-user-role');
if (isAuth) { /* set */ }
```

---

### 3.7 Logout does not clear client state or call the logout endpoint
**Files:** `src/components/Navbar.tsx:85-93`, `src/components/profile/ProfileSidebar.tsx:39-44`

```ts
const handleLogout = async () => {
  await removeCookies();
  dispatch(setAuthenticated(false));
  router.push("/login");
};
```

Missing:
- `dispatch(setCurrentUser(null))` — so `localStorage.currentUser` (written by `authSlice.ts:39`) survives logout. The next visitor to that browser sees the previous user's name and email rehydrated into Redux at `authSlice.ts:18-21`.
- Any call to `POST /api/auth/logout` — that route (`src/app/api/auth/logout/route.ts`) exists and is **never invoked anywhere**. It is dead code.
- Any cart/wishlist clearing, so `localStorage.cartItems` also persists across users on a shared device.

The two logout handlers also diverge — `Navbar` redirects to `/login`, `ProfileSidebar` to `/`.

**Remediation** — extract one shared `useLogout()` hook that calls `POST /api/auth/logout`, dispatches `setAuthenticated(false)` **and** `setCurrentUser(null)`, clears the cart/wishlist keys from `localStorage`, and redirects consistently.

---

### 3.8 Navbar auth check only tests for cookie *presence*
**Files:** `src/app/actions.ts:36-39`, `src/components/Navbar.tsx:68-80`

```ts
export async function authenticated() {
  const token = await getCookies("token");
  return !!token;          // never verified
}
```

An expired, malformed, or forged token still renders the logged-in UI. The user sees their profile menu, clicks through, and gets 401s from every API call.

Separately, the effect that consumes this lists `isAuthenticated` in its own dependency array while dispatching `setAuthenticated` inside itself (`Navbar.tsx:68-80`) — a self-triggering effect that re-runs on every value flip.

**Remediation** — have `authenticated()` call `verifyToken()` rather than checking presence, or drop it entirely and rely on the `/api/auth/check` call that `AuthProvider` already makes on mount (`AuthProvider.tsx:14`). Two parallel auth-status mechanisms is one too many. Remove `isAuthenticated` from the effect's dependency array.

---

## 4. 🟡 Medium-Severity Findings

### 4.1 Mongoose models deleted and re-registered on every module evaluation
**Files:** `src/lib/models/cart.ts:54-59`, `src/lib/models/order.ts:81-86`

```ts
if (mongoose.models.Cart) {
  delete mongoose.models.Cart;
}
const Cart = mongoose.model<ICart>('Cart', cartSchema);
```

`user.ts:75` and `product.ts:59` use the correct `mongoose.models.X || mongoose.model(...)` guard; these two do the opposite. Re-registering discards compiled schema state and any registered hooks/indexes on every hot reload, and makes `instanceof` checks unreliable across module instances. It is the kind of workaround that gets added to silence an `OverwriteModelError` and then hides the real cause.

**Remediation** — match the pattern used in `user.ts`:
```ts
export default mongoose.models.Cart || mongoose.model<ICart>('Cart', cartSchema);
```

---

### 4.2 Redux reducers perform `localStorage` side effects
**File:** `src/lib/features/cart/cartSlice.ts` (11 `localStorage.setItem` calls inside reducers); `src/lib/features/auth/authSlice.ts:39-42`

Reducers must be pure. Writing to `localStorage` inside them breaks time-travel debugging, makes reducers untestable in Node, and will misbehave under React 18 strict-mode double-invocation.

There is also a concrete bug at `cartSlice.ts:54-58` — the early-return branch for an item already in the cart updates `selectedColor`/`selectedSize` but **never persists**, so those selections are lost on reload:

```ts
if (item) {
  item.selectedColor = state.selectedColor;
  item.selectedSize = state.selectedSize;
  return;                    // <- no localStorage.setItem
}
```

**Remediation** — move persistence into a middleware (`store.subscribe`, or `createListenerMiddleware`) that mirrors the relevant slice to `localStorage` after each action. Then delete all 11 in-reducer writes.

---

### 4.3 `localStorage` read during reducer initialisation causes hydration mismatch
**Files:** `src/lib/features/cart/cartSlice.ts:26-39`, `src/lib/features/auth/authSlice.ts:16-22`

```ts
cartItems:
  (typeof window !== "undefined" &&
    JSON.parse(window.localStorage.getItem("cartItems") as string)) || [],
```

Two problems:
1. The server renders with `[]` and the client with the stored array — a React hydration mismatch. `OrderSummery.tsx:31,137-141` papers over this with an `isClient` flag and a skeleton; that is treating a symptom.
2. `JSON.parse` is unguarded. Any malformed value in `localStorage` (truncated write, another app on the same origin, manual tampering) throws **at module-evaluation time**, before any error boundary exists — the whole app fails to boot with a white screen.

**Remediation** — initialise with `[]`, then hydrate from `localStorage` in a `useEffect` inside `StoreProvider`. Wrap every `JSON.parse` in `try/catch` returning a safe default.

---

### 4.4 Server Components call the app's own HTTP API
**Files:** `src/components/ProductGrid.tsx:34`, `src/components/RelatedProducts.tsx:15`, `src/app/products/[slug]/page.tsx:16`

These are async Server Components using the axios client from `fetchDataFromApi.ts`, which on the server resolves to `process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api'`. So the server makes an HTTP request to itself to reach code running in the same process.

Consequences: a full network round-trip and JSON serialise/deserialise per render; no Next.js data caching or revalidation; and a hard dependency on `NEXT_PUBLIC_API_URL` being correct inside the container — if it points at a public hostname, every SSR render leaves the pod and back. Under load this can deadlock when the server's own request pool is saturated.

Note also that `axios` is flagged HIGH in `npm audit` for *"SSRF and Credential Leakage via Absolute URL"*, which is directly relevant to a client whose `baseURL` comes from an environment variable.

**Remediation** — call `dbConnect()` and the Mongoose models directly from Server Components, or extract the query logic into `src/lib/queries/*.ts` shared by both the Server Components and the route handlers. Reserve `fetchDataFromApi` for genuinely client-side calls.

---

### 4.5 N+1 queries when populating cart and order items
**Files:** `src/app/api/cart/route.ts:22-37` and `125-140`; `src/app/api/orders/route.ts:25-48`

```ts
cart.items.map(async (item) => {
  const product = await Product.findOne({ originalId: item.product });
  ...
})
```

One database round-trip per line item. `orders/route.ts` nests this inside a per-order loop, so a page of 5 orders × 4 items is 20 sequential-ish queries plus the order query. `cart/route.ts` runs the identical block twice (GET and POST) — copy-pasted, not shared.

**Remediation** — single batched query:
```ts
const ids = items.map(i => i.product);
const products = await Product.find({ originalId: { $in: ids } });
const byId = new Map(products.map(p => [p.originalId, p]));
```
Extract into one `populateItems(items)` helper used by all three call sites. Also add an index on `Product.originalId` (currently `unique: true` implies one, but confirm it exists in the deployed collection).

---

### 4.6 Invalid ObjectId returns 500 instead of 404
**File:** `src/app/api/orders/[orderId]/route.ts:15-18, 54, 85-88`

`Order.findOne({ _id: params.orderId })` throws a Mongoose `CastError` when `orderId` is not a valid ObjectId. The catch block at line 28-33 maps everything except `'Authentication required'` to **500**, so `/api/orders/garbage` reports a server error for what is plainly a client error.

**Remediation** — validate with `mongoose.Types.ObjectId.isValid(params.orderId)` up front and return 404. More broadly, replace the `error.message === 'Authentication required' ? 401 : 500` idiom (repeated in **11** handlers) with typed error classes carrying a status code.

---

### 4.7 Internal error messages leaked to clients
**Files:** `orders/route.ts:57, 137, 143`; `cart/route.ts:49, 153, 173`; `products/[productId]/route.ts:27, 50, 88, 121`; `auth/register/route.ts:82`

```ts
return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
```

Raw Mongoose errors reach the browser — schema paths, validator text, index names, and on duplicate-key errors the offending value. `login/route.ts:67-73` gets this right (generic `"Authentication failed"`); the rest do not.

**Remediation** — log the detail server-side, return a generic message plus a correlation id. Return specific messages only for deliberate 4xx validation failures.

---

### 4.8 Inconsistent cookie attributes across auth routes
| Route | `sameSite` | `maxAge` |
|---|---|---|
| `login/route.ts:60,62` | `lax` | 30 days |
| `register/route.ts:75` | `strict` | *(none — session cookie)* |
| `logout/route.ts:13` | `strict` | expired |
| `actions.ts:16,19` | `lax` | 30 days |

Registering therefore produces a session-only cookie that disappears when the browser closes, while logging in produces a 30-day one — the same user gets different session lifetimes depending on which door they came through. And because `logout` sets `sameSite: 'strict'` while `login` used `lax`, browsers may treat them as distinct cookies and fail to clear the original.

**Remediation** — define the cookie options once in a shared constant and import it in all four places.

---

### 4.9 Duplicate `next.config` files
**Files:** `next.config.js`, `next.config.cjs`

Both exist and both `module.exports` a config. Next.js resolves `next.config.js` first, so `next.config.cjs` — including its `webpack` JSON-loader rule — is **silently ignored**. Anyone editing the `.cjs` file will watch their changes do nothing.

**Remediation** — delete `next.config.cjs`. (The JSON rule in it is redundant anyway: `tsconfig.json` sets `resolveJsonModule: true` and webpack 5 handles `.json` natively.)

---

### 4.10 `Orders` component double-fetches and hides the list while paginating
**File:** `src/app/profile/orders/Orders.tsx:64-72`

```ts
const handleRefresh = () => { setPage(1); setHasMore(true); fetchOrders(1); };
useEffect(() => { fetchOrders(page); }, [page]);
```

When `page !== 1`, `handleRefresh` calls `fetchOrders(1)` directly *and* changes `page`, firing the effect too — two concurrent requests whose responses can land out of order.

Separately, "Load More" sets `loading = true`, and the guard at line 74-80 returns early for the whole component — so the already-loaded list is replaced by "Loading orders..." instead of appending below it.

**Remediation** — drive fetching solely from the effect; use a separate `isLoadingMore` flag so the initial-load guard does not swallow the rendered list. `page` is also missing from the effect's dependency lint (`fetchOrders` is not memoised).

---

### 4.11 Address forms notify the parent from a mount-only effect
**Files:** `src/components/forms/BillingAddressForm.tsx:48-50`, `ShippingAddressForm.tsx:48-50`

```ts
useEffect(() => {
  onFormDataChange(form.getValues());
}, []);          // onFormDataChange not in deps
```

`onFormDataChange` is a new inline arrow on every parent render (`checkout/page.tsx:103,113`), so the exhaustive-deps rule is being violated deliberately. It works today only because the parent's `updateFormData` is stable in behaviour — fragile.

The forms also propagate via the DOM `onChange` bubble on the `<form>` element (line 82) rather than react-hook-form's `watch()`, which misses programmatic updates and non-bubbling controls.

**Remediation** — wrap the parent callbacks in `useCallback` and use `form.watch()` with a subscription effect.

---

### 4.12 Two parallel type systems for the same domain
**Files:** `src/types.d.ts` (global ambient) vs `src/types/product.ts` (exported modules)

`GroceryProduct`, `GadgetProduct`, `ClothingProduct`, `AllProduct`, `SingleProductType` etc. are declared **twice** — once globally in `types.d.ts`, once as exports in `types/product.ts` — with identical bodies. Consumers are split: `ProductGrid.tsx:6` imports from `@/types/product`; `AddToCartWrapper.tsx:20`, `AddToWishlist.tsx:45` and `RelatedProducts.tsx:21` use the global. The two will drift.

`SingleProductType` is also an intersection of all eight product shapes, meaning it claims every product has `authors`, `sizes`, `colors`, and `rating` simultaneously — that is why `products/[slug]/page.tsx` needs `product?.categories` optional chaining on a non-optional field.

**Remediation** — delete the duplicated declarations from `types.d.ts` (keep only `SearchParamsType`), import from `@/types` everywhere, and model products as a discriminated union on `shop_category` rather than an intersection.

---

## 5. 🔵 Low Severity / Code Quality

### 5.1 Placeholder personal data hardcoded into the checkout flow
**Files:** `src/app/checkout/page.tsx:39-47`, `BillingAddressForm.tsx:37-45`, `ShippingAddressForm.tsx:37-45`

```ts
const defaultAddress = {
  title: "Afzal Hassan",
  phone: "+91 9499004395",
  streetAddress: "12/43 Kidd Avenue",
  city: "Muzaffarpur", state: "Bihar", zip: "840000", country: "India",
};
```

Every checkout is pre-populated with this named individual's address. Because `OrderSummery.validateAddress` (line 67-75) only checks that fields are non-empty, a user who never touches the form places a real order shipped to it. The three copies of the data have already drifted (the two forms carry different phone numbers and street addresses).

**Remediation** — default to empty strings and let validation require real input. If demo pre-fill is wanted for the hackathon, gate it behind `NODE_ENV !== 'production'` and use obviously-fake values.

---

### 5.2 Demo credentials pre-filled in the login form
**File:** `src/components/forms/LoginForm.tsx:51-54`

```ts
defaultValues: { email: "demo@gmail.com", password: "test1234" },
```

Matches the account created by `scripts/seed-demo-user.ts:9`. Acceptable for a demo, but it ships a working credential pair in the client bundle. Gate behind an env flag if this ever faces real users.

---

### 5.3 Non-functional features rendered as working UI
- `src/app/profile/change-password/ChangePass.tsx:72-76` — submit handler is `console.log(values)`. There is **no** `/api/auth/change-password` route. The form validates, submits, shows no error, and does nothing.
- `src/components/forms/ProfileForm.tsx:88-92` — same; "Save Changes" is a no-op. Avatar upload (line 94-101) creates a blob URL that is never uploaded and leaks (`URL.revokeObjectURL` is never called).
- `src/components/forms/ContactForm.tsx` — contains a `console.log` submit handler.
- Wishlists (`cartSlice.ts:104-117`) are `localStorage`-only with no server persistence, so they vanish across devices despite living under an authenticated `/profile` route.

**Remediation** — either implement the endpoints or disable the controls with an explicit "coming soon" state. Shipping forms that silently discard input is worse than not shipping them.

---

### 5.4 Unused dependencies in the production bundle
Verified absent from all of `src/**` and `scripts/**`:

| Package | Note |
|---|---|
| `next-auth` (^4.24.5) | Auth is hand-rolled with `jose`. Flagged **CRITICAL** in `npm audit`. |
| `jsonwebtoken` (^9.0.2) | Superseded by `jose`. Its `jws` dep is flagged HIGH — *"Improperly Verifies HMAC Signature"*. |
| `@types/jsonwebtoken` | Follows the above. |
| `@types/react-redux` | `react-redux` v9 ships its own types; this stub can conflict. |

`sharp` is legitimate (Next.js image optimisation). `NEXTAUTH_SECRET` and `NEXTAUTH_URL` in `.env` are vestigial too — though `NEXTAUTH_URL` *is* read by `actions.ts:6`, which is itself slated for deletion (§2.2).

**Remediation** — `npm uninstall next-auth jsonwebtoken @types/jsonwebtoken @types/react-redux`. This alone clears two of the three CRITICAL audit findings.

---

### 5.5 Dependency vulnerabilities
`npm audit` reports **18 vulnerabilities (3 critical, 10 high, 4 moderate, 1 low)**. Beyond the removable packages above:

| Package | Severity | Issue |
|---|---|---|
| `next` 14.1.0 | **CRITICAL** | SSRF in Server Actions |
| `axios` | HIGH | SSRF / credential leakage via absolute URL |
| `mongoose` | HIGH | Improper `$nor` sanitisation → NoSQL injection (see §3.2) |
| `postcss` | HIGH | XSS via unescaped `</style>` |
| `sharp` | HIGH | Inherited libvips CVEs |

**Remediation** — upgrade Next.js to the latest 14.x patch (or 15.x, which needs an App Router migration pass). Run `npm audit fix`, then re-audit. Add `npm audit --audit-level=high` to CI. Note `package-lock.json` **and** `yarn.lock` both exist — pick one package manager; having both guarantees they will diverge.

---

### 5.6 Assorted smaller items

| # | File / Line | Issue |
|---|---|---|
| a | `lib/utils.ts:27` | `discountPercent` divides by `oldPrice` with no zero-guard → `Infinity%` / `NaN%` rendered when `oldPrice` is 0 or missing. |
| b | `api/products/route.ts:83-85` | `page`/`limit` unbounded. `?limit=1000000` is an easy resource-exhaustion vector. Clamp to a max. |
| c | `ProductGrid.tsx:57` | `Math.ceil(totalCount / 10)` hardcodes the page size while the API default lives in `products/route.ts:84`. Two sources of truth; breaks the moment either changes. |
| d | `Paginations.tsx:27` | Fallback `Math.ceil(totalCount / 20)` uses **20** — a third, different page size. |
| e | `api/products/route.ts:138` | `Product.create(body)` with no field allowlist; an admin typo writes arbitrary keys. |
| f | `OrderSummery.tsx:147` | Typo in user-facing copy: `"No prodduct select!"`. |
| g | `ChangePass.tsx:56-58` | Typo `"Passoword"` in three validation messages. |
| h | `ChangePass.tsx:101,117,133` | Password `<Input>`s lack `type="password"` — passwords render in plaintext as the user types. |
| i | `ContactForm`, `ProfileForm`, `ChangePass` | `defaultValues: {}` with a schema requiring all fields → react-hook-form warns about uncontrolled→controlled transitions. |
| j | `api/orders/route.ts:63-67` | `OrderItemInput` is declared between the two exported handlers; move type declarations to the top of the file. |
| k | `SearchBar.tsx:129-130` | Mixes `defaultValue` (uncontrolled) with `onChange`+state (controlled); the field does not update when `?q=` changes via navigation. |
| l | `middleware.ts:8` | `getTokenFromRequest` is called, then `isAuthenticated(request)` calls it a **second** time internally. Pass the token through. |
| m | `api/auth/logout/route.ts` | Entire route is dead code — no caller anywhere (§3.7). |
| n | `scripts/migrate-data.ts:7` | `path.resolve(path.dirname(''))` evaluates to the CWD and the resulting `scriptDir` is never used. Dead line. |
| o | `scripts/migrate-data.ts:75,119` | `deleteMany({})` on both products **and users** with no confirmation prompt or env guard. One careless `npm run migrate` against a live `MONGODB_URI` destroys all accounts. |
| p | `.eslintrc.json` | Only `next/core-web-vitals`. No `@typescript-eslint`, no `no-console`, no `no-explicit-any` (38 `: any` annotations across the codebase). |
| q | project-wide | **No tests of any kind** — no Jest, Vitest, Playwright, or config for any of them. |

---

## 6. What the codebase does well

Worth stating plainly, since the findings above are heavily weighted toward problems:

- **`tsc --noEmit` passes clean under `strict: true`.** That is not common in a project of this size and reflects real discipline.
- **`src/app/api/products/route.ts` is genuinely well-written** — `VALID_SHOPS` / `VALID_SORT_FIELDS` allowlists, a proper `escapeRegex` helper, `Number.isFinite` guards on price parsing, and no unvalidated user input reaching the query object. It is the model the other routes should follow.
- **Password handling is correct** — bcrypt with a per-user salt in a `pre('save')` hook, `select: false` on the field, and a constant-time `bcrypt.compare`. The login handler returns an identical `"Invalid credentials"` for both unknown-email and wrong-password.
- **Consistent, sensible component architecture** — colocated `loading.tsx` / `error.tsx` per route segment, clean shadcn/ui primitives, coherent Tailwind design tokens.
- **`dbConnect` caches correctly** via the global, which is the right pattern for serverless/hot-reload Mongoose.
- **`api/singleProduct/[slug]/route.ts:20`** validates the ObjectId shape before calling `findById` — exactly the guard §4.6 asks for elsewhere. The knowledge is already in the codebase; it just needs applying consistently.

---

## 7. Suggested remediation order

**Phase 1 — Security (do before any further deployment)**
1. Rotate `JWT_SECRET` + `NEXTAUTH_SECRET`; untrack and purge `.env` (§2.1)
2. Delete `createCookies` / `getAuthToken`; rely on the `httpOnly` cookie (§2.2)
3. Remove the hardcoded `JWT_SECRET` fallback; fail closed (§2.6)
4. Guard or delete `POST /api/products/[productId]` (§2.3)
5. Fix the open redirect in `middleware.ts` and `LoginForm` (§3.1)
6. Strip token/payload/email logging (§3.3)
7. `npm uninstall next-auth jsonwebtoken @types/jsonwebtoken @types/react-redux`; upgrade `next` (§5.4, §5.5)

**Phase 2 — Commerce integrity**
8. Server-side pricing in the cart route (§2.4)
9. Server-side order construction and total calculation (§2.5)
10. Zod validation on every route that reads `request.json()` (§3.2)
11. Clear identity headers in middleware (§3.6)

**Phase 3 — Correctness**
12. Delete `src/app/orders/page.tsx` (§3.4)
13. Fix the logout path; wire up `/api/auth/logout` (§3.7)
14. Resolve the `populate` / `originalId` inconsistency (§3.5)
15. Fix model re-registration in `cart.ts` / `order.ts` (§4.1)
16. Move `localStorage` out of reducers; guard every `JSON.parse` (§4.2, §4.3)
17. Remove placeholder addresses from checkout (§5.1)

**Phase 4 — Quality & performance**
18. Server Components query the DB directly (§4.4)
19. Batch the N+1 product lookups (§4.5)
20. Delete `next.config.cjs`; settle on one lockfile (§4.9, §5.5)
21. Consolidate the duplicated type definitions (§4.12)
22. Tighten ESLint (`no-console`, `no-explicit-any`, `exhaustive-deps` as error) (§5.6p)
23. Introduce a test suite — start with the auth and order routes (§5.6q)

---

*Review covers application source only. Infrastructure code (Terraform, Kubernetes, Helm, ArgoCD, Jenkins) and all YAML were excluded by request and were neither read nor modified.*

---

# 8. Remediation Record

**Completed 2026-08-15.** Scope: all Critical, High and Medium findings. No Terraform or YAML file was touched.

## 8.1 Verification performed

| Gate | Result |
|---|---|
| `npx tsc --noEmit` | **exit 0**, clean |
| `npx next lint` | **exit 0** — "No ESLint warnings or errors" |
| `npm run build` | **exit 0** — all routes compiled, Next.js 14.2.35 |
| Runtime security suite (54 assertions) | **54 passed, 0 failed** |
| `npm audit --omit=dev` | 18 vulns → **4**; **3 criticals → 0** |

The runtime suite ran against a real instance (`next start`, MongoDB 7 in Docker, seeded
products and both a `user` and an `admin` account) and asserts the *exploit is closed*, not
merely that the code changed. Representative assertions:

- Posting `price: 0.01` for a $100 product to `/api/cart` → stored line price is **100**, total **200**.
- Posting `items:[{price:0.01}], total:0` to `/api/orders` → stored price **100**, total recomputed to **220**.
- `{"email":{"$ne":null}}` to `/api/auth/login` → **400**, no cookie issued.
- `POST /api/products/[productId]` → **405** (handler gone); `/api/products` → **401** anon, **403** non-admin, **201** admin.
- `?redirect=https://evil.example` → stays on-origin; `?redirect=/profile` still works.
- Forged `x-user-id: … / x-user-role: admin` headers → **401**.
- `Authorization: Bearer <valid token>` → **401** (header auth path removed).
- Login response body contains **no** `token` field; `Set-Cookie` is `HttpOnly` + `SameSite`.
- Weak `JWT_SECRET` ("tooshort") → login **500**, no token minted, explicit server-side error.
- Missing `MONGODB_URI` → **500** with explicit error, no silent localhost fallback.
- Server log after a full run: **6 lines**, **0** loopback requests to `:3000`, **0** JWTs.

## 8.2 Findings closed

**Critical** — §2.1 `.env` untracked + secrets regenerated + `.env.example` added (with a
`!.env.example` gitignore negation) · §2.2 `createCookies`/`getAuthToken`/Bearer path deleted;
cookie is httpOnly-only and the token no longer appears in any response body · §2.3 unauthenticated
`POST` handler deleted · §2.4 cart re-prices every line from the catalogue · §2.5 orders re-price
and recompute the total server-side · §2.6 `JWT_SECRET` (min 32 chars) and `MONGODB_URI` fail closed.

**High** — §3.1 open redirect fixed in middleware *and* `LoginForm` via a shared `safeRedirectPath`
· §3.2 Zod validation on every route that reads a body, plus `sanitizeFilter: true` · §3.3 all token,
payload, password-adjacent and email logging removed · §3.4 broken `/orders` page deleted · §3.5
`populate()` replaced with a batched `populateLineItems()` · §3.6 identity headers cleared before
forwarding · §3.7 one shared `useLogout()` across all three call sites · §3.8 `authenticated()` now
verifies the token; self-triggering effect fixed.

**Medium** — §4.1 model re-registration · §4.2/§4.3 `localStorage` moved out of reducers into
middleware with SSR-safe hydration and guarded `JSON.parse` · §4.4 Server Components query Mongo
directly via `lib/queries/products.ts` · §4.5 N+1 collapsed to one `$in` query · §4.6 ObjectId
validated → 400/404 · §4.7 typed error classes; internals no longer leak · §4.8 one shared cookie
config · §4.9 `next.config.cjs` deleted · §4.10 orders double-fetch fixed · §4.11 address forms use
`watch()` + `useCallback` · §4.12 type definitions de-duplicated.

Opportunistically also fixed: §5.1 placeholder addresses cleared, §5.2 demo credentials removed from
the login form, §5.6b pagination clamped, §5.6c/d page-size constants unified, §5.6e product body
allowlisted, §5.6f/g copy typos, §5.6h missing `type="password"`, §5.6m dead logout route now used.

**New files:** `lib/api/errors.ts`, `lib/auth/cookies.ts`, `lib/auth/safeRedirect.ts`,
`lib/auth/useLogout.ts`, `lib/validation/schemas.ts`, `lib/queries/products.ts`,
`lib/queries/populate.ts`, `lib/commerce/pricing.ts`, `lib/features/cart/persistence.ts`,
`components/forms/AddressForm.tsx`, `.env.example`.

**Deleted:** `src/app/orders/page.tsx`, `next.config.cjs`, the unauthenticated `POST` handler,
`createCookies`, `getAuthToken`.

## 8.3 Still open

1. **Purge `.env` from git history.** It is untracked going forward and the secrets in it have been
   replaced, but **the old values remain in every existing clone and in the history**. Treat them as
   compromised until you run `git filter-repo` (or BFG) and force-push. This needs a human decision —
   it rewrites history and requires coordinating with anyone holding a clone.
2. **4 High dependency CVEs remain**, all requiring breaking-change upgrades: `next` (DoS via Image
   Optimizer `remotePatterns` — *not exploitable here, no `remotePatterns` is configured*; needs
   Next 15), `sharp` (needs 0.35, libvips CVEs), `postcss`, and `glob` (dev tooling). Next.js was
   moved 14.1.0 → 14.2.35 within-major, which cleared the critical Server Actions SSRF.
3. **Low-severity items in §5 are untouched** — notably the non-functional Change Password and
   Profile forms (§5.3), which still submit to nothing. Their endpoints do not exist.
4. **Still no test suite** (§5.6q). The 54-assertion suite used here was a throwaway harness, not
   committed. Standing up Vitest around the auth and order routes remains the highest-value follow-up.
5. **Two lockfiles** (`package-lock.json` + `yarn.lock`) still coexist — pick one.
6. `src/app/api/products/books/route.ts` is now unused by the UI (its only caller, `BooksCategory`,
   queries Mongo directly). Kept as a public API endpoint; delete it if nothing external depends on it.
