"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Clock3, Flame, Minus, Plus, Search, ShoppingBasket, Truck, X } from "lucide-react";
import { OpenBadge } from "@/components/home/open-badge";
import { useCart } from "@/lib/cart";
import {
  fetchMenu,
  visibleCategories,
  type AppSettings,
  type MenuCategory,
  type MenuItem,
} from "@/lib/menu";
import { flyToCart } from "@/lib/motion";
import { plateCutoutFor } from "@/lib/plates";
import { isSupabaseConfigured } from "@/lib/supabase";

type Customization = {
  spiceLevel?: string | null;
  notes: string;
  selectedAddOns: { name: string; price: number }[];
  quantity: number;
};

type InitialMenu = { items: MenuItem[]; categories: MenuCategory[]; appSettings: AppSettings } | null;

const ALL = "All";

export default function MenuClient({ initial = null }: { initial?: InitialMenu }) {
  const { add } = useCart();
  const params = useSearchParams();
  const [items, setItems] = useState<MenuItem[]>(initial?.items ?? []);
  const [catalog, setCatalog] = useState<MenuCategory[]>(initial?.categories ?? []);
  const [appSettings, setAppSettings] = useState<AppSettings | null>(initial?.appSettings ?? null);
  const [activeCategory, setActiveCategory] = useState(ALL);
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(!initial);
  const [error, setError] = useState<string | null>(null);
  const [customizing, setCustomizing] = useState<MenuItem | null>(null);
  const [custom, setCustom] = useState<Customization>({ notes: "", selectedAddOns: [], quantity: 1, spiceLevel: null });
  const [toast, setToast] = useState<string | null>(null);
  const deepLinkHandled = useRef(false);
  const returnFocus = useRef<HTMLElement | null>(null);
  const closeButton = useRef<HTMLButtonElement>(null);
  const addButton = useRef<HTMLButtonElement>(null);

  const load = useCallback(async (showSpinner: boolean) => {
    if (!isSupabaseConfigured()) {
      if (showSpinner) {
        setError("The menu is not available right now. Please try again shortly or order on WhatsApp.");
        setLoading(false);
      }
      return;
    }
    try {
      if (showSpinner) setLoading(true);
      const { items: fetchedItems, categories: fetchedCats, appSettings: settings } = await fetchMenu();
      setItems(fetchedItems);
      setCatalog(fetchedCats);
      setAppSettings(settings);
      setError(null);
    } catch {
      // Keep any menu already on screen; only show the error when there is nothing to show.
      if (showSpinner) setError("The menu could not load. Check your connection and try again.");
    } finally {
      if (showSpinner) setLoading(false);
    }
  }, []);

  useEffect(() => {
    // With a server-rendered menu, refresh quietly; otherwise show the loading state.
    void load(!initial);
  }, [initial, load]);

  const categories = useMemo(() => [ALL, ...visibleCategories(catalog, items)], [catalog, items]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return items.filter((it) => {
      if (activeCategory !== ALL && it.category !== activeCategory) return false;
      if (q && !`${it.name} ${it.description} ${it.category}`.toLowerCase().includes(q)) return false;
      return true;
    });
  }, [items, activeCategory, query]);

  const openCustomize = useCallback((item: MenuItem, opener?: HTMLElement | null) => {
    returnFocus.current = opener ?? (document.activeElement as HTMLElement | null);
    setCustomizing(item);
    setCustom({
      quantity: 1,
      notes: "",
      spiceLevel: item.spiceLevels?.[0] ?? null,
      selectedAddOns: [],
    });
  }, []);

  const closeCustomize = useCallback(() => {
    setCustomizing(null);
    returnFocus.current?.focus?.();
  }, []);

  // Links such as /menu/?item=<id> (from the homepage) open that dish, and
  // /menu/?category=<name> selects a category.
  useEffect(() => {
    if (deepLinkHandled.current || items.length === 0) return;
    deepLinkHandled.current = true;
    const category = params.get("category");
    if (category && categories.includes(category)) setActiveCategory(category);
    const itemId = params.get("item");
    const item = itemId ? items.find((it) => it.id === itemId) : undefined;
    if (item?.isAvailable) openCustomize(item);
  }, [items, categories, params, openCustomize]);

  useEffect(() => {
    if (!customizing) return;
    closeButton.current?.focus();
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") closeCustomize();
    };
    document.addEventListener("keydown", onKey);
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = overflow;
    };
  }, [customizing, closeCustomize]);

  const toggleAddOn = (name: string, price: number) => {
    setCustom((prev) => {
      const exists = prev.selectedAddOns.some((a) => a.name === name);
      return {
        ...prev,
        selectedAddOns: exists ? prev.selectedAddOns.filter((a) => a.name !== name) : [...prev.selectedAddOns, { name, price }],
      };
    });
  };

  const showToast = (message: string, ms: number) => {
    setToast(message);
    window.setTimeout(() => setToast(null), ms);
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
      flyToCart(addButton.current);
      showToast(`${customizing.name} ×${custom.quantity} added to cart`, 2600);
      closeCustomize();
    } catch (e) {
      showToast(e instanceof Error ? e.message : "Could not add to cart", 3000);
    }
  };

  const deliveryFee = appSettings?.deliveryFee ?? 30;
  const lineTotal = customizing
    ? (customizing.price + custom.selectedAddOns.reduce((s, a) => s + a.price, 0)) * custom.quantity
    : 0;
  const sheetCutout = customizing ? plateCutoutFor(customizing.imagePath) : null;

  return (
    <main id="main-content" className="min-h-[70svh] bg-soot text-cream">
      <section className="stage stage-glow grill-lines overflow-hidden border-b border-white/6 pb-6 pt-10">
        <div className="site-shell">
          <div className="flex flex-wrap items-center gap-3">
            <OpenBadge settings={appSettings} />
            {appSettings?.deliveryAvailable !== false && (
              <span className="inline-flex min-h-9 items-center gap-2 rounded-full border border-white/12 bg-white/6 px-3.5 text-xs font-extrabold text-smoke">
                <Truck size={15} aria-hidden="true" /> Delivery +R{deliveryFee.toFixed(0)}
              </span>
            )}
            {appSettings && !appSettings.storeOpen && (
              <span className="inline-flex min-h-9 items-center rounded-full bg-amber-500 px-3.5 text-xs font-extrabold text-charcoal">
                Ordering is paused by the restaurant
              </span>
            )}
          </div>
          <div className="mt-6 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <h1 className="font-display text-6xl font-extrabold uppercase leading-[0.9] sm:text-7xl">The menu</h1>
              <p className="mt-3 max-w-xl text-sm leading-7 text-smoke sm:text-base">
                Every plate is flame-grilled to order. Pick a dish, set your spice level and add it to your cart.
              </p>
            </div>
            <label className="relative w-full lg:max-w-sm">
              <span className="sr-only">Search the menu</span>
              <Search size={18} className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-white/45" aria-hidden="true" />
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                type="search"
                placeholder="Search: wors, liver, chicken…"
                className="h-12 w-full rounded-full border border-white/12 bg-white/6 pl-11 pr-4 text-sm font-semibold text-cream placeholder:text-white/45 focus:border-orange/60"
              />
            </label>
          </div>
        </div>
      </section>

      <nav aria-label="Menu categories" className="sticky top-[4.5rem] z-40 border-b border-white/6 bg-soot/92 backdrop-blur-xl">
        <div className="site-shell flex gap-2 overflow-x-auto py-3 [scrollbar-width:none]">
          {categories.map((cat) => (
            <button key={cat} type="button" aria-pressed={activeCategory === cat} onClick={() => setActiveCategory(cat)} className="chip">
              {cat}
            </button>
          ))}
        </div>
      </nav>

      <section className="pb-28 pt-8 md:pb-20">
        <div className="site-shell">
          {loading ? (
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4" aria-busy="true" aria-label="Loading the menu">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="h-96 animate-pulse rounded-[1.25rem] bg-charcoal" />
              ))}
            </div>
          ) : error ? (
            <div className="rounded-[1.25rem] border border-white/10 bg-charcoal p-8 text-center">
              <p className="font-extrabold text-cream">Menu unavailable</p>
              <p className="mx-auto mt-2 max-w-xl text-sm leading-6 text-smoke">{error}</p>
              <button type="button" onClick={() => void load(true)} className="button button-primary mt-5">
                Try again
              </button>
            </div>
          ) : filtered.length === 0 ? (
            <div className="rounded-[1.25rem] border border-white/10 bg-charcoal p-10 text-center">
              <p className="font-extrabold text-cream">
                No dishes match &ldquo;{query}&rdquo;{activeCategory !== ALL ? ` in ${activeCategory}` : ""}.
              </p>
              <button
                type="button"
                onClick={() => {
                  setQuery("");
                  setActiveCategory(ALL);
                }}
                className="button button-ghost mt-4"
              >
                Clear filters
              </button>
            </div>
          ) : (
            <ul className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {filtered.map((item, index) => (
                <li key={item.id}>
                  <article className="dish-card h-full">
                    <div className="relative aspect-square overflow-hidden bg-black/30">
                      <Image
                        src={item.imagePath}
                        alt={item.name}
                        fill
                        sizes="(min-width: 1280px) 290px, (min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
                        priority={index < 4}
                        className="dish-photo object-cover"
                      />
                      <div className="absolute left-3 top-3 flex flex-wrap gap-2">
                        <span className="rounded-full bg-soot/80 px-3 py-1 text-[0.68rem] font-black uppercase tracking-[0.12em] text-orange backdrop-blur">
                          {item.category}
                        </span>
                        {!item.isAvailable && (
                          <span className="rounded-full bg-amber-500 px-3 py-1 text-[0.68rem] font-black uppercase text-charcoal">Unavailable</span>
                        )}
                      </div>
                      <span className="absolute bottom-3 right-3 inline-flex items-center gap-1.5 rounded-full bg-soot/80 px-3 py-1.5 text-xs font-extrabold text-cream backdrop-blur">
                        <Clock3 size={14} className="text-orange" aria-hidden="true" /> {item.prepMinutes} min
                      </span>
                    </div>
                    <div className="flex flex-1 flex-col p-5">
                      <h2 className="text-lg font-extrabold leading-6 text-cream">{item.name}</h2>
                      {item.description && item.description !== item.name && (
                        <p className="mt-2 line-clamp-2 text-sm leading-6 text-smoke">{item.description}</p>
                      )}
                      {item.addOns.length > 0 && (
                        <p className="mt-2 text-[0.7rem] font-bold uppercase tracking-[0.12em] text-orange">
                          + {item.addOns.map((a) => a.name).join(", ")}
                        </p>
                      )}
                      <div className="mt-auto flex items-end justify-between gap-3 pt-4">
                        <span className="price-tag text-3xl text-cream">R{item.price.toFixed(0)}</span>
                        <button
                          type="button"
                          onClick={(event) => openCustomize(item, event.currentTarget)}
                          disabled={!item.isAvailable}
                          aria-label={`Add ${item.name}`}
                          className="button button-primary button-sm disabled:opacity-40"
                        >
                          <Plus size={16} aria-hidden="true" />
                          Add
                        </button>
                      </div>
                    </div>
                  </article>
                </li>
              ))}
            </ul>
          )}

          <div className="mt-10 flex flex-wrap items-center justify-between gap-4 rounded-[1.25rem] border border-white/8 bg-charcoal p-5">
            <p className="text-sm font-semibold text-smoke">
              Questions about a dish?{" "}
              <a href="https://wa.me/27736423549" target="_blank" rel="noreferrer" className="font-extrabold text-orange underline">
                Chat on WhatsApp
              </a>
            </p>
            <Link href="/cart/" className="button button-ghost">
              Go to cart <ShoppingBasket size={16} aria-hidden="true" />
            </Link>
          </div>
        </div>
      </section>

      {customizing && (
        <div
          className="sheet-backdrop"
          onClick={(event) => {
            if (event.target === event.currentTarget) closeCustomize();
          }}
        >
          <div role="dialog" aria-modal="true" aria-labelledby="dish-sheet-title" className="sheet">
            <div className="grid md:grid-cols-[0.9fr_1.1fr]">
              <div className="relative grid place-items-center bg-soot p-6 md:rounded-l-[1.5rem]">
                <div className="plate-halo" aria-hidden="true" />
                {sheetCutout ? (
                  <Image src={sheetCutout} alt={customizing.name} width={600} height={600} sizes="(min-width: 768px) 380px, 70vw" className="plate h-auto w-[70%] md:w-full" />
                ) : (
                  <Image
                    src={customizing.imagePath}
                    alt={customizing.name}
                    width={600}
                    height={600}
                    sizes="(min-width: 768px) 380px, 70vw"
                    className="plate aspect-square h-auto w-[70%] rounded-[1.25rem] object-cover md:w-full"
                  />
                )}
              </div>

              <div className="p-6 sm:p-8">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <p className="text-xs font-black uppercase tracking-[0.18em] text-orange">{customizing.category}</p>
                    <h2 id="dish-sheet-title" className="mt-1 font-display text-4xl font-extrabold uppercase leading-[0.95] text-cream">
                      {customizing.name}
                    </h2>
                    {customizing.description && customizing.description !== customizing.name && (
                      <p className="mt-2 text-sm leading-6 text-smoke">{customizing.description}</p>
                    )}
                    <p className="price-tag mt-3 text-3xl text-cream">R{customizing.price.toFixed(0)}</p>
                  </div>
                  <button
                    ref={closeButton}
                    type="button"
                    onClick={closeCustomize}
                    aria-label="Close"
                    className="grid size-11 shrink-0 place-items-center rounded-full border border-white/15 text-cream hover:bg-white/8"
                  >
                    <X size={18} aria-hidden="true" />
                  </button>
                </div>

                {customizing.spiceLevels.length > 1 && (
                  <fieldset className="mt-6">
                    <legend className="flex items-center gap-2 text-xs font-black uppercase tracking-[0.14em] text-smoke">
                      <Flame size={14} className="text-orange" aria-hidden="true" /> Spice level
                    </legend>
                    <div className="mt-3 flex flex-wrap gap-2">
                      {customizing.spiceLevels.map((lvl) => (
                        <button
                          key={lvl}
                          type="button"
                          aria-pressed={custom.spiceLevel === lvl}
                          onClick={() => setCustom((p) => ({ ...p, spiceLevel: lvl }))}
                          className="sheet-option"
                        >
                          {lvl}
                        </button>
                      ))}
                    </div>
                  </fieldset>
                )}

                {customizing.addOns.length > 0 && (
                  <fieldset className="mt-6">
                    <legend className="text-xs font-black uppercase tracking-[0.14em] text-smoke">Add-ons (optional)</legend>
                    <div className="mt-3 grid gap-2">
                      {customizing.addOns.map((ad) => {
                        const selected = custom.selectedAddOns.some((s) => s.name === ad.name);
                        return (
                          <label
                            key={ad.name}
                            className={`flex min-h-12 items-center justify-between gap-3 rounded-2xl border p-3 ${
                              selected ? "border-orange bg-orange/12" : "border-white/14"
                            }`}
                          >
                            <span className="flex items-center gap-3">
                              <input type="checkbox" checked={selected} onChange={() => toggleAddOn(ad.name, ad.price)} className="size-5 accent-peri-red" />
                              <span className="text-sm font-extrabold">{ad.name}</span>
                            </span>
                            <span className="text-sm font-black text-smoke">+ R{ad.price.toFixed(0)}</span>
                          </label>
                        );
                      })}
                    </div>
                  </fieldset>
                )}

                <div className="mt-6">
                  <label htmlFor="dish-notes" className="text-xs font-black uppercase tracking-[0.14em] text-smoke">
                    Notes for the kitchen (optional)
                  </label>
                  <textarea
                    id="dish-notes"
                    value={custom.notes}
                    onChange={(e) => setCustom((p) => ({ ...p, notes: e.target.value.slice(0, 500) }))}
                    placeholder="e.g. No onions, extra sauce on the side"
                    rows={2}
                    maxLength={500}
                    className="field-dark mt-2 text-sm"
                  />
                </div>

                <div className="mt-6 flex items-center justify-between gap-4">
                  <div className="flex items-center gap-2" role="group" aria-label="Quantity">
                    <button
                      type="button"
                      aria-label="One less"
                      onClick={() => setCustom((p) => ({ ...p, quantity: Math.max(1, p.quantity - 1) }))}
                      className="stepper-button"
                    >
                      <Minus size={16} aria-hidden="true" />
                    </button>
                    <span className="price-tag min-w-10 text-center text-2xl" aria-live="polite">
                      {custom.quantity}
                    </span>
                    <button
                      type="button"
                      aria-label="One more"
                      onClick={() => setCustom((p) => ({ ...p, quantity: Math.min(50, p.quantity + 1) }))}
                      className="stepper-button"
                    >
                      <Plus size={16} aria-hidden="true" />
                    </button>
                  </div>
                  <div className="text-right">
                    <p className="text-xs font-bold uppercase tracking-[0.14em] text-smoke">Line total</p>
                    <p className="price-tag text-3xl text-cream">R{lineTotal.toFixed(2)}</p>
                  </div>
                </div>

                <button ref={addButton} type="button" onClick={handleAdd} className="button button-primary mt-6 w-full">
                  <ShoppingBasket size={18} aria-hidden="true" />
                  Add to cart · R{lineTotal.toFixed(0)}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div aria-live="polite" className="pointer-events-none fixed inset-x-0 bottom-24 z-[70] flex justify-center px-4 md:bottom-6">
        {toast && (
          <div className="pointer-events-auto rounded-full bg-cream px-5 py-3 text-sm font-extrabold text-charcoal shadow-2xl">
            {toast} ·{" "}
            <Link href="/cart/" className="text-peri-red underline">
              View cart
            </Link>
          </div>
        )}
      </div>
    </main>
  );
}
