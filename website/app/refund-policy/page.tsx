import type { Metadata } from "next";
import Link from "next/link";
import { RotateCcw } from "lucide-react";
import { LegalPage, Pending } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Refund Policy",
  description: "When RastasperiQ gives refunds, how they are paid and how long they take.",
  alternates: { canonical: "/refund-policy/" },
};

export default function RefundPolicyPage() {
  return (
    <LegalPage
      title="Refund policy"
      href="/refund-policy/"
      icon={RotateCcw}
      intro="When we refund an order, how the money reaches you, and how long it takes."
    >
      <h2>1. When we refund</h2>
      <ul>
        <li>We cancel your paid order (for example, an item sold out or we cannot deliver): full refund.</li>
        <li>You were charged more than once for the same order: the extra payment is refunded.</li>
        <li>
          An item is missing, wrong, or not of acceptable quality: we will offer a replacement or a
          refund for the affected items. <Pending>how the restaurant decides between replacement and refund</Pending>
        </li>
        <li>You cancel an order: see our <Link href="/cancellation-policy/">cancellation policy</Link>.</li>
      </ul>
      <p>
        Your rights under the Consumer Protection Act, including the right to safe goods of good quality,
        are not limited by this policy.
      </p>

      <h2>2. How to ask for a refund</h2>
      <p>
        Contact us with your order number and what went wrong, as soon as possible and ideally on the day
        of the order. A photo helps us resolve food-quality issues quickly. See our{" "}
        <Link href="/complaints/">complaints procedure</Link>.
      </p>

      <h2>3. How refunds are paid</h2>
      <ul>
        <li>Refunds are paid to the card you used, through our payment provider Yoco. We do not refund in cash.</li>
        <li>We may refund the full amount or only the affected items.</li>
        <li>Your order shows as refunded once the full amount has been returned.</li>
      </ul>

      <h2>4. How long a refund takes</h2>
      <p>
        We aim to approve or decline a refund request within <Pending>number of days</Pending>. After we issue
        the refund, it usually takes <Pending>number of business days, per Yoco and the card issuer</Pending> to
        appear on your statement. This depends on your bank.
      </p>
    </LegalPage>
  );
}
