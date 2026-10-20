import type { Metadata } from "next";
import Link from "next/link";
import {
  ArrowLeft,
  Database,
  EyeOff,
  LockKeyhole,
  Mail,
  MapPin,
  MessageCircle,
  UserRoundCheck,
} from "lucide-react";
import { mailtoUrl, siteConfig } from "@/lib/site";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "How RastasperiQ collects, uses, stores, and protects information in its Android ordering app.",
  alternates: { canonical: "/privacy-policy/" },
};

const sections = [
  ["who-we-are", "Who we are"],
  ["scope", "Scope"],
  ["information", "Information we process"],
  ["purposes", "How we use information"],
  ["sharing", "Sharing and providers"],
  ["security", "Security"],
  ["retention", "Retention"],
  ["device", "Information on your device"],
  ["choices", "Your choices and rights"],
  ["children", "Children"],
  ["international", "International processing"],
  ["changes", "Changes"],
  ["contact-policy", "Contact us"],
] as const;

export default function PrivacyPolicyPage() {
  return (
    <main id="main-content" className="bg-cream">
      <header className="relative isolate overflow-hidden bg-charcoal py-16 text-white sm:py-24">
        <div className="hero-grid absolute inset-0 -z-20 opacity-70" />
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
            <p className="eyebrow text-orange">Your information, explained clearly</p>
            <h1 className="mt-6 font-display text-5xl font-black uppercase leading-[0.88] tracking-[-0.05em] sm:text-7xl lg:text-8xl">
              Privacy policy
            </h1>
            <p className="mt-7 max-w-2xl text-base leading-8 text-white/65 sm:text-lg">
              This policy explains what information the RastasperiQ Android app
              uses, why it is needed, and the choices available to you.
            </p>
            <div className="mt-8 inline-flex items-center rounded-full border border-white/12 bg-white/7 px-4 py-2 text-xs font-bold text-white/70">
              Effective date: 20 July 2026
            </div>
          </div>
        </div>
      </header>

      <section className="border-b border-black/8 bg-muted py-10">
        <div className="policy-shell grid gap-4 md:grid-cols-3">
          {[
            {
              icon: EyeOff,
              title: "No advertising trackers",
              copy: "The app does not use advertising, analytics, location, contacts, SMS, or call-log tracking.",
            },
            {
              icon: LockKeyhole,
              title: "Protected by design",
              copy: "Encrypted connections, access rules, and protected storage help secure app information.",
            },
            {
              icon: UserRoundCheck,
              title: "You have choices",
              copy: "Use guest checkout, update your details, or request access to or deletion of your information.",
            },
          ].map(({ icon: Icon, title, copy }) => (
            <article key={title} className="policy-card">
              <Icon className="text-peri-red" size={24} aria-hidden="true" />
              <h2 className="mt-4 text-sm font-extrabold text-charcoal">{title}</h2>
              <p className="mt-2 text-xs leading-6 text-ash">{copy}</p>
            </article>
          ))}
        </div>
      </section>

      <div className="policy-shell grid gap-12 py-14 lg:grid-cols-[15rem_minmax(0,1fr)] lg:py-20">
        <aside className="hidden lg:block">
          <div className="sticky top-28">
            <p className="text-[0.68rem] font-black uppercase tracking-[0.18em] text-peri-red">
              On this page
            </p>
            <nav aria-label="Privacy policy sections" className="mt-4">
              {sections.map(([id, label]) => (
                <a key={id} href={`#${id}`} className="toc-link">
                  {label}
                </a>
              ))}
            </nav>
          </div>
        </aside>

        <article className="policy-content max-w-3xl">
          <p className="!mt-0 text-lg !leading-8 text-charcoal">
            RastasperiQ respects your privacy. We only process
            information needed to provide food ordering, fulfilment, payment
            reconciliation, customer support, and app security.
          </p>

          <h2 id="who-we-are">1. Who we are</h2>
          <p>
            The RastasperiQ Android app is operated by
            <strong> RastasperiQ</strong> at {siteConfig.address}.
          </p>

          <h2 id="scope">2. Scope of this policy</h2>
          <p>
            This policy applies to the RastasperiQ Android mobile app and the
            services used to place and manage orders from our single store. The app
            lets customers view a menu, create an account or use guest checkout,
            choose pickup or delivery, submit order details, and follow order status.
            Authorised staff use protected administration features to manage orders.
          </p>

          <h2 id="information">3. Information we process</h2>
          <h3>Account and contact details</h3>
          <ul>
            <li>Name, phone number, and email address.</li>
            <li>Authentication information managed through Supabase Auth.</li>
            <li>Delivery address and any addresses you choose to save.</li>
          </ul>

          <h3>Order and payment information</h3>
          <ul>
            <li>Items ordered, quantities, notes, totals, payment status, and timestamps.</li>
            <li>Pickup or delivery selection and the address needed to fulfil a delivery.</li>
            <li>Historical EFT payment proofs retained for existing orders. New orders use card payments.</li>
          </ul>

          <h3>Guest orders</h3>
          <p>
            If you use guest checkout, Supabase creates an anonymous identifier so the
            app can connect your device session to the order. You do not need to create
            a permanent account to place a guest order.
          </p>

          <h3>Information we do not collect through the app</h3>
          <p>
            The app does not include advertising or analytics SDKs and does not request
            precise location, contacts, SMS, or call-log access. It does not process card
            details, use Firebase Cloud Messaging, or include a third-party crash-reporting SDK.
          </p>

          <h2 id="purposes">4. How we use information</h2>
          <p>We use information to:</p>
          <ul>
            <li>Create and secure accounts and app sessions.</li>
            <li>Receive, prepare, update, and fulfil food orders.</li>
            <li>Deliver orders to the address a customer provides.</li>
            <li>Review historical payment records and reconcile card payment status.</li>
            <li>Show order status and order history.</li>
            <li>Prevent misuse, troubleshoot problems, and provide customer support.</li>
          </ul>

          <h2 id="sharing">5. Sharing and service providers</h2>
          <p>
            We do not sell personal information or use it for third-party advertising.
            Information is available only where needed to operate the service:
          </p>
          <ul>
            <li>
              <strong>Supabase</strong> provides authentication, PostgreSQL database,
              realtime updates, and protected file storage.
            </li>
            <li>
              <strong>Authorised store staff and delivery personnel</strong> can access
              the order details required to prepare, manage, or deliver an order.
            </li>
            <li>
              <strong>WhatsApp or email</strong> may process information you send when
              you choose those channels for support.
            </li>
          </ul>
          <p>
            The app&apos;s Supabase project is hosted in Ireland (<strong>eu-west-1</strong>).
          </p>

          <h2 id="security">6. How we protect information</h2>
          <p>Safeguards used by the app include:</p>
          <ul>
            <li>Encrypted HTTPS and WSS connections while information is transmitted.</li>
            <li>Row Level Security rules that limit database access by role and ownership.</li>
            <li>Server-side calculation of order prices.</li>
            <li>Private storage for uploaded EFT proof, with access restricted to authorised users.</li>
          </ul>
          <p>
            No online system can be guaranteed completely secure, but we use reasonable
            controls to reduce risk and restrict access.
          </p>

          <h2 id="retention">7. How long we keep information</h2>
          <ul>
            <li>
              Account details, profile data, saved addresses, and uploaded proof are
              deleted when an account deletion request is completed, except where a legal
              obligation requires retention.
            </li>
            <li>
              Order and financial records may be anonymised and retained for at least five
              years to meet South African tax and record-keeping obligations.
            </li>
            <li>
              Residual information in Supabase backups or operational logs may remain for
              up to 30 days before automatic expiry.
            </li>
          </ul>

          <h2 id="device">8. Information stored on your device</h2>
          <p>
            The Android app may save your selected preferences and saved delivery addresses
            locally for convenience. Android cloud backup is disabled for the app. Removing
            the app clears information stored only on that device, while server-side account
            and order records follow the retention rules above.
          </p>

          <h2 id="choices">9. Your choices and rights</h2>
          <ul>
            <li>Use guest checkout instead of creating a permanent account.</li>
            <li>Provide a delivery address only when you choose delivery.</li>
            <li>Pay securely by card on a hosted payment page without sharing card details with us.</li>
            <li>Review or correct your account and saved address details in the app.</li>
            <li>
              Delete your account from <strong>Profile → Delete Account</strong>, or follow
              the steps on our <Link href="/delete-account/">account deletion page</Link>.
            </li>
            <li>
              Ask us for access to, correction of, or deletion of personal information by
              using the contact details below.
            </li>
          </ul>

          <h2 id="children">10. Children&apos;s privacy</h2>
          <p>
            The app is a general-audience food ordering service and is not designed to
            knowingly collect information from children without appropriate involvement
            from a parent or guardian. Please contact us if you believe a child has provided
            personal information inappropriately.
          </p>

          <h2 id="international">11. International processing</h2>
          <p>
            Because Supabase hosts the app&apos;s backend in Ireland, information may be
            processed outside South Africa. We use the provider&apos;s security controls and
            contractual protections as part of operating the service.
          </p>

          <h2 id="changes">12. Changes to this policy</h2>
          <p>
            We may update this policy when the app or our legal obligations change. The
            effective date at the top of this page will show when the current version began
            to apply.
          </p>

          <h2 id="contact-policy">13. Contact us</h2>
          <p>
            Contact RastasperiQ if you have a privacy question or want to
            exercise one of the rights described above.
          </p>

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
                Phone / WhatsApp
              </span>
              <span className="mt-1 block text-sm font-extrabold text-charcoal">
                {siteConfig.phones.join(" / ")}
              </span>
            </a>
            <a
              href={siteConfig.mapsUrl}
              target="_blank"
              rel="noreferrer"
              className="policy-card !no-underline sm:col-span-2"
            >
              <MapPin className="text-peri-red" size={21} aria-hidden="true" />
              <span className="mt-4 block text-xs font-black uppercase tracking-[0.14em] text-ash">
                Address
              </span>
              <span className="mt-1 block text-sm font-extrabold text-charcoal">
                {siteConfig.address}
              </span>
            </a>
          </div>

          <div className="mt-12 flex items-start gap-4 rounded-3xl bg-charcoal p-6 text-white sm:p-8">
            <Database className="mt-1 shrink-0 text-orange" size={24} aria-hidden="true" />
            <div>
              <p className="!mt-0 !text-white font-extrabold">A plain-language commitment</p>
              <p className="!mt-2 !text-sm !leading-7 !text-white/60">
                We aim to collect only what the ordering service needs and to explain those
                choices without hiding them in complicated language.
              </p>
            </div>
          </div>
        </article>
      </div>
    </main>
  );
}

