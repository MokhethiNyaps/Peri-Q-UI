// Shared menu types + browser helpers (uses publishable key only)

import { createBrowserClient, readPublicSupabaseConfig } from "./supabase";

export type MenuItem = {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  imagePath: string;
  isAvailable: boolean;
  prepMinutes: number;
  spiceLevels: string[];
  addOns: { name: string; price: number }[];
};

export type MenuCategory = {
  id: string;
  name: string;
  sortOrder: number;
  isActive: boolean;
};

export type AppSettings = {
  storeOpen: boolean;
  pickupAvailable: boolean;
  deliveryAvailable: boolean;
  deliveryFee: number;
  openingTime: string; // HH:MM
  closingTime: string; // HH:MM
};

function imageUrlFor(path: unknown, supabaseUrl?: string): string {
  const value = typeof path === "string" ? path.trim() : "";
  if (!value) return "/white-app-icon.png";
  if (value.startsWith("https://")) return value;
  if (value.startsWith("assets/images/")) return "/white-app-icon.png";
  // menu-images storage public URL fallback: if we have supabaseUrl we can construct, else placeholder
  if (supabaseUrl && value.startsWith("menu/")) {
    return `${supabaseUrl.replace(/\/$/, "")}/storage/v1/object/public/menu-images/${value}`;
  }
  if (value.startsWith("menu/")) return "/white-app-icon.png";
  return value;
}

export async function fetchMenu(): Promise<{ items: MenuItem[]; categories: MenuCategory[]; appSettings: AppSettings }> {
  const cfg = readPublicSupabaseConfig();
  if (!cfg) {
    return { items: [], categories: [], appSettings: { storeOpen: true, pickupAvailable: true, deliveryAvailable: true, deliveryFee: 30, openingTime: "10:00", closingTime: "21:00" } };
  }
  const supa = createBrowserClient();
  const [itemsRes, catsRes, settingsRes] = await Promise.all([
    supa.from("menu_items").select("*").order("category").order("name"),
    supa.from("menu_categories").select("*").order("sort_order").order("name"),
    supa.from("app_settings").select("store_open,pickup_available,delivery_available,delivery_fee,opening_time,closing_time").eq("id", "default").maybeSingle(),
  ]);
  for (const result of [itemsRes, catsRes, settingsRes]) {
    if (result.error) throw result.error;
  }
  if (!settingsRes.data) throw new Error("Store settings are unavailable. Please try again later.");

  const items: MenuItem[] = ((itemsRes.data as unknown[]) ?? []).map((row: unknown) => mapMenuRow(row as Record<string, unknown>, cfg.url));
  const categories: MenuCategory[] = ((catsRes.data as unknown[]) ?? []).map((row: unknown) => mapCategoryRow(row as Record<string, unknown>));
  const s = settingsRes.data as Record<string, unknown> | null;
  const appSettings: AppSettings = s
    ? {
        storeOpen: (s["store_open"] as boolean) ?? true,
        pickupAvailable: (s["pickup_available"] as boolean) ?? true,
        deliveryAvailable: (s["delivery_available"] as boolean) ?? true,
        deliveryFee: Number(s["delivery_fee"] ?? 30),
        openingTime: (s["opening_time"] as string) ?? "10:00",
        closingTime: (s["closing_time"] as string) ?? "21:00",
      }
    : { storeOpen: true, pickupAvailable: true, deliveryAvailable: true, deliveryFee: 30, openingTime: "10:00", closingTime: "21:00" };

  return { items, categories, appSettings };
}

function mapMenuRow(row: Record<string, unknown>, supabaseUrl?: string): MenuItem {
  return {
    id: String(row["id"] ?? ""),
    name: String(row["name"] ?? ""),
    description: String(row["description"] ?? ""),
    price: Number(row["price"] ?? 0),
    category: String(row["category"] ?? ""),
    imagePath: imageUrlFor(row["image_path"] ?? row["imagePath"], supabaseUrl),
    isAvailable: (row["is_available"] as boolean) ?? (row["isAvailable"] as boolean) ?? true,
    prepMinutes: Number(row["prep_minutes"] ?? row["prepMinutes"] ?? 25),
    spiceLevels: (row["spice_levels"] as string[]) ?? (row["spiceLevels"] as string[]) ?? ["Mild","Medium","Hot","Extra Hot"],
    addOns: ((row["add_ons"] as unknown[]) ?? (row["addOns"] as unknown[]) ?? []).map((a: unknown) => {
      const o = a as Record<string, unknown>;
      return { name: String(o["name"] ?? ""), price: Number(o["price"] ?? 0) };
    }),
  };
}

function mapCategoryRow(row: Record<string, unknown>): MenuCategory {
  return {
    id: String(row["id"] ?? ""),
    name: String(row["name"] ?? ""),
    sortOrder: Number(row["sort_order"] ?? row["sortOrder"] ?? 0),
    isActive: (row["is_active"] as boolean) ?? (row["isActive"] as boolean) ?? true,
  };
}

export function isStoreOpenNow(settings: AppSettings, now = new Date()): boolean {
  if (!settings.storeOpen) return false;
  const minutes = (s: string) => {
    const parts = s.split(":");
    const h = parseInt(parts[0] ?? "0", 10);
    const m = parseInt(parts[1] ?? "0", 10);
    return (Math.min(23, Math.max(0, h)) * 60) + Math.min(59, Math.max(0, m));
  };
  const open = minutes(settings.openingTime);
  const close = minutes(settings.closingTime);
  const local = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Africa/Johannesburg", hour: "2-digit", minute: "2-digit", hourCycle: "h23",
  }).format(now);
  const cur = minutes(local);
  if (open === close) return true;
  if (open < close) return cur >= open && cur < close;
  return cur >= open || cur < close;
}

export function formatPrice(centsOrRand: number, asRands = true): string {
  const v = asRands ? centsOrRand : centsOrRand / 100;
  return `R${v.toFixed(2)}`.replace(/\.00$/, "");
}
