import Image from "next/image";
import Link from "next/link";
import {
  ArrowRight,
  Check,
  ChevronRight,
  Clock3,
  MapPin,
  MessageCircle,
  ShieldCheck,
  Smartphone,
  Truck,
  UserRoundCheck,
  UtensilsCrossed,
} from "lucide-react";
import { SocialLinks } from "@/components/social-links";
import { TodaysSpecialLive } from "@/components/todays-special-live";
import { mailtoUrl, siteConfig } from "@/lib/site";

const features = [
  {
    icon: UtensilsCrossed,
    title: "Browse the menu",
    copy: "Explore the latest menu and make your choice without waiting at the counter.",
  },
  {
    icon: Truck,
    title: "Pickup or delivery",
    copy: "Choose the option that fits your day and add delivery details only when needed.",
  },
  {
    icon: Clock3,
    title: "Follow your order",
    copy: "See order status updates clearly, from confirmation through to collection or delivery.",
  },
  {
    icon: UserRoundCheck,
    title: "Checkout your way",
    copy: "Create an account for convenience or keep it quick with guest checkout.",
  },
];

const steps = [
  ["01", "Open the app", "Sign in, create an account, or continue as a guest."],
  ["02", "Build your order", "Choose your favourites and add any helpful order notes."],
  ["03", "Choose fulfilment", "Select pickup or delivery and confirm your order details."],
  ["04", "Track the flame", "Follow the order status until your food is ready."],
];

