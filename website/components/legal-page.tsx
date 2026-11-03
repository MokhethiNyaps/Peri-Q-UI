import Link from "next/link";
import type { LucideIcon } from "lucide-react";
import { ArrowLeft, Mail, MessageCircle, TriangleAlert } from "lucide-react";
import { business, LEGAL_REVIEW_PENDING, LEGAL_VERSION, legalDocuments } from "@/lib/legal";
import { mailtoUrl, siteConfig } from "@/lib/site";

/** A fact the business owner or an attorney still has to supply. */
export function Pending({ children }: { children: React.ReactNode }) {
  return (
    <mark className="rounded bg-amber-100 px-1.5 py-0.5 font-bold text-amber-900">
      [To be confirmed: {children}]
    </mark>
  );
}

/** Shows a confirmed value, or a visible placeholder when it is unknown. */
export function Fact({ value, missing }: { value: string | null; missing: string }) {
  return value ? <>{value}</> : <Pending>{missing}</Pending>;
}

/** The supplier details ECTA section 43 asks online sellers to show. */
export function BusinessDetails() {
  return (
    <ul>
      <li><strong>Legal name:</strong> {business.legalName}, trading as {business.tradingName}</li>
      <li><strong>Legal status and registration number:</strong> {business.entityType}, {business.registrationNumber}</li>
      <li><strong>Registered office and address for legal notices:</strong> {business.registeredOffice}</li>
      <li><strong>Physical trading address:</strong> <Fact value={business.tradingAddress} missing="trading address (the website currently shows 28 King Edward Rd)" /></li>
      <li><strong>Directors:</strong> <Fact value={business.directors} missing="names of the directors" /></li>
      <li><strong>VAT registration:</strong> <Fact value={business.vatNumber} missing="VAT number, or confirmation the company is not VAT-registered" /></li>
      <li><strong>Email:</strong> {siteConfig.email}</li>
      <li><strong>Phone / WhatsApp:</strong> {siteConfig.phones.join(" / ")}</li>
      <li><strong>Website:</strong> {siteConfig.url}</li>
    </ul>
  );
}

export function LegalPage({
  title,
  intro,
  icon: Icon,
  href,
  children,
}: {
  title: string;
  intro: string;
  icon: LucideIcon;
  href: string;
  children: React.ReactNode;
}) {
  const related = legalDocuments.filter((doc) => doc.href !== href);
  return (
    <main id="main-content" className="bg-cream">
      <header className="relative isolate overflow-hidden bg-charcoal py-16 text-white sm:py-24">
        <div className="hero-grid absolute inset-0 -z-20 opacity-60" />
        <div className="absolute -right-20 -top-32 -z-10 size-[30rem] rounded-full bg-peri-red/25 blur-3xl" />
        <div className="policy-shell">
          <Link
            href="/legal/"
            className="inline-flex items-center gap-2 text-sm font-bold text-white/60 transition-colors hover:text-white"
          >
            <ArrowLeft size={17} aria-hidden="true" />
            Legal and policies
          </Link>
          <div className="mt-10 max-w-4xl">
            <span className="grid size-14 place-items-center rounded-2xl bg-peri-red text-white shadow-xl">
              <Icon size={25} aria-hidden="true" />
            </span>
            <h1 className="mt-7 font-display text-5xl font-black uppercase leading-[0.88] tracking-[-0.05em] sm:text-7xl lg:text-8xl">
              {title}
            </h1>
            <p className="mt-7 max-w-2xl text-base leading-8 text-white/65 sm:text-lg">{intro}</p>
            <div className="mt-8 inline-flex items-center rounded-full border border-white/12 bg-white/7 px-4 py-2 text-xs font-bold text-white/70">
              {LEGAL_VERSION}
            </div>
          </div>
        </div>
      </header>

      <div className="policy-shell py-14 lg:py-20">
        <article className="policy-content mx-auto max-w-3xl">
          {LEGAL_REVIEW_PENDING && (
            <div role="note" className="!mt-0 flex gap-3 rounded-2xl border border-amber-300 bg-amber-50 p-5 text-sm leading-6 text-amber-950">
              <TriangleAlert size={20} className="mt-0.5 shrink-0" aria-hidden="true" />
              <p className="!mt-0 !text-sm !leading-6 !text-amber-950">
                <strong>Draft under review.</strong> This document is being reviewed by the business
                owner and a legal adviser. Items marked &ldquo;To be confirmed&rdquo; are still being
                finalised. If anything is unclear, contact us before you order.
              </p>
            </div>
          )}

          {children}

          <h2>Contact us</h2>
          <p>
            {siteConfig.name} is the trading name of the company named in this document. Contact us
            about this document, an order, or your personal information.
          </p>
          <div className="mt-7 grid gap-3 sm:grid-cols-2">
            <a href={mailtoUrl} className="policy-card !no-underline">
              <Mail className="text-peri-red" size={21} aria-hidden="true" />
              <span className="mt-4 block text-xs font-black uppercase tracking-[0.14em] text-ash">Email</span>
              <span className="mt-1 block break-all text-sm font-extrabold text-charcoal">{siteConfig.email}</span>
            </a>
            <a href={siteConfig.whatsappUrl} target="_blank" rel="noreferrer" className="policy-card !no-underline">
              <MessageCircle className="text-peri-red" size={21} aria-hidden="true" />
              <span className="mt-4 block text-xs font-black uppercase tracking-[0.14em] text-ash">Phone / WhatsApp</span>
              <span className="mt-1 block text-sm font-extrabold text-charcoal">{siteConfig.phones.join(" / ")}</span>
            </a>
          </div>

          <h2>Related documents</h2>
          <ul>
            {related.map((doc) => (
              <li key={doc.href}>
                <Link href={doc.href}>{doc.title}</Link>: {doc.summary}
              </li>
            ))}
          </ul>
        </article>
      </div>
    </main>
  );
}
