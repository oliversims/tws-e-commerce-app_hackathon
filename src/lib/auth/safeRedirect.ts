/**
 * Accepts only same-origin, non-protocol-relative paths.
 *
 * `router.replace(target)` and `new URL(target, base)` both happily follow an
 * absolute URL, so an unchecked `?redirect=` value turns the login flow into an
 * open redirect that phishing pages can use with our domain in the referrer.
 */
export function safeRedirectPath(
  target: string | null | undefined,
  fallback = "/"
): string {
  if (!target) return fallback;
  if (!target.startsWith("/")) return fallback;
  if (target.startsWith("//")) return fallback;
  if (target.startsWith("/\\")) return fallback;
  return target;
}
