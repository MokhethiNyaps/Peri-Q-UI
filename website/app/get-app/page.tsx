import { ArrowLeft, BellRing, Flame, Percent, ShoppingBag } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { GetAppPanel } from "@/components/get-app-panel";
import { siteConfig } from "@/lib/site";

export const metadata: Metadata = {
  title: "Get the App",
  description:
    "Install the RastasperiQ Android app from the Google Play Store to order flame-grilled chesanyama for pickup or delivery in Bloemfontein.",
  alternates: { canonical: "/get-app/" },
  openGraph: {
    title: "Get the RastasperiQ app",
    description:
      "Order flame-grilled chesanyama from your phone. Install the RastasperiQ app from the Google Play Store.",
    url: "/get-app/",
    images: [{ url: "/qr/rastasperiq-get-app-qr-square.png", width: 1200, height: 1200, alt: "RastasperiQ app QR code" }],
  },
};

const installSteps = [
  [
    "1",
    "Open this page on Android",
    "Scan the printed QR code, or open this link on the phone you want to install on.",
  ],
  [
    "2",
    "Install from Play Store",
    "Android sends you straight into the Play Store app, where you can tap Install.",
  ],
  [
    "3",
    "Order in a few taps",
    "Build your plate, choose your sauce, and track it from the grill to your hands.",
  ],
];

const appPerks = [
  {
    icon: ShoppingBag,
    title: "The full menu",
    copy: "Meat plates, combos, sharing meals, and sides with Peri-Peri, BBQ, or Lemon & Herb.",
  },
  {
    icon: BellRing,
    title: "Order updates",
    copy: "Know when the kitchen accepts your order and when it is ready for pickup or out for delivery.",
  },
  {
    icon: Flame,
    title: "Built for chesanyama",
    copy: "Pork chops, beef, flame-grilled chicken, wors, liver, soft pap, and fresh salads.",
  },
  {
    icon: Percent,
    title: "App-only specials",
    copy: "Combos and offers shared with app users first.",
  },
];

export default function GetAppPage() {
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
              <ShoppingBag size={26} aria-hidden="true" />
            </span>
            <h1 className="mt-7 font-display text-5xl font-black uppercase leading-[0.88] tracking-[-0.05em] sm:text-7xl">
              Get the app
            </h1>
            <p className="mt-7 max-w-2xl text-base leading-8 text-white/65 sm:text-lg">
              Order flame-grilled chesanyama from your phone. Open this page on an
              Android device and we take you straight to RastasperiQ in the Play
              Store app.
            </p>
          </div>
        </div>
      </section>

      <section className="section-pad">
        <div className="policy-shell grid gap-10 lg:grid-cols-[1.08fr_0.92fr]">
          <div>
            <p className="eyebrow">Installing</p>
            <h2 className="section-title mt-5">Three taps to your next plate.</h2>
            <div className="mt-9 grid gap-4">
              {installSteps.map(([number, title, copy]) => (
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

          <GetAppPanel />
        </div>
      </section>

      <section className="section-pad bg-muted">
        <div className="policy-shell">
          <p className="eyebrow">Why the app</p>
          <h2 className="section-title mt-5">Everything on the menu, in your pocket.</h2>
          <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {appPerks.map(({ icon: Icon, title, copy }) => (
              <div key={title} className="feature-card">
                <span className="icon-tile">
                  <Icon size={23} aria-hidden="true" />
                </span>
                <h3 className="mt-6 font-display text-2xl font-black uppercase leading-none tracking-[-0.03em]">
                  {title}
                </h3>
                <p className="mt-3 text-sm leading-7 text-ash">{copy}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-black/8 bg-cream py-8">
        <div className="policy-shell flex flex-col gap-3 text-sm text-ash sm:flex-row sm:items-center sm:justify-between">
          <p>
            Prefer to read first? Here is how the app handles your information.
          </p>
          <Link href="/privacy-policy/" className="font-extrabold text-peri-red underline">
            Read the privacy policy
          </Link>
        </div>
      </section>

      <section className="bg-charcoal py-10 text-white">
        <div className="policy-shell flex flex-col gap-4 text-sm text-white/60 sm:flex-row sm:items-center sm:justify-between">
          <p>
            Need help installing? Call{" "}
            <a href={`tel:${siteConfig.phones[0].replace(/\s/g, "")}`} className="font-bold text-white underline">
              {siteConfig.phones[0]}
            </a>{" "}
            or message us on WhatsApp.
          </p>
          <a
            href={siteConfig.app.playStoreUrl}
            target="_blank"
            rel="noreferrer"
            className="button button-sm button-ghost"
          >
            View listing on Google Play
          </a>
        </div>
      </section>
    </main>
  );
}
