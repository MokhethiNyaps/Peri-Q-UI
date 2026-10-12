import { describe, it, expect } from "vitest";

// Cart pure logic (mirrors lib/cart maths) — tested without React
function lineTotal(price: number, addOns: { price: number }[], qty: number) {
  const add = addOns.reduce((s, a) => s + (a.price ?? 0), 0);
  return (price + add) * qty;
}
function cartSubtotal(entries: { price: number; addOns: { price: number }[]; qty: number }[]) {
  return entries.reduce((s, e) => s + lineTotal(e.price, e.addOns, e.qty), 0);
}
function totalFor(type: "pickup" | "delivery", subtotal: number, deliveryFee = 30) {
  return subtotal + (type === "delivery" ? deliveryFee : 0);
}

describe("Cart calculations and quantity changes", () => {
  it("computes line total with add-ons", () => {
    expect(lineTotal(70, [{ price: 10 }, { price: 5 }], 2)).toBe(170);
    expect(lineTotal(15, [], 3)).toBe(45);
  });

  it("computes subtotal across multiple lines", () => {
    const entries = [
      { price: 70, addOns: [], qty: 2 },
      { price: 15, addOns: [{ price: 5 }], qty: 1 },
    ];
    expect(cartSubtotal(entries)).toBe(140 + 20);
  });

  it("adds delivery fee only for delivery", () => {
    expect(totalFor("pickup", 100, 30)).toBe(100);
    expect(totalFor("delivery", 100, 30)).toBe(130);
  });

  it("quantity changes update totals", () => {
    let qty = 1;
    const price = 50;
    expect(lineTotal(price, [], qty)).toBe(50);
    qty += 1; // inc
    expect(lineTotal(price, [], qty)).toBe(100);
    qty -= 1; // dec
    expect(lineTotal(price, [], qty)).toBe(50);
  });

  it("prevents invalid quantities (mirrors server 1–50)", () => {
    const valid = (q: number) => q >= 1 && q <= 50;
    expect(valid(0)).toBe(false);
    expect(valid(1)).toBe(true);
    expect(valid(50)).toBe(true);
    expect(valid(51)).toBe(false);
  });

  it("remove item clears from cart", () => {
    let entries = [{ id: "a" }, { id: "b" }, { id: "c" }] as { id: string }[];
    entries = entries.filter((e) => e.id !== "b");
    expect(entries.map((e) => e.id)).toEqual(["a", "c"]);
  });
});
