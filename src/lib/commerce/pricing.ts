/**
 * Order pricing constants. The server is authoritative: the checkout UI reads
 * these same values so the figure a customer sees always matches the figure the
 * order is created with.
 */
export const SHIPPING_FEE = 10;
export const TAX_FEE = 10;

export function roundCurrency(value: number): number {
  return Math.round(value * 100) / 100;
}

export function calculateSubtotal(
  items: { price: number; quantity: number }[]
): number {
  return roundCurrency(
    items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  );
}

export function calculateOrderTotal(
  items: { price: number; quantity: number }[]
): number {
  return roundCurrency(calculateSubtotal(items) + SHIPPING_FEE + TAX_FEE);
}
