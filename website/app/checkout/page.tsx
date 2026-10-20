import type { Metadata } from "next";
import CheckoutClient from "./checkout-client";

export const metadata: Metadata = {
  title: "Checkout",
  description: "Enter your details, choose pickup or delivery, and pay by card before your order is placed.",
  alternates: { canonical: "/checkout/" },
};

export default function CheckoutPage() {
  return <CheckoutClient />;
}

