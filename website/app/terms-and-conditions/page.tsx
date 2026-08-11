import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeft, Mail, MessageCircle, Scale } from "lucide-react";
import { mailtoUrl, siteConfig } from "@/lib/site";

export const metadata: Metadata = {
  title: "Terms and Conditions",
  description:
    "Terms for using the RastasperiQ mobile ordering app and related services.",
  alternates: { canonical: "/terms-and-conditions/" },
};

export default function TermsAndConditionsPage() {
  return (
    <main id="main-content" className="bg-cream">
      <header className="relative isolate overflow-hidden bg-charcoal py-16 text-white sm:py-24">
        <div className="hero-grid absolute inset-0 -z-20 opacity-60" />
        <div className="absolute -right-20 -top-32 -z-10 size-[30rem] rounded-full bg-peri-red/25 blur-3xl" />
        <div className="policy-shell">
          <Link
            href="/"
            className="inline-flex items-center gap-2 text-sm font-bold text-white/60 transition-colors hover:text-white"
          >
            <ArrowLeft size={17} aria-hidden="true" />
            Back to home
          </Link>
          <div className="mt-10 max-w-4xl">
            <span className="grid size-14 place-items-center rounded-2xl bg-peri-red text-white shadow-xl">
              <Scale size={25} aria-hidden="true" />
            </span>
            <h1 className="mt-7 font-display text-5xl font-black uppercase leading-[0.88] tracking-[-0.05em] sm:text-7xl lg:text-8xl">
              Terms and conditions
            </h1>
            <p className="mt-7 max-w-2xl text-base leading-8 text-white/65 sm:text-lg">
              These terms explain the basic rules for using the RastasperiQ
              ordering app and related customer services.
            </p>
            <div className="mt-8 inline-flex items-center rounded-full border border-white/12 bg-white/7 px-4 py-2 text-xs font-bold text-white/70">
              Effective date: 27 July 2026
            </div>
          </div>
        </div>
      </header>

      <div className="policy-shell py-14 lg:py-20">
        <article className="policy-content mx-auto max-w-3xl">
          <p className="!mt-0 text-lg !leading-8 text-charcoal">
            By using the app or placing an order, you agree to these terms. If you do
            not agree, please do not use the ordering service.
          </p>

          <h2>1. About the service</h2>
          <p>
            The app is operated by <strong>RastasperiQ</strong> at {" "}
            {siteConfig.address}. It allows customers to browse menu information, place
            pickup or delivery orders when available, submit payment information, and
            follow order status.
          </p>

          <h2>2. Accounts and guest checkout</h2>
          <p>
            You may use guest checkout or create an account. You are responsible for
            providing accurate contact information and keeping account credentials
            confidential. Tell us promptly if you believe your account is being used
            without permission.
          </p>

          <h2>3. Menu information and availability</h2>
          <p>
            Menu items, prices, operating hours, preparation estimates, delivery options,
            and availability may change. An item shown in the app may become unavailable
            before an order is accepted. The amount confirmed during checkout is the amount
            used for the order unless we contact you about an agreed change.
          </p>

          <h2>4. Orders</h2>
          <p>
            Check your items, contact details, fulfilment choice, delivery address, and
            notes before submitting. An order is subject to store availability and
            confirmation. Please contact the store immediately if you submitted incorrect
            information; changes may not be possible after preparation begins.
          </p>

          <h2>5. Payment</h2>
          <p>
            Available payment methods are shown during checkout. If you choose EFT, you
            may be asked to upload proof so staff can reconcile payment. Do not upload card
            numbers, passwords, or unrelated documents. Card payment is not processed by
            the current app unless the checkout screen explicitly states otherwise.
          </p>

          <h2>6. Pickup and delivery</h2>
          <p>
            Pickup and delivery availability depends on store settings and operating
            conditions. Delivery customers must provide a complete, accurate address and
            remain reachable using the supplied phone number. Preparation and delivery
            times are estimates and can be affected by order volume, traffic, weather, or
            other circumstances.
          </p>

          <h2>7. Cancellations, problems, and refunds</h2>
          <p>
            Contact us as soon as possible if you need to cancel or report a problem.
            Cancellations may not be available once preparation has started. Refund or
            replacement requests are reviewed according to the order circumstances and
            applicable South African consumer law.
          </p>

          <h2>8. Acceptable use</h2>
          <p>
            You must not misuse the app, attempt unauthorised access, interfere with the
            service, submit fraudulent orders or payment proof, impersonate another person,
            or use the service in a way that violates applicable law.
          </p>

          <h2>9. Service availability</h2>
          <p>
            We aim to keep the app available, but uninterrupted operation cannot be
            guaranteed. Maintenance, network failures, provider outages, or security work
            may temporarily limit access. Where practical, the app may show the last saved
            menu while a connection is unavailable.
          </p>

          <h2>10. Privacy and account deletion</h2>
          <p>
            Our <Link href="/privacy-policy/">Privacy Policy</Link> explains how information
            is handled. You can delete an eligible account in the app or use the public {" "}
            <Link href="/delete-account/">account-deletion page</Link> if you cannot access
            the app.
          </p>

          <h2>11. Changes to these terms</h2>
          <p>
            We may update these terms when the service or legal requirements change. The
            effective date above identifies the current version. Continued use after an
            update means the revised terms apply to later use and orders.
          </p>

          <h2>12. Contact</h2>
          <p>Contact the team if you have a question about these terms or an order.</p>
          <div className="mt-7 grid gap-3 sm:grid-cols-2">
            <a href={mailtoUrl} className="policy-card !no-underline">
              <Mail className="text-peri-red" size={21} aria-hidden="true" />
              <span className="mt-4 block text-xs font-black uppercase tracking-[0.14em] text-ash">
                Email
              </span>
              <span className="mt-1 block break-all text-sm font-extrabold text-charcoal">
                {siteConfig.email}
              </span>
            </a>
            <a
              href={siteConfig.whatsappUrl}
              target="_blank"
              rel="noreferrer"
              className="policy-card !no-underline"
            >
              <MessageCircle className="text-peri-red" size={21} aria-hidden="true" />
              <span className="mt-4 block text-xs font-black uppercase tracking-[0.14em] text-ash">
                WhatsApp
              </span>
              <span className="mt-1 block text-sm font-extrabold text-charcoal">
                {siteConfig.phones[0]}
              </span>
            </a>
          </div>
        </article>
      </div>
    </main>
  );
}
