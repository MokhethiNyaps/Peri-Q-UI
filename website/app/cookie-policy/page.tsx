import type { Metadata } from "next";
import Link from "next/link";
import { Cookie } from "lucide-react";
import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Cookie and Storage Notice",
  description: "What the RastasperiQ website stores on your device and why.",
  alternates: { canonical: "/cookie-policy/" },
};

const stored = [
  { name: "Sign-in session (sb-…-auth-token)", why: "Keeps you signed in, or keeps your guest identifier so you can see your order.", until: "You sign out or clear your browser data." },
  { name: "Cart (peri_q_cart_v1)", why: "Remembers the items in your cart.", until: "You order, empty your cart, or clear your browser data." },
  { name: "Checkout details (peri_q_customer_v1)", why: "Fills in your name, phone, delivery address and order type next time.", until: "You sign out or clear your browser data." },
  { name: "Checkout in progress (peri_q_checkout_request, peri_q_pending_payment)", why: "Stops the same checkout being paid twice and clears your cart once payment is confirmed.", until: "The payment is confirmed or you clear your browser data." },
];

export default function CookiePolicyPage() {
  return (
    <LegalPage
      title="Cookies and storage"
      href="/cookie-policy/"
      icon={Cookie}
      intro="What the RastasperiQ website stores in your browser, why, and how to remove it."
    >
      <h2>1. Cookies</h2>
      <p>
        Our website does not set its own cookies, and we do not use advertising, analytics or tracking
        cookies. The secure payment page is run by our payment provider, Yoco, which may use its own
        cookies to process and secure your payment.
      </p>

      <h2>2. What we store in your browser</h2>
      <p>
        The website uses your browser&rsquo;s local storage, which stays on your device and is not sent to
        other websites. We store only what the ordering service needs:
      </p>
      <ul>
        {stored.map((item) => (
          <li key={item.name}>
            <strong>{item.name}:</strong> {item.why} Kept until: {item.until}
          </li>
        ))}
      </ul>
      <p>
        Because these items are needed for the service you ask for, we do not ask for separate consent to
        store them. Your checkout details include personal information, so do not save them on a shared
        device. Our <Link href="/privacy-policy/">privacy policy</Link> explains how we handle that information.
      </p>

      <h2>3. How to remove stored information</h2>
      <p>
        Sign out on the website to remove your session and saved checkout details. You can also clear this
        website&rsquo;s data in your browser settings at any time. The site will still work, but you will need
        to sign in and enter your details again.
      </p>
    </LegalPage>
  );
}
