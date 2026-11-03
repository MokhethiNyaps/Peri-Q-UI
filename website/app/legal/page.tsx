import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeft, ArrowRight, Landmark } from "lucide-react";
import { BusinessDetails } from "@/components/legal-page";
import { LEGAL_REVIEW_PENDING, LEGAL_VERSION, legalDocuments } from "@/lib/legal";

export const metadata: Metadata = {
  title: "Legal and Policies",
  description: "RastasperiQ's privacy policy, terms and customer policies in one place.",
  alternates: { canonical: "/legal/" },
};

export default function LegalIndexPage() {
  return (
    <main id="main-content" className="bg-cream">
      <header className="relative isolate overflow-hidden bg-charcoal py-16 text-white sm:py-24">
        <div className="hero-grid absolute inset-0 -z-20 opacity-60" />
        <div className="absolute -right-20 -top-32 -z-10 size-[30rem] rounded-full bg-peri-red/25 blur-3xl" />
        <div className="policy-shell">
          <Link href="/" className="inline-flex items-center gap-2 text-sm font-bold text-white/60 transition-colors hover:text-white">
            <ArrowLeft size={17} aria-hidden="true" />
            Back to home
          </Link>
          <div className="mt-10 max-w-4xl">
            <span className="grid size-14 place-items-center rounded-2xl bg-peri-red text-white shadow-xl">
              <Landmark size={25} aria-hidden="true" />
            </span>
            <h1 className="mt-7 font-display text-5xl font-black uppercase leading-[0.88] tracking-[-0.05em] sm:text-7xl lg:text-8xl">
              Legal and policies
            </h1>
            <p className="mt-7 max-w-2xl text-base leading-8 text-white/65 sm:text-lg">
              Everything about how we handle your orders, payments and personal information, in one place.
            </p>
            <div className="mt-8 inline-flex items-center rounded-full border border-white/12 bg-white/7 px-4 py-2 text-xs font-bold text-white/70">
              {LEGAL_REVIEW_PENDING ? LEGAL_VERSION : "Current versions"}
            </div>
          </div>
        </div>
      </header>

      <div className="policy-shell py-14 lg:py-20">
        <div className="mx-auto grid max-w-5xl gap-4 sm:grid-cols-2">
          {legalDocuments.map((doc) => (
            <Link key={doc.href} href={doc.href} className="policy-card group flex flex-col !no-underline">
              <span className="font-display text-2xl font-black uppercase tracking-[-0.03em] text-charcoal">{doc.title}</span>
              <span className="mt-2 flex-1 text-sm leading-6 text-ash">{doc.summary}</span>
              <span className="mt-4 inline-flex items-center gap-2 text-sm font-extrabold text-peri-red">
                Read
                <ArrowRight size={16} className="transition-transform group-hover:translate-x-1" aria-hidden="true" />
              </span>
            </Link>
          ))}
          <Link href="/delete-account/" className="policy-card group flex flex-col !no-underline">
            <span className="font-display text-2xl font-black uppercase tracking-[-0.03em] text-charcoal">Delete your account</span>
            <span className="mt-2 flex-1 text-sm leading-6 text-ash">How to delete your account and what happens to your information.</span>
            <span className="mt-4 inline-flex items-center gap-2 text-sm font-extrabold text-peri-red">
              Read
              <ArrowRight size={16} className="transition-transform group-hover:translate-x-1" aria-hidden="true" />
            </span>
          </Link>
        </div>

        <article className="policy-content mx-auto mt-14 max-w-3xl">
          <h2>About the business</h2>
          <BusinessDetails />
        </article>
      </div>
    </main>
  );
}
