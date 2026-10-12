import type { Metadata } from "next";
import MenuClient from "./menu-client";

export const metadata: Metadata = {
  title: "Menu & Ordering",
  description: "Browse the RastasperiQ menu, add to cart and order for pickup or delivery. Same kitchen, same prices as the app.",
  alternates: { canonical: "/menu/" },
};

export default function MenuPage() {
  return <MenuClient />;
}
