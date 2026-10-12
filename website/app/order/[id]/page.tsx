import type { Metadata } from "next";
import OrderClient from "./order-client";

export const metadata: Metadata = {
  title: "Your Order",
  description: "Track your RastasperiQ order status, payment, and receipt.",
};

export default async function OrderPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <OrderClient orderId={id} />;
}
