import { describe, expect, it } from "vitest";
import { visibleCategories, type MenuCategory, type MenuItem } from "../lib/menu";
import { plateCutoutFor } from "../lib/plates";
import manifest from "../public/plates/manifest.json";

const item = (id: string, category: string): MenuItem => ({
  id,
  name: id,
  description: "",
  price: 45,
  category,
  imagePath: "",
  isAvailable: true,
  prepMinutes: 25,
  spiceLevels: ["Mild"],
  addOns: [],
});

const category = (name: string, sortOrder: number, isActive = true): MenuCategory => ({
  id: name,
  name,
  sortOrder,
  isActive,
});

describe("visibleCategories", () => {
  it("hides categories with no items and keeps the restaurant's order", () => {
    const categories = [category("Combo Plates", 10), category("Wors Meals", 20), category("Liver Meals", 50), category("Sides", 80)];
    const items = [item("a", "Liver Meals"), item("b", "Combo Plates")];
    expect(visibleCategories(categories, items)).toEqual(["Combo Plates", "Liver Meals"]);
  });

  it("never hides a dish: categories that hold items always get a tab, catalogue ones first", () => {
    const categories = [category("Liver Meals", 50), category("Combo Plates", 10, false)];
    const items = [item("a", "Combo Plates"), item("b", "Specials"), item("c", "Liver Meals")];
    expect(visibleCategories(categories, items)).toEqual(["Liver Meals", "Combo Plates", "Specials"]);
  });
});

describe("plateCutoutFor", () => {
  const host = "https://example.supabase.co/storage/v1/object/public/menu-images/menu/";

  it("uses a cut-out only for the exact stored photo it was made from", () => {
    const [stored, entry] = Object.entries(manifest)[0];
    expect(plateCutoutFor(host + stored)).toBe(`/plates/${entry.file}`);
  });

  it("falls back to the photo for any other image", () => {
    expect(plateCutoutFor(host + "1999999999999-new-photo.jpg")).toBeNull();
    expect(plateCutoutFor("/white-app-icon.png")).toBeNull();
    expect(plateCutoutFor("")).toBeNull();
  });

  it("never maps a retired July 2026 photo", () => {
    expect(Object.keys(manifest).some((name) => name.includes("20260728"))).toBe(false);
  });
});
