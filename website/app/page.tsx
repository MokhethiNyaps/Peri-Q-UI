import Link from "next/link";
import { ArrowRight, CreditCard, Flame, MapPin, ShieldCheck, Truck, UtensilsCrossed } from "lucide-react";
import { CategoryChapters, type Chapter } from "@/components/home/category-chapters";
import { HeroGrill, type HeroPlate } from "@/components/home/hero-grill";
import { OffTheGrill, type GrillDish } from "@/components/home/off-the-grill";
import { SocialLinks } from "@/components/social-links";
import { visibleCategories } from "@/lib/menu";
import { fetchPublicMenuSnapshot } from "@/lib/menu-server";
import { plateCutoutFor } from "@/lib/plates";
import { mailtoUrl, siteConfig } from "@/lib/site";

// Menu, prices and Today's Special come from the restaurant's database and are
// refreshed at most every five minutes. Opening hours are checked live in the browser.
export const revalidate = 300;

const steps = [
  { icon: UtensilsCrossed, title: "Pick your plate", copy: "Choose from the current menu and set your spice level." },
  { icon: Truck, title: "Pickup or delivery", copy: "Collect on King Edward Road, or add a delivery address." },
  { icon: CreditCard, title: "Pay by card", copy: "Card details are entered on a secure hosted payment page." },
  { icon: Flame, title: "Track the flame", copy: "Follow your order from received to ready." },
];

export default async function HomePage() {
  const { items, categories, settings, special } = await fetchPublicMenuSnapshot();

  const categoryOrder = visibleCategories(categories, items);
  const orderedItems = [...items].sort(
    (a, b) => categoryOrder.indexOf(a.category) - categoryOrder.indexOf(b.category) || a.name.localeCompare(b.name),
  );

  const specialItem = special?.menuItemId ? items.find((item) => item.id === special.menuItemId) : undefined;
  const heroSpecial = special
    ? {
        id: specialItem?.id ?? null,
        name: special.title,
        cutout: plateCutoutFor(special.imageUrl),
        photo: special.imageUrl,
        price: specialItem?.price ?? null,
        label: special.label,
        title: special.title,
        subtitle: special.subtitle,
      }
    : null;

  const sidePlates: HeroPlate[] = orderedItems
    .map((item) => ({ id: item.id, name: item.name, cutout: plateCutoutFor(item.imagePath), photo: item.imagePath, price: item.price }))
    .filter((plate) => plate.cutout && plate.cutout !== heroSpecial?.cutout)
    .slice(0, 2);

  const dishes: GrillDish[] = orderedItems.map((item) => ({
    id: item.id,
    name: item.name,
    category: item.category,
    price: item.price,
    photo: item.imagePath,
    cutout: plateCutoutFor(item.imagePath),
    available: item.isAvailable,
  }));

  const chapters: Chapter[] = categoryOrder.flatMap((name) => {
    const inCategory = orderedItems.filter((item) => item.category === name);
    const first = inCategory[0];
    if (!first) return [];
    return [
      {
        name,
        count: inCategory.length,
        fromPrice: Math.min(...inCategory.map((item) => item.price)),
        photo: first.imagePath,
        photoAlt: first.name,
      },
    ];
  });

  const localBusinessJsonLd = {
    "@context": "https://schema.org",
    "@type": "Restaurant",
    name: siteConfig.name,
    url: siteConfig.url,
    logo: `${siteConfig.url}/Logo.png`,
    email: siteConfig.email,
    telephone: siteConfig.phones[0],
    servesCuisine: "South African, Chesanyama",
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
    <main id="main-content" className="bg-soot">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(localBusinessJsonLd) }} />

      <HeroGrill settings={settings} special={heroSpecial} sidePlates={sidePlates} />

      <OffTheGrill dishes={dishes} />

      <CategoryChapters chapters={chapters} />

      <section id="how-it-works" className="section-pad bg-cream">
        <div className="site-shell">
          <div className="grid gap-6 lg:grid-cols-[0.9fr_1.1fr] lg:items-end">
            <div>
              <p className="eyebrow">How it works</p>
              <h2 className="section-title mt-5">From phone to flame in four steps.</h2>
            </div>
            <p className="max-w-xl text-base leading-8 text-ash lg:ml-auto">
              Order on this website or in the RastasperiQ app. Both use the same kitchen, the same menu and the same prices.
            </p>
          </div>

          <ol className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {steps.map(({ icon: Icon, title, copy }, index) => (
              <li key={title} className="feature-card">
                <div className="flex items-center justify-between">
                  <span className="icon-tile">
                    <Icon size={23} aria-hidden="true" />
                  </span>
                  <span className="font-display text-4xl font-extrabold text-black/10">0{index + 1}</span>
                </div>
                <h3 className="mt-7 font-display text-3xl font-extrabold uppercase leading-none">{title}</h3>
                <p className="mt-3 text-sm leading-7 text-ash">{copy}</p>
              </li>
            ))}
          </ol>

          <div className="mt-10 flex flex-col gap-3 sm:flex-row">
            <Link href="/menu/" className="button button-primary">
              Start an order
              <ArrowRight size={18} aria-hidden="true" />
            </Link>
            <Link href="/get-app/" className="button border border-black/10 bg-white text-charcoal">
              Get the Android app
            </Link>
          </div>
        </div>
      </section>

      <section id="visit" className="stage stage-glow section-pad overflow-hidden">
        <div className="site-shell grid gap-10 lg:grid-cols-[1.1fr_0.9fr] lg:items-center">
          <div>
            <p className="eyebrow eyebrow-ember">Come through</p>
            <h2 className="section-title mt-5 max-w-[12ch] text-cream">Find the flame in Bloemfontein.</h2>
            <p className="mt-6 max-w-lg text-base leading-8 text-smoke">
              Collect your order on King Edward Road, or contact the team before you head out.
            </p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <a href={siteConfig.mapsUrl} target="_blank" rel="noreferrer" className="button button-primary">
                <MapPin size={18} aria-hidden="true" />
                Open in Maps
              </a>
              <a href={mailtoUrl} className="button button-ghost">
                Email the team
              </a>
            </div>
          </div>

          <div className="rounded-[1.5rem] border border-white/10 bg-charcoal p-7 shadow-2xl">
            <span className="grid size-12 place-items-center rounded-2xl bg-orange text-soot">
              <MapPin size={23} aria-hidden="true" />
            </span>
            <p className="mt-6 text-xs font-black uppercase tracking-[0.18em] text-orange">RastasperiQ</p>
            <address className="mt-3 text-xl font-bold not-italic leading-8 text-cream">
              28 King Edward Rd
              <br />
              Bloemfontein, FS 9301
              <br />
              South Africa
            </address>
            {settings && (
              <p className="mt-5 border-t border-white/10 pt-5 text-sm font-semibold text-smoke">
                Kitchen hours: {settings.openingTime} – {settings.closingTime}
              </p>
            )}
          </div>
        </div>
      </section>

      <section id="contact" className="section-pad bg-peri-red text-white">
        <div className="site-shell grid gap-10 lg:grid-cols-[1fr_auto] lg:items-center">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.2em] text-white/70">Stay connected</p>
            <h2 className="mt-4 font-display text-5xl font-extrabold uppercase leading-none sm:text-7xl">Questions? We&apos;re here.</h2>
            <p className="mt-5 max-w-2xl text-base leading-8 text-white/80">
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
