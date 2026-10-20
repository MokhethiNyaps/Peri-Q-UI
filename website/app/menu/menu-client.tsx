"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { ArrowRight, Clock3, Flame, Search, ShoppingBasket, Store, Truck } from "lucide-react";
import { useCart } from "@/lib/cart";
import { fetchMenu, isStoreOpenNow, type MenuItem, type AppSettings } from "@/lib/menu";
import { isSupabaseConfigured } from "@/lib/supabase";

type Customization = {
  spiceLevel?: string | null;
  notes: string;
  selectedAddOns: { name: string; price: number }[];
  quantity: number;
};

export default function MenuClient() {
  const { add, count } = useCart();
  const [items, setItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<string[]>(["All"]);
  const [appSettings, setAppSettings] = useState<AppSettings | null>(null);
  const [activeCategory, setActiveCategory] = useState("All");
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [customizing, setCustomizing] = useState<MenuItem | null>(null);
  const [custom, setCustom] = useState<Customization>({ notes: "", selectedAddOns: [], quantity: 1, spiceLevel: null });
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    if (!isSupabaseConfigured()) {
      setError("Menu is not yet connected. Owner must add Supabase URL and publishable key in Vercel.");
      setLoading(false);
      return;
    }
    void (async () => {
      try {
        setLoading(true);
        const { items: fetchedItems, categories: fetchedCats, appSettings: settings } = await fetchMenu();
        setItems(fetchedItems);
        const activeCats = fetchedCats.filter((c) => c.isActive).map((c) => c.name);
        // Merge item categories that may not have catalog entry
        const itemCats = Array.from(new Set(fetchedItems.map((i) => i.category))).filter(Boolean);
        const merged = ["All", ...Array.from(new Set([...activeCats, ...itemCats]))];
        setCategories(merged);
        setAppSettings(settings);
        setError(null);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Failed to load menu. Check your connection.");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return items.filter((it) => {
      if (activeCategory !== "All" && it.category !== activeCategory) return false;
      if (q && !(`${it.name} ${it.description} ${it.category}`.toLowerCase().includes(q))) return false;
      return true;
    });
  }, [items, activeCategory, query]);

  const openCustomize = (item: MenuItem) => {
    setCustomizing(item);
    setCustom({
      quantity: 1,
      notes: "",
      spiceLevel: item.spiceLevels?.[0] ?? null,
      selectedAddOns: [],
    });
  };

  const toggleAddOn = (name: string, price: number) => {
    setCustom((prev) => {
      const exists = prev.selectedAddOns.some((a) => a.name === name);
      return {
        ...prev,
        selectedAddOns: exists ? prev.selectedAddOns.filter((a) => a.name !== name) : [...prev.selectedAddOns, { name, price }],
      };
    });
  };

  const handleAdd = () => {
    if (!customizing) return;
    try {
      add(customizing, {
        quantity: custom.quantity,
        spiceLevel: custom.spiceLevel ?? undefined,
        notes: custom.notes,
        selectedAddOns: custom.selectedAddOns,
      });
      setToast(`${customizing.name} ×${custom.quantity} added to cart`);
      setCustomizing(null);
      setTimeout(() => setToast(null), 2500);
    } catch (e) {
      setToast(e instanceof Error ? e.message : "Could not add to cart");
      setTimeout(() => setToast(null), 3000);
    }
  };

  const storeOpenNow = appSettings ? isStoreOpenNow(appSettings) : true;
  const deliveryFee = appSettings?.deliveryFee ?? 30;

  return (
    <main id="main-content" className="bg-cream">
      {/* Header hero */}
      <section className="bg-charcoal py-10 text-white">
        <div className="site-shell">
          <div className="flex flex-wrap items-center gap-3 text-xs font-black uppercase tracking-[0.18em] text-orange">
            <span className="inline-flex items-center gap-2 rounded-full border border-orange/30 bg-orange/10 px-3 py-1.5">
              <Flame size={14} aria-hidden="true" /> Same kitchen • Same prices • Same Supabase
            </span>
            {appSettings && (
              <span className={`inline-flex items-center gap-2 rounded-full px-3 py-1.5 ${storeOpenNow ? "bg-leaf text-white" : "bg-white/10 text-white/70"}`}>
                <Store size={14} aria-hidden="true" /> {storeOpenNow ? `Open now • Closes ${appSettings.closingTime}` : `Closed • Opens ${appSettings.openingTime}`}
              </span>
            )}
          </div>
          <div className="mt-6 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <h1 className="font-display text-5xl font-black uppercase leading-none tracking-[-0.05em] sm:text-6xl">Menu & Ordering</h1>
              <p className="mt-3 max-w-xl text-sm leading-7 text-white/60 sm:text-base">Browse the current menu directly from the same database the app and kitchen use. Prices are validated on the server at checkout.</p>
            </div>
            <div className="flex flex-wrap gap-3">
              <div className="inline-flex items-center gap-2 rounded-full bg-white/10 px-4 py-2 text-xs font-bold text-white/70">
                <Truck size={16} /> Delivery +R{deliveryFee.toFixed(0)}
              </div>
              <Link href="/cart/" className="button button-primary">
                <ShoppingBasket size={18} /> View cart {count > 0 ? `(${count})` : ""}
              </Link>
            </div>
          </div>

          {/* Search + category chips */}
          <div className="mt-8 flex flex-col gap-4 sm:flex-row sm:items-center">
            <label className="relative flex-1">
              <Search size={18} className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-white/40" aria-hidden="true" />
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search menu — e.g. Wors, Chicken, Cold Drink"
                className="h-12 w-full rounded-full border border-white/12 bg-white/10 pl-11 pr-4 text-sm font-semibold text-white placeholder:text-white/40 focus:border-orange/60 focus:outline-none"
              />
            </label>
            {!appSettings?.storeOpen && <span className="rounded-full bg-amber-500 px-4 py-2 text-xs font-extrabold text-charcoal">Ordering paused by restaurant</span>}
          </div>

          <div className="mt-5 flex flex-wrap gap-2">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setActiveCategory(cat)}
                className={`rounded-full px-4 py-2 text-xs font-extrabold transition ${activeCategory === cat ? "bg-orange text-charcoal" : "border border-white/15 bg-white/10 text-white/80 hover:bg-white/15"}`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* Menu grid */}
      <section className="section-pad">
        <div className="site-shell">
          {loading ? (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="h-80 animate-pulse rounded-[1.75rem] bg-muted" />
              ))}
            </div>
          ) : error ? (
            <div className="rounded-[1.75rem] border border-amber-200 bg-amber-50 p-8 text-center">
              <p className="font-extrabold text-amber-900">Menu unavailable</p>
              <p className="mx-auto mt-2 max-w-xl text-sm leading-6 text-amber-900/70">{error}</p>
              <p className="mt-2 text-xs text-amber-900/50">If you are the owner, check Vercel → Project Settings → Environment Variables → NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY and redeploy.</p>
            </div>
          ) : filtered.length === 0 ? (
            <div className="rounded-[1.75rem] border border-black/8 bg-white p-10 text-center shadow-sm">
              <p className="font-extrabold text-charcoal">No items match &ldquo;{query}&rdquo; in {activeCategory}.</p>
              <button onClick={() => { setQuery(""); setActiveCategory("All"); }} className="button button-dark mt-4">Clear filters</button>
            </div>
          ) : (
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {filtered.map((item) => (
                <article key={item.id} className="group flex flex-col overflow-hidden rounded-[1.75rem] border border-black/8 bg-white shadow-[0_14px_36px_rgba(48,22,12,0.08)]">
                  <div className="relative aspect-[1.15] overflow-hidden bg-muted">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={item.imagePath}
                      alt={item.name}
                      loading="lazy"
                      className="h-full w-full object-cover transition duration-500 group-hover:scale-[1.03]"
                    />
                    <div className="absolute left-3 top-3 flex gap-2">
                      <span className="rounded-full bg-charcoal px-3 py-1 text-[0.68rem] font-black uppercase tracking-[0.12em] text-white">{item.category}</span>
                      {!item.isAvailable && <span className="rounded-full bg-amber-500 px-3 py-1 text-[0.68rem] font-black uppercase text-charcoal">Unavailable</span>}
                    </div>
                    <span className="absolute bottom-3 right-3 inline-flex items-center gap-1.5 rounded-full bg-white px-3 py-1.5 text-xs font-extrabold text-charcoal shadow">
                      <Clock3 size={14} className="text-peri-red" /> {item.prepMinutes} min
                    </span>
                  </div>
                  <div className="flex flex-1 flex-col p-5">
                    <h3 className="font-display text-xl font-black uppercase leading-none tracking-[-0.02em]">{item.name}</h3>
                    <p className="mt-2 line-clamp-2 text-xs leading-6 text-ash">{item.description || "Flame-grilled favourite."}</p>
                    {item.addOns.length > 0 && <p className="mt-2 text-[0.68rem] font-bold uppercase tracking-[0.12em] text-orange">+ {item.addOns.map((a) => a.name).join(", ")}</p>}
                    <div className="mt-4 flex items-end justify-between gap-3">
                      <span className="font-display text-2xl font-black tracking-[-0.02em]">R{item.price.toFixed(0)}</span>
                      <button
                        onClick={() => openCustomize(item)}
                        disabled={!item.isAvailable}
                        className="button button-primary button-sm disabled:opacity-40"
                      >
                        Add
                        <ArrowRight size={16} />
                      </button>
                    </div>
                    <p className="mt-2 text-[0.68rem] font-semibold text-ash">Price validated on server at checkout.</p>
                  </div>
                </article>
              ))}
            </div>
          )}

          <div className="mt-10 flex flex-wrap items-center justify-between gap-4 rounded-[1.75rem] border border-black/8 bg-white p-5 shadow-sm">
            <p className="text-sm font-bold text-ash">
              Need help? <a href="https://wa.me/27736423549" target="_blank" rel="noreferrer" className="text-peri-red underline">Chat on WhatsApp</a> • Orders appear instantly in the restaurant system (same Orders table as the app).
            </p>
            <Link href="/cart/" className="button button-dark">Go to cart <ShoppingBasket size={16} /></Link>
          </div>
        </div>
      </section>

      {/* Customization dialog */}
      {customizing && (
        <div className="fixed inset-0 z-[60] grid place-items-center bg-charcoal/60 p-4 backdrop-blur-sm">
          <div className="max-h-[90svh] w-full max-w-xl overflow-auto rounded-[1.75rem] bg-white p-6 shadow-2xl">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.18em] text-peri-red">{customizing.category}</p>
                <h2 className="mt-1 font-display text-3xl font-black uppercase tracking-[-0.03em]">{customizing.name}</h2>
                <p className="mt-1 text-sm leading-6 text-ash">{customizing.description}</p>
                <p className="mt-2 font-display text-2xl font-black">R{customizing.price.toFixed(0)}</p>
              </div>
              <button onClick={() => setCustomizing(null)} className="grid size-10 place-items-center rounded-full border border-black/10 bg-white text-ash hover:bg-muted">✕</button>
            </div>

            {customizing.spiceLevels.length > 1 && (
              <div className="mt-6">
                <p className="text-xs font-black uppercase tracking-[0.14em] text-ash">Spice level</p>
                <div className="mt-2 flex flex-wrap gap-2">
                  {customizing.spiceLevels.map((lvl) => (
                    <button
                      key={lvl}
                      onClick={() => setCustom((p) => ({ ...p, spiceLevel: lvl }))}
                      className={`rounded-full px-4 py-2 text-sm font-extrabold ${custom.spiceLevel === lvl ? "bg-charcoal text-white" : "border border-black/10 bg-white text-charcoal"}`}
                    >
                      {lvl}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {customizing.addOns.length > 0 && (
              <div className="mt-6">
                <p className="text-xs font-black uppercase tracking-[0.14em] text-ash">Add-ons (optional)</p>
                <div className="mt-3 grid gap-2">
                  {customizing.addOns.map((ad) => {
                    const selected = custom.selectedAddOns.some((s) => s.name === ad.name);
                    return (
                      <label key={ad.name} className={`flex items-center justify-between gap-3 rounded-2xl border p-3 ${selected ? "border-orange bg-orange/10" : "border-black/10 bg-white"}`}>
                        <span className="flex items-center gap-3">
                          <input type="checkbox" checked={selected} onChange={() => toggleAddOn(ad.name, ad.price)} className="size-5 accent-peri-red" />
                          <span className="text-sm font-extrabold text-charcoal">{ad.name}</span>
                        </span>
                        <span className="text-sm font-black text-ash">+ R{ad.price.toFixed(0)}</span>
                      </label>
                    );
                  })}
                </div>
              </div>
            )}

            <div className="mt-6">
              <label className="text-xs font-black uppercase tracking-[0.14em] text-ash">Notes (optional, max 500)</label>
              <textarea
                value={custom.notes}
                onChange={(e) => setCustom((p) => ({ ...p, notes: e.target.value.slice(0, 500) }))}
                placeholder="e.g. No onions, extra sauce on the side"
                rows={3}
                className="mt-2 w-full rounded-2xl border border-black/10 bg-white p-3 text-sm focus:border-orange/60 focus:outline-none"
              />
            </div>

            <div className="mt-6 flex items-center justify-between gap-4">
              <div className="flex items-center gap-2">
                <button onClick={() => setCustom((p) => ({ ...p, quantity: Math.max(1, p.quantity - 1) }))} className="grid size-10 place-items-center rounded-full border border-black/10 bg-white text-lg font-black">−</button>
                <span className="min-w-10 text-center font-display text-xl font-black">{custom.quantity}</span>
                <button onClick={() => setCustom((p) => ({ ...p, quantity: Math.min(50, p.quantity + 1) }))} className="grid size-10 place-items-center rounded-full border border-black/10 bg-white text-lg font-black">+</button>
              </div>
              <div className="text-right">
                <p className="text-xs font-bold uppercase tracking-[0.14em] text-ash">Total for this line</p>
                <p className="font-display text-2xl font-black">
                  R{((customizing.price + custom.selectedAddOns.reduce((s, a) => s + a.price, 0)) * custom.quantity).toFixed(2)}
                </p>
              </div>
            </div>

            <div className="mt-6 flex gap-3">
              <button onClick={() => setCustomizing(null)} className="button flex-1 border border-black/10 bg-white text-charcoal">Cancel</button>
              <button onClick={handleAdd} className="button button-primary flex-1">Add to cart • R{((customizing.price + custom.selectedAddOns.reduce((s, a) => s + a.price, 0)) * custom.quantity).toFixed(0)}</button>
            </div>
          </div>
        </div>
      )}

      {toast && (
        <div className="fixed bottom-6 left-1/2 z-[70] -translate-x-1/2 rounded-full bg-charcoal px-5 py-3 text-sm font-extrabold text-white shadow-2xl">
          {toast} • <Link href="/cart/" className="underline">View cart</Link>
        </div>
      )}
    </main>
  );
}

