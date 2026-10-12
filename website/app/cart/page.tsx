import type { Metadata } from "next";
import CartClient from "./cart-client";

export const metadata: Metadata = {
  title: "Your Cart",
  description: "Review your RastasperiQ cart, adjust quantities, and proceed to checkout.",
  alternates: { canonical: "/cart/" },
};

export default function CartPage() {
  return <CartClient />;
}
