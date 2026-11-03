import type { Metadata } from "next";
import Link from "next/link";
import { ShieldCheck } from "lucide-react";
import { BusinessDetails, Fact, LegalPage, Pending } from "@/components/legal-page";
import { business } from "@/lib/legal";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "How RastasperiQ collects, uses, shares and protects personal information on its website and Android app.",
  alternates: { canonical: "/privacy-policy/" },
};

export default function PrivacyPolicyPage() {
  return (
    <LegalPage
      title="Privacy policy"
      href="/privacy-policy/"
      icon={ShieldCheck}
      intro="How we collect, use, share and protect your personal information when you use the RastasperiQ website or Android app, and the rights you have under the Protection of Personal Information Act (POPIA)."
    >
      <h2>1. Who is responsible</h2>
      <p>
        The responsible party for your personal information is the company below. In this policy,
        &ldquo;we&rdquo; and &ldquo;us&rdquo; mean that company.
      </p>
      <BusinessDetails />
      <p>
        <strong>Information Officer:</strong>{" "}
        <Fact value={business.informationOfficer} missing="name and contact details of the Information Officer" />
      </p>

      <h2>2. Information we collect</h2>
      <h3>When you create an account</h3>
      <ul>
        <li>Your name, email address and phone number.</li>
        <li>Your password. It is stored only in hashed form by our authentication provider, and we cannot read it.</li>
      </ul>
      <h3>When you order</h3>
      <ul>
        <li>Your name and phone number, so we can identify your order and contact you about it.</li>
        <li>Your delivery address, only if you choose delivery.</li>
        <li>The items, quantities, spice levels, add-ons and any notes you add, the total, and the times your order was placed and updated.</li>
        <li>
          Payment references from our card payment provider, such as the payment ID, amount and payment
          status. <strong>We never receive or store your card number, expiry date or security code.</strong>
        </li>
      </ul>
      <h3>When you check out as a guest</h3>
      <p>
        We create an anonymous account identifier so that only you can see your order. It does not
        contain your name or email address.
      </p>
      <h3>When you use the Android app</h3>
      <ul>
        <li>
          If you allow notifications, a notification token for your device and an installation
          identifier, so we can tell you when your order status changes.
        </li>
        <li>Your saved details and delivery addresses, stored securely on your phone for convenience.</li>
      </ul>
      <h3>When you use the website</h3>
      <p>
        The website stores your sign-in session, your cart and your checkout details (name, phone,
        address and order type) in your browser so they are there when you return. See our{" "}
        <Link href="/cookie-policy/">cookie and storage notice</Link>.
      </p>
      <h3>When you contact us</h3>
      <p>Anything you send us by email, phone or WhatsApp.</p>
      <h3>What we do not collect</h3>
      <p>
        We do not use advertising or analytics tools, and we do not collect your precise location,
        contacts, photos, SMS messages or call logs. Our hosting and payment providers keep technical
        records, such as IP addresses, to run and secure their services.
      </p>

      <h2>3. Health and other sensitive information</h2>
      <p>
        Please do not include health, religious or other sensitive details in order notes unless they
        are needed to prepare your food. If you tell us about an allergy or dietary need, we use it
        only to prepare that order. Read the allergen information in our{" "}
        <Link href="/terms-and-conditions/">terms and conditions</Link> before you order.
      </p>

      <h2>4. Why we use your information</h2>
      <ul>
        <li><strong>To take, prepare, deliver and support your order</strong> (needed to perform our agreement with you).</li>
        <li><strong>To take payment and handle refunds</strong> (needed to perform the agreement, and to keep financial records the law requires).</li>
        <li><strong>To run your account and keep it secure</strong> (needed to perform the agreement, and our legitimate interest in preventing fraud and misuse).</li>
        <li><strong>To send order-status notifications</strong> (only if you allow notifications on your device).</li>
        <li><strong>To answer your questions and complaints</strong> (our legitimate interest and, where it applies, legal obligation).</li>
      </ul>
      <p>We do not sell your personal information, and we do not send marketing messages.</p>

      <h2>5. Who receives your information</h2>
      <p>Only people and service providers that need it to provide the service:</p>
      <ul>
        <li><strong>Our staff and delivery personnel</strong>, to prepare and deliver your order.</li>
        <li><strong>Supabase</strong>: database, sign-in, file storage and server functions. Data is hosted in {business.dataRegion}.</li>
        <li><strong>Vercel</strong>: hosts the website and its payment server. Server region: <Pending>Vercel server region</Pending>.</li>
        <li><strong>Yoco</strong>: processes card payments on its own secure payment page. Yoco receives the amount and our order reference; your card details go directly to Yoco.</li>
        <li><strong>Google Firebase Cloud Messaging</strong>: delivers app notifications. Restaurant staff notifications include the customer&rsquo;s name and order total.</li>
        <li><strong>Google Play</strong>: distributes the Android app.</li>
        <li><strong>WhatsApp and our email provider</strong>: if you choose to contact us that way.</li>
        <li><strong>Authorities</strong>, where the law requires us to share information.</li>
      </ul>
      <p>
        These providers act on our instructions. <Pending>confirmation that operator agreements or
        data-processing terms are in place with each provider</Pending>
      </p>

      <h2>6. Information sent outside South Africa</h2>
      <p>
        Our database is hosted in Ireland, and some providers (such as Google and Vercel) may process
        information in other countries. We send information abroad only as POPIA section 72 allows.{" "}
        <Pending>the legal basis for each cross-border transfer, for attorney review</Pending>
      </p>

      <h2>7. How we protect your information</h2>
      <ul>
        <li>Encrypted connections (HTTPS) between your device, our website, our app and our providers.</li>
        <li>Database access rules that let customers see only their own orders and account.</li>
        <li>Prices and payments are checked on our server, and an order is created only after the payment provider confirms payment.</li>
        <li>Your app sign-in is kept in your phone&rsquo;s secure storage, and app backups to the cloud are switched off.</li>
        <li>Limits on repeated payment attempts to prevent abuse.</li>
      </ul>
      <p>
        If we become aware of a security compromise affecting your information, we will notify you
        and the Information Regulator as POPIA requires.
      </p>

      <h2>8. How long we keep information</h2>
      <ul>
        <li>Account and order information is kept while your account exists.</li>
        <li>
          When you delete your account, your account, profile, notification registrations, unfinished
          checkouts, consent records and privacy requests are deleted. Your past orders and payment
          records are kept as financial records, with your name, phone number, delivery address and
          order notes removed, for: <Pending>record-keeping period for orders and payments, for
          attorney and accountant review</Pending>
        </li>
        <li>Unfinished checkouts (payments that were never completed): <Pending>retention period (proposed: 30 days)</Pending></li>
        <li>Guest (anonymous) identifiers that never placed an order: <Pending>retention period (proposed: 90 days)</Pending></li>
        <li>Messages you send us: <Pending>retention period</Pending></li>
        <li>Our providers&rsquo; backups and logs expire on their own schedules.</li>
      </ul>

      <h2>9. Your rights</h2>
      <p>Under POPIA you may:</p>
      <ul>
        <li>ask whether we hold information about you, and ask for a copy of it;</li>
        <li>ask us to correct or delete information that is inaccurate, out of date, excessive or no longer needed;</li>
        <li>object to processing based on our legitimate interests;</li>
        <li>withdraw consent where we rely on it, for example by switching off app notifications; and</li>
        <li>
          complain to the Information Regulator at{" "}
          <a href="https://inforegulator.org.za" target="_blank" rel="noreferrer">inforegulator.org.za</a>.
        </li>
      </ul>
      <p>
        You can update your details, download a copy of your data, make a privacy request and delete
        your account in your account on the website, or delete it in the app. See our{" "}
        <Link href="/delete-account/">account deletion steps</Link>. For other requests, contact us
        using the details below. Formal requests for records follow our <Link href="/paia-manual/">PAIA
        manual</Link>.
      </p>

      <h2>10. Children</h2>
      <p>
        The service is not intended for children under 18 without a parent or guardian. If you believe a
        child has given us personal information, contact us and we will delete it.
      </p>

      <h2>11. Changes to this policy</h2>
      <p>
        We will update this policy when our service or the law changes. The version label at the top
        shows the current version. We will tell you about important changes in the app or on the website.
      </p>
    </LegalPage>
  );
}
