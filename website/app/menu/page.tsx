import type { Metadata } from "next";
import { Suspense } from "react";
import { fetchPublicMenuSnapshot } from "@/lib/menu-server";
import MenuClient from "./menu-client";

export const metadata: Metadata = {
  title: "Menu & Ordering",
  description: "Browse the RastasperiQ menu, add to cart and order for pickup or delivery. Same kitchen, same prices as the app.",
  alternates: { canonical: "/menu/" },
};

// The first view is rendered from the restaurant's database (refreshed at most
// every five minutes); the browser then reloads the live menu in the background.
export const revalidate = 300;

export default async function MenuPage() {
  const snapshot = await fetchPublicMenuSnapshot();
  const initial =
    snapshot.items.length > 0 && snapshot.settings
      ? { items: snapshot.items, categories: snapshot.categories, appSettings: snapshot.settings }
      : null;
  return (
    <Suspense>
      <MenuClient initial={initial} />
    </Suspense>
  );
}
