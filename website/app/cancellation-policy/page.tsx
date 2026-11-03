import type { Metadata } from "next";
import Link from "next/link";
import { CircleX } from "lucide-react";
import { LegalPage, Pending } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Cancellation Policy",
  description: "When and how a RastasperiQ order can be cancelled.",
  alternates: { canonical: "/cancellation-policy/" },
};

export default function CancellationPolicyPage() {
  return (
    <LegalPage
      title="Cancellation policy"
      href="/cancellation-policy/"
      icon={CircleX}
      intro="When you can cancel an order, when we may cancel it, and what happens to your payment."
    >
      <h2>1. Before you pay</h2>
      <p>
        You can change or leave your cart at any time before you complete the payment. Nothing is ordered
        and nothing is charged until the payment is confirmed.
      </p>

      <h2>2. Cancelling a paid order</h2>
      <ul>
        <li>
          Contact us as soon as possible by phone or WhatsApp, with your order number. You cannot yet
          cancel a paid order yourself in the app or on the website.
        </li>
        <li>
          While your order is still <strong>pending</strong> (we have not started preparing it):{" "}
          <Pending>whether customers can cancel for a full refund</Pending>
        </li>
        <li>
          Once your order is <strong>being prepared</strong>, the food is made to order and is perishable:{" "}
          <Pending>whether a cancellation is still possible, and any refund</Pending>
        </li>
      </ul>

      <h2>3. When we may cancel</h2>
      <p>We may cancel a paid order if, for example:</p>
      <ul>
        <li>an item sold out after you paid;</li>
        <li>we cannot deliver to your address or cannot reach you; or</li>
        <li>the store had to close unexpectedly.</li>
      </ul>
      <p>
        If we cancel your order, we tell you and refund the full amount to your card. See our{" "}
        <Link href="/refund-policy/">refund policy</Link>.
      </p>

      <h2>4. Orders that are not collected</h2>
      <p>
        <Pending>how long a collection order is kept, and whether an uncollected order is refunded</Pending>
      </p>
    </LegalPage>
  );
}
