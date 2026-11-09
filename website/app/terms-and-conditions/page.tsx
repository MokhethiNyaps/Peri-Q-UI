import type { Metadata } from "next";
import Link from "next/link";
import { Scale } from "lucide-react";
import { BusinessDetails, LegalPage, Pending } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Terms and Conditions",
  description:
    "The terms that apply when you use the RastasperiQ website or Android app and order food.",
  alternates: { canonical: "/terms-and-conditions/" },
};

export default function TermsAndConditionsPage() {
  return (
    <LegalPage
      title="Terms and conditions"
      href="/terms-and-conditions/"
      icon={Scale}
      intro="The agreement between you and us when you use the RastasperiQ website or Android app and order food for collection or delivery."
    >
      <p className="text-lg !leading-8 text-charcoal">
        Please read these terms before you order. By placing an order you accept them. Nothing in these
        terms limits rights you have under the Consumer Protection Act or the Electronic Communications
        and Transactions Act that cannot legally be limited.
      </p>

      <h2>1. Who we are</h2>
      <BusinessDetails />

      <h2>2. Accounts and guest checkout</h2>
      <p>
        You can order as a guest or with an account. Give accurate contact details, keep your password
        private, and tell us straight away if you think someone else is using your account.
      </p>

      <h2>3. Menu, prices and availability</h2>
      <ul>
        <li>Prices are in South African rand and include <Pending>whether prices include VAT</Pending>.</li>
        <li>Delivery, where available, costs the delivery fee shown at checkout before you pay.</li>
        <li>Menu items, photos and descriptions are a guide. Portions and presentation may vary slightly.</li>
        <li>
          Items can sell out. If a price or item changes while you are ordering, checkout stops and shows
          you the updated total before you pay.
        </li>
      </ul>

      <h2>4. Allergens and food information</h2>
      <p>
        Our food is prepared in a kitchen that also handles other ingredients, so we cannot guarantee
        that any item is free from a particular allergen.{" "}
        <Pending>allergen and ingredient information for each menu item, and any certification
        (for example halaal), supplied by the restaurant</Pending>
      </p>
      <p>
        If you have an allergy or dietary requirement, contact us before you order. Order notes are
        read by the kitchen, but they are not a guarantee.
      </p>

      <h2>5. How an order is made</h2>
      <ol className="mt-4 grid list-decimal gap-2 pl-5">
        <li>You choose your items, collection or delivery, and enter your details.</li>
        <li>Checkout shows your items, the delivery fee if any, and the total. Check them; you can go back and change them before you pay.</li>
        <li>You pay by card on our payment provider&rsquo;s secure page.</li>
        <li>
          <strong>Your order is accepted, and the agreement is formed, when the payment is confirmed</strong> and
          the order appears in your order history. If the payment fails or you cancel it, no order is
          placed and you are not charged.
        </li>
      </ol>
      <p>
        Estimated preparation and delivery times are estimates, not guarantees. They can change with
        demand, traffic and weather.
      </p>

      <h2>6. Payment</h2>
      <p>
        You pay in full by card before we prepare your order. Read our{" "}
        <Link href="/payment-policy/">payment policy</Link>.
      </p>

      <h2>7. Collection and delivery</h2>
      <ul>
        <li>Collection: collect your order from the store once it is marked ready. <Pending>how long uncollected orders are kept</Pending></li>
        <li>
          Delivery: give a complete, accurate address and keep your phone on. Delivery area:{" "}
          <Pending>delivery area</Pending>. <Pending>what happens if the driver cannot reach you</Pending>
        </li>
      </ul>

      <h2>8. Cancellations and refunds</h2>
      <p>
        See our <Link href="/cancellation-policy/">cancellation policy</Link> and{" "}
        <Link href="/refund-policy/">refund policy</Link>. Prepared food is perishable, so the
        cooling-off period for online purchases does not apply to it.{" "}
        <Pending>attorney to confirm that ECTA section 42 excludes prepared food</Pending>
      </p>

      <h2>9. Problems with your order</h2>
      <p>
        If something is missing, wrong or not of acceptable quality, tell us as soon as possible,
        ideally while you still have the food. Follow our{" "}
        <Link href="/complaints/">complaints procedure</Link>.
      </p>

      <h2>10. Acceptable use</h2>
      <p>
        Do not misuse the service: no fraudulent orders or payments, attempts to access other people&rsquo;s
        accounts or our systems, interference with the service, or impersonation of another person. We may
        suspend accounts used in these ways.
      </p>

      <h2>11. Service availability</h2>
      <p>
        We aim to keep the website and app available, but we cannot guarantee they will always work.
        Maintenance, network failures or provider outages can interrupt them.
      </p>

      <h2>12. Our responsibility to you</h2>
      <p>
        <Pending>limitation-of-liability wording, for attorney drafting in line with the Consumer
        Protection Act</Pending>
      </p>

      <h2>13. Privacy</h2>
      <p>
        Our <Link href="/privacy-policy/">privacy policy</Link> explains how we handle your personal
        information.
      </p>

      <h2>14. Changes to these terms</h2>
      <p>
        We may update these terms. The terms that apply to an order are the ones shown when you placed
        it. The version label at the top shows the current version.
      </p>

      <h2>15. Governing law and disputes</h2>
      <p>
        South African law applies to these terms. You can also take a dispute to the Consumer Goods and
        Services Ombud or the National Consumer Commission, as explained in our{" "}
        <Link href="/complaints/">complaints procedure</Link>.
      </p>
    </LegalPage>
  );
}
