import type { Metadata } from "next";
import Link from "next/link";
import { CreditCard } from "lucide-react";
import { LegalPage } from "@/components/legal-page";
import { business } from "@/lib/legal";

export const metadata: Metadata = {
  title: "Payment Policy",
  description: "How card payments work on the RastasperiQ website and app.",
  alternates: { canonical: "/payment-policy/" },
};

export default function PaymentPolicyPage() {
  return (
    <LegalPage
      title="Payment policy"
      href="/payment-policy/"
      icon={CreditCard}
      intro="How you pay for orders on the RastasperiQ website and app, when you are charged, and what happens if something goes wrong."
    >
      <h2>1. How you pay</h2>
      <ul>
        <li>Online orders are paid in full, by card, before we start preparing them.</li>
        <li>All amounts are in South African rand (ZAR).</li>
        <li>
          Card payments are processed by <strong>Yoco</strong>, a South African payment provider, on its
          own secure payment page. The payment is made to {business.legalName}.
        </li>
        <li>Your card details go directly to Yoco. We never see or store your card number, expiry date or security code.</li>
      </ul>

      <h2>2. When you are charged</h2>
      <p>
        You are charged once, when you complete the payment on the secure payment page. The amount is the
        total shown at checkout, which our server calculates from current menu prices and the delivery fee.
      </p>

      <h2>3. When your order is placed</h2>
      <p>
        We create your order only after Yoco confirms the payment to our server. The confirmation page in
        your browser or app is not proof of payment on its own. Your order appears in your order history
        once the payment is confirmed, usually within seconds.
      </p>

      <h2>4. If a payment fails or you cancel it</h2>
      <ul>
        <li>No order is placed and you are not charged.</li>
        <li>Your cart is kept, so you can try again.</li>
        <li>
          Check your order history before you pay again. If you think you were charged without an order
          appearing, contact us and do not pay a second time.
        </li>
      </ul>

      <h2>5. Paying twice by mistake</h2>
      <p>
        Our system is designed to create only one order for each payment. If you are charged twice for the
        same order, contact us and we will refund the extra payment, as set out in our{" "}
        <Link href="/refund-policy/">refund policy</Link>.
      </p>

      <h2>6. Refunds</h2>
      <p>
        Approved refunds are paid back to the card you used, through Yoco. See our{" "}
        <Link href="/refund-policy/">refund policy</Link>.
      </p>

      <h2>7. Security</h2>
      <p>
        Payment pages use encrypted connections, and our server verifies every payment notification it
        receives from Yoco before it accepts it. We limit repeated payment attempts to prevent abuse.
      </p>
    </LegalPage>
  );
}
