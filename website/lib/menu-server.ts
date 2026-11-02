import { createClient } from "@supabase/supabase-js";
import {
  imageUrlFor,
  mapCategoryRow,
  mapMenuRow,
  type AppSettings,
  type MenuCategory,
  type MenuItem,
} from "./menu";
import { readPublicSupabaseConfig } from "./supabase";

export type TodaysSpecial = {
  label: string;
  title: string;
  subtitle: string;
  imageUrl: string;
  menuItemId: string | null;
};

export type PublicMenuSnapshot = {
  items: MenuItem[];
  categories: MenuCategory[];
  settings: AppSettings | null;
  special: TodaysSpecial | null;
};

const EMPTY: PublicMenuSnapshot = { items: [], categories: [], settings: null, special: null };

/**
 * Read-only snapshot of the public menu for server rendering. Uses the same
 * publishable key and tables as the browser and the app, so prices and items
 * always come from the restaurant's database. Returns an empty snapshot (and
 * the page falls back to client loading) when Supabase is not configured or
 * unreachable.
 */
export async function fetchPublicMenuSnapshot(): Promise<PublicMenuSnapshot> {
  const config = readPublicSupabaseConfig();
  if (!config) return EMPTY;
  try {
    const supabase = createClient(config.url, config.publishableKey, {
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    });
    const [itemsRes, categoriesRes, settingsRes] = await Promise.all([
      supabase.from("menu_items").select("*").order("category").order("name"),
      supabase.from("menu_categories").select("*").order("sort_order").order("name"),
      supabase.from("app_settings").select("*").eq("id", "default").maybeSingle(),
    ]);
    if (itemsRes.error || categoriesRes.error || settingsRes.error) return EMPTY;

    const items = ((itemsRes.data ?? []) as Record<string, unknown>[]).map((row) =>
      mapMenuRow(row, config.url),
    );
    const categories = ((categoriesRes.data ?? []) as Record<string, unknown>[]).map(mapCategoryRow);
    const s = settingsRes.data as Record<string, unknown> | null;

    const settings: AppSettings | null = s
      ? {
          storeOpen: (s["store_open"] as boolean) ?? true,
          pickupAvailable: (s["pickup_available"] as boolean) ?? true,
          deliveryAvailable: (s["delivery_available"] as boolean) ?? true,
          deliveryFee: Number(s["delivery_fee"] ?? 30),
          openingTime: String(s["opening_time"] ?? "10:00"),
          closingTime: String(s["closing_time"] ?? "21:00"),
        }
      : null;

    const specialImage = imageUrlFor(s?.["todays_special_image_path"], config.url);
    const special: TodaysSpecial | null =
      s && s["todays_special_enabled"] !== false && specialImage !== "/white-app-icon.png"
        ? {
            label: String(s["todays_special_label"] || "Today's special"),
            title: String(s["todays_special_title"] || "Fresh from the flame"),
            subtitle: String(s["todays_special_subtitle"] || ""),
            imageUrl: specialImage,
            menuItemId: typeof s["todays_special_menu_item_id"] === "string" ? (s["todays_special_menu_item_id"] as string) : null,
          }
        : null;

    return { items, categories, settings, special };
  } catch {
    return EMPTY;
  }
}
