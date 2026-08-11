import type { Metadata } from "next";
import Link from "next/link";
import {
  ArrowLeft,
  CheckCircle2,
  Mail,
  MessageCircle,
  Smartphone,
  Trash2,
} from "lucide-react";
import { siteConfig } from "@/lib/site";

export const metadata: Metadata = {
  title: "Delete Your Account",
  description:
    "Instructions for deleting a RastasperiQ account and associated personal information.",
  alternates: { canonical: "/delete-account/" },
};

const deletionEmail = `mailto:${siteConfig.email}?subject=${encodeURIComponent(
  "RastasperiQ account deletion request",
)}&body=${encodeURIComponent(
  "Hello RastasperiQ team,\n\nPlease delete my app account and associated personal information.\n\nAccount email or phone number:\n\nThank you.",
)}`;

export default function DeleteAccountPage() {
  return (
    <main id="main-content" className="bg-cream">
      <section className="relative isolate overflow-hidden bg-charcoal py-16 text-white sm:py-24">
        <div className="hero-grid absolute inset-0 -z-20 opacity-60" />
        <div className="absolute -right-28 -top-32 -z-10 size-[30rem] rounded-full bg-peri-red/25 blur-3xl" />
        <div className="policy-shell">
          <Link
            href="/"
            className="inline-flex items-center gap-2 text-sm font-bold text-white/60 transition-colors hover:text-white"
          >
            <ArrowLeft size={17} aria-hidden="true" />
            Back to home
          </Link>
          <div className="mt-10 max-w-3xl">
            <span className="grid size-14 place-items-center rounded-2xl bg-peri-red text-white shadow-xl">
              <Trash2 size={26} aria-hidden="true" />
            </span>
            <h1 className="mt-7 font-display text-5xl font-black uppercase leading-[0.88] tracking-[-0.05em] sm:text-7xl">
              Delete your account
            </h1>
            <p className="mt-7 max-w-2xl text-base leading-8 text-white/65 sm:text-lg">
              You can request deletion from inside the RastasperiQ app or contact
              us directly if you cannot access your account.
            </p>
          </div>
        </div>
      </section>

      <section className="section-pad">
        <div className="policy-shell grid gap-10 lg:grid-cols-[1.08fr_0.92fr]">
          <div>
            <p className="eyebrow">Fastest option</p>
            <h2 className="section-title mt-5">Delete it in the app.</h2>
            <div className="mt-9 grid gap-4">
              {[
                ["1", "Open the app", "Sign in to the account you want to delete."],
                ["2", "Go to Profile", "Open your profile and choose Delete Account."],
                ["3", "Confirm deletion", "Read the confirmation and complete the deletion request."],
              ].map(([number, title, copy]) => (
                <div key={number} className="feature-card flex gap-5">
                  <span className="step-number">{number}</span>
                  <div>
                    <h3 className="font-display text-2xl font-black uppercase tracking-[-0.03em]">
                      {title}
                    </h3>
                    <p className="mt-2 text-sm leading-7 text-ash">{copy}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <aside className="lg:pt-12">
            <div className="rounded-[2rem] bg-muted p-6 sm:p-8">
              <span className="icon-tile">
                <Smartphone size={23} aria-hidden="true" />
              </span>
              <h2 className="mt-6 font-display text-3xl font-black uppercase leading-none tracking-[-0.04em]">
                Can&apos;t access the app?
              </h2>
              <p className="mt-4 text-sm leading-7 text-ash">
                Contact us using the email address or WhatsApp number associated with your
                account. Include enough information for us to verify the request, but do not
                send your password.
              </p>
              <div className="mt-6 grid gap-3">
                <a href={deletionEmail} className="button button-primary w-full">
                  <Mail size={18} aria-hidden="true" />
                  Email deletion request
                </a>
                <a
                  href={`${siteConfig.whatsappUrl}?text=${encodeURIComponent(
                    "Hello, I need help deleting my RastasperiQ app account.",
                  )}`}
                  target="_blank"
                  rel="noreferrer"
                  className="button button-dark w-full"
                >
                  <MessageCircle size={18} aria-hidden="true" />
                  Ask on WhatsApp
                </a>
              </div>
            </div>
          </aside>
        </div>
      </section>

      <section className="section-pad bg-muted">
        <div className="policy-shell grid gap-10 lg:grid-cols-2">
          <div>
            <p className="eyebrow">What happens next</p>
            <h2 className="section-title mt-5">What deletion covers.</h2>
          </div>
          <div className="grid gap-4">
            {[
              "Your account, profile details, and saved addresses are removed.",
              "Uploaded EFT payment proof associated with the account is removed, except where retention is legally required.",
              "Order and financial records may be anonymised and kept for at least five years where South African record-keeping law requires it.",
              "Residual data in Supabase backups or operational logs may take up to 30 days to expire.",
            ].map((item) => (
              <div key={item} className="flex gap-4 rounded-2xl border border-black/8 bg-white p-5">
                <CheckCircle2 className="mt-0.5 shrink-0 text-leaf" size={21} aria-hidden="true" />
                <p className="text-sm leading-7 text-ash">{item}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-black/8 bg-cream py-8">
        <div className="policy-shell flex flex-col gap-3 text-sm text-ash sm:flex-row sm:items-center sm:justify-between">
          <p>Want to understand how app information is handled?</p>
          <Link href="/privacy-policy/" className="font-extrabold text-peri-red underline">
            Read the privacy policy
          </Link>
        </div>
      </section>
    </main>
  );
}