export default function HomePage() {
  const localBusinessJsonLd = {
    "@context": "https://schema.org",
    "@type": "Restaurant",
    name: siteConfig.name,
    url: siteConfig.url,
    logo: `${siteConfig.url}/Logo.png`,
    email: siteConfig.email,
    telephone: siteConfig.phones[0],
    address: {
      "@type": "PostalAddress",
      streetAddress: "28 King Edward Rd",
      addressLocality: "Bloemfontein",
      addressRegion: "Free State",
      postalCode: "9301",
      addressCountry: "ZA",
    },
  };

  return (
    <main id="main-content">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(localBusinessJsonLd) }}
      />

      <section className="hero-grid relative isolate overflow-hidden bg-charcoal text-white">
        <div className="hero-glow absolute -right-40 top-12 -z-10 size-[42rem] rounded-full" />
        <div className="absolute -bottom-24 -left-28 -z-10 size-72 rounded-full bg-peri-red/20 blur-3xl" />

        <div className="site-shell grid min-h-[calc(100svh-5rem)] items-center gap-10 py-16 lg:grid-cols-[1.12fr_0.88fr] lg:py-20">
          <div className="relative z-10 max-w-3xl">
            <p className="eyebrow text-orange">Bloemfontein&apos;s flame-grilled flavour</p>
            <h1 className="display-title mt-7">
              Food with
              <span className="block text-orange">proper fire.</span>
            </h1>
            <p className="mt-7 max-w-xl text-base leading-8 text-white/68 sm:text-lg">
              Your RastasperiQ favourites, ordered simply. Browse the menu,
              choose pickup or delivery, and follow your order from your phone.
            </p>

            <div className="mt-9 flex flex-col gap-3 sm:flex-row">
              <Link href="/menu/" className="button button-primary">
                <UtensilsCrossed size={19} aria-hidden="true" />
                Order on website
              </Link>
              <a
                href={siteConfig.whatsappUrl}
                target="_blank"
                rel="noreferrer"
                className="button button-ghost"
              >
                <MessageCircle size={19} aria-hidden="true" />
                Chat on WhatsApp
              </a>
              <a href="#how-it-works" className="button button-ghost">
                See how it works
                <ArrowRight size={18} aria-hidden="true" />
              </a>
            </div>

            <div className="mt-12 grid max-w-xl grid-cols-3 gap-3">
              {[
                ["Easy", "mobile ordering"],
                ["Guest", "checkout"],
                ["Live", "order status"],
              ].map(([top, bottom]) => (
                <div key={bottom} className="stat-card">
                  <p className="font-display text-xl font-black uppercase text-white sm:text-2xl">
                    {top}
                  </p>
                  <p className="mt-1 text-[0.7rem] leading-4 text-white/50 sm:text-xs">{bottom}</p>
                </div>
              ))}
            </div>
          </div>

          <div className="relative mx-auto w-full max-w-[32rem] lg:ml-auto">
            <div className="absolute left-0 top-1/2 size-24 -translate-x-1/3 rounded-full bg-orange/75 blur-3xl" />
            <div className="hero-logo-wrap relative aspect-square overflow-hidden rounded-[3.25rem] bg-cream p-7 ring-1 ring-orange/20 sm:p-10">
              <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_28%,rgba(240,120,32,0.16),transparent_58%)]" />
              <Image
                src="/logo-squere.png"
                alt="RastasperiQ logo"
                width={1254}
                height={1254}
                priority
                className="relative h-full w-full scale-[1.28] object-contain drop-shadow-[0_28px_36px_rgba(0,0,0,0.45)]"
              />
            </div>
            <div className="absolute -bottom-4 left-5 right-5 flex items-center justify-between rounded-2xl border border-white/10 bg-white/10 px-5 py-4 shadow-2xl backdrop-blur-xl sm:left-10 sm:right-10">
              <div className="flex items-center gap-3">
                <span className="grid size-9 place-items-center rounded-full bg-orange text-charcoal">
                  <Check size={18} strokeWidth={3} aria-hidden="true" />
                </span>
                <div>
                  <p className="text-xs font-extrabold text-white">Simple from start to finish</p>
                  <p className="mt-0.5 text-[0.68rem] text-white/50">Order. Track. Enjoy.</p>
                </div>
              </div>
              <Smartphone className="text-white/35" size={22} aria-hidden="true" />
            </div>
          </div>
        </div>
      </section>

      <section className="section-pad overflow-hidden">
        <div className="site-shell">
          <div className="grid gap-8 lg:grid-cols-[0.8fr_1.2fr] lg:items-end">
            <div>
              <p className="eyebrow">Made for real life</p>
              <h2 className="section-title mt-5">Your order, without the guesswork.</h2>
            </div>
            <p className="max-w-xl text-base leading-8 text-ash lg:ml-auto">
              The RastasperiQ app keeps ordering clear and convenient, whether you
              want to collect your meal or have it delivered.
            </p>
          </div>

          <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {features.map(({ icon: Icon, title, copy }) => (
              <article key={title} className="feature-card">
                <span className="icon-tile">
                  <Icon size={23} aria-hidden="true" />
                </span>
                <h3 className="mt-7 font-display text-2xl font-black uppercase leading-none tracking-[-0.03em]">
                  {title}
                </h3>
                <p className="mt-4 text-sm leading-7 text-ash">{copy}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section id="how-it-works" className="section-pad bg-muted">
        <div className="site-shell grid gap-14 lg:grid-cols-[0.82fr_1.18fr]">
          <div className="lg:sticky lg:top-32 lg:self-start">
            <p className="eyebrow">How it works</p>
            <h2 className="section-title mt-5">From phone to flame in four steps.</h2>
            <p className="mt-6 max-w-md text-base leading-8 text-ash">
              Straightforward ordering designed around the way you already choose and
              collect food.
            </p>
          </div>

          <ol className="divide-y divide-black/8 border-y border-black/8">
            {steps.map(([number, title, copy]) => (
              <li key={number} className="group flex gap-5 py-7 sm:gap-7 sm:py-9">
                <span className="step-number">{number}</span>
                <div className="flex-1">
                  <h3 className="font-display text-2xl font-black uppercase tracking-[-0.03em] sm:text-3xl">
                    {title}
                  </h3>
                  <p className="mt-2 max-w-lg text-sm leading-7 text-ash sm:text-base">{copy}</p>
                </div>
                <ChevronRight
                  className="mt-2 hidden text-peri-red transition-transform group-hover:translate-x-1 sm:block"
                  size={22}
                  aria-hidden="true"
                />
              </li>
            ))}
          </ol>
        </div>
      </section>

      <TodaysSpecialLive />

      <section id="visit" className="section-pad bg-cream">
        <div className="site-shell grid overflow-hidden rounded-[2.5rem] bg-charcoal text-white shadow-2xl lg:grid-cols-[1.1fr_0.9fr]">
          <div className="relative overflow-hidden p-7 sm:p-12 lg:p-16">
            <div className="absolute -right-24 -top-28 size-80 rounded-full bg-peri-red/30 blur-3xl" />
            <p className="eyebrow relative text-orange">Come through</p>
            <h2 className="section-title relative mt-5 max-w-[11ch] text-white">
              Find the flame in Bloemfontein.
            </h2>
            <p className="relative mt-6 max-w-lg text-base leading-8 text-white/60">
              Visit us on King Edward Road, or contact the team before you head out.
            </p>
            <div className="relative mt-8 flex flex-col gap-3 sm:flex-row">
              <a
                href={siteConfig.mapsUrl}
                target="_blank"
                rel="noreferrer"
                className="button button-primary"
              >
                <MapPin size={18} aria-hidden="true" />
                Open in Maps
              </a>
              <a href={mailtoUrl} className="button button-ghost">
                Email the team
              </a>
            </div>
          </div>

          <div className="grid min-h-80 place-items-center bg-[linear-gradient(135deg,#f07820_0%,#c8240b_48%,#7b190b_100%)] p-8">
            <div className="w-full max-w-sm rounded-[2rem] border border-white/20 bg-charcoal/90 p-7 shadow-2xl backdrop-blur">
              <span className="grid size-12 place-items-center rounded-2xl bg-orange text-charcoal">
                <MapPin size={23} aria-hidden="true" />
              </span>
              <p className="mt-6 text-xs font-black uppercase tracking-[0.18em] text-orange">
                RastasperiQ
              </p>
              <address className="mt-3 text-xl font-bold not-italic leading-8 text-white">
                28 King Edward Rd
                <br />
                Bloemfontein, FS 9301
                <br />
                South Africa
              </address>
            </div>
          </div>
        </div>
      </section>

      <section id="contact" className="section-pad bg-peri-red text-white">
        <div className="site-shell grid gap-10 lg:grid-cols-[1fr_auto] lg:items-center">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.2em] text-white/60">
              Stay connected
            </p>
            <h2 className="mt-4 font-display text-4xl font-black uppercase leading-none tracking-[-0.04em] sm:text-6xl">
              Questions? We&apos;re here.
            </h2>
            <p className="mt-5 max-w-2xl text-base leading-8 text-white/72">
              Message, call, or email the team for help with an order or the RastasperiQ app.
            </p>
          </div>
          <SocialLinks />
        </div>
      </section>

      <section className="border-t border-black/8 bg-cream py-7">
        <div className="site-shell flex flex-col gap-4 text-sm text-ash sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-3">
            <ShieldCheck className="text-leaf" size={20} aria-hidden="true" />
            <span>Your privacy and choices are clearly explained.</span>
          </div>
          <Link href="/privacy-policy/" className="inline-flex items-center gap-2 font-extrabold text-peri-red">
            Read the privacy policy
            <ArrowRight size={17} aria-hidden="true" />
          </Link>
        </div>
      </section>
    </main>
  );
}
