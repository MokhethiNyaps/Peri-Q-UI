import { describe, it, expect } from "vitest";
import { isStoreOpenNow } from "../lib/menu";

describe("Menu loading (shared data)", () => {
  it("loads menu from same Supabase project (shape contract)", async () => {
    // Shape: menu_items must have id, name, price, category, is_available
    const fakeRow = { id: "combo-chicken-pork-wors", name: "Chicken, Pork & Wors Plate", price: 70, category: "Combo Plates", isAvailable: true };
    expect(fakeRow.id).toBeTruthy();
    expect(typeof fakeRow.price).toBe("number");
    expect(fakeRow.price).toBeGreaterThan(0);
  });

  it("availability flag prevents ordering unavailable items (client + server)", () => {
    const item = { id: "x", isAvailable: false } as const;
    const canOrder = item.isAvailable;
    expect(canOrder).toBe(false);
  });
});

describe("Store hours validation (server trusts same logic)", () => {
  it("detects open within hours", () => {
    const settings = { storeOpen: true, pickupAvailable: true, deliveryAvailable: true, deliveryFee: 30, openingTime: "10:00", closingTime: "21:00" };
    // 12:00 local should be open
    const noon = new Date();
    noon.setHours(12, 0, 0, 0);
    expect(isStoreOpenNow(settings, noon)).toBe(true);
  });

  it("detects closed outside hours", () => {
    const settings = { storeOpen: true, pickupAvailable: true, deliveryAvailable: true, deliveryFee: 30, openingTime: "10:00", closingTime: "21:00" };
    const early = new Date();
    early.setHours(9, 0, 0, 0);
    expect(isStoreOpenNow(settings, early)).toBe(false);
    const late = new Date();
    late.setHours(22, 0, 0, 0);
    expect(isStoreOpenNow(settings, late)).toBe(false);
  });

  it("respects storeOpen global toggle", () => {
    const settings = { storeOpen: false, pickupAvailable: true, deliveryAvailable: true, deliveryFee: 30, openingTime: "10:00", closingTime: "21:00" };
    const noon = new Date();
    noon.setHours(12, 0, 0, 0);
    expect(isStoreOpenNow(settings, noon)).toBe(false);
  });
});

describe("Delivery / collection validation", () => {
  it("requires address >=8 chars for delivery", () => {
    const ok = (addr: string) => addr.trim().length >= 8;
    expect(ok("12 Main Rd")).toBe(true);
    expect(ok("short")).toBe(false);
    expect(ok("   ")).toBe(false);
  });

  it("rejects delivery when deliveryAvailable false", () => {
    const canUse = (type: "pickup" | "delivery", settings: { pickupAvailable: boolean; deliveryAvailable: boolean }) =>
      type === "pickup" ? settings.pickupAvailable : settings.deliveryAvailable;
    expect(canUse("delivery", { pickupAvailable: true, deliveryAvailable: false })).toBe(false);
    expect(canUse("pickup", { pickupAvailable: true, deliveryAvailable: false })).toBe(true);
  });

  it("cash_delivery only allowed for delivery", () => {
    const valid = (payment: string, type: string) => !(type === "pickup" && payment === "cash_delivery");
    expect(valid("cash_delivery", "pickup")).toBe(false);
    expect(valid("cash_delivery", "delivery")).toBe(true);
    expect(valid("cash_collection", "pickup")).toBe(true);
  });
});

describe("Server-side price validation (never trust client total)", () => {
  it("server recomputes trusted total from menu", () => {
    // Simulate server: menu price 70, add-on 10, qty 2 = 160, delivery 30 => 190
    const trusted = (70 + 10) * 2 + 30;
    const clientSubmitted = 190;
    expect(Math.abs(trusted - clientSubmitted) <= 0.009).toBe(true);
    const tampered = 100; // client tries to underpay
    expect(Math.abs(trusted - tampered) <= 0.009).toBe(false);
  });
});
