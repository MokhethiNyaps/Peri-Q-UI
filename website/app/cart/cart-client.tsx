"use client";

import Link from "next/link";
import { ArrowRight, Minus, Plus, Trash2 } from "lucide-react";
import { useCart } from "@/lib/cart";
import { useEffect, useState } from "react";
import { fetchMenu, type AppSettings } from "@/lib/menu";
import { isSupabaseConfigured } from "@/lib/supabase";

export default function CartClient() {
  const { entries, inc, dec, remove, subtotal, clear } = useCart();
  const [settings, setSettings] = useState<AppSettings | null>(null);

  useEffect(() => {
    if (!isSupabaseConfigured()) return;
    void fetchMenu().then(({ appSettings }) => setSettings(appSettings)).catch(() => {});
  }, []);

  const deliveryFee = settings?.deliveryFee ?? 30;
  const hasItems = entries.length > 0;

  return (
    <main id="main-content" className="bg-cream">
      <section className="bg-charcoal py-10 text-white">
        <div className="site-shell">
          <h1 className="font-display text-5xl font-black uppercase tracking-[-0.05em]">Your Cart</h1>
          <p className="mt-3 max-w-xl text-sm leading-7 text-white/60">Adjust quantities. Totals without delivery fee are shown below; delivery fee is added at checkout if you choose Home Delivery. Prices are re-validated on the server.</p>
        </div>
      </section>

      <section className="section-pad">
        <div className="site-shell grid gap-8 lg:grid-cols-[1.7fr_0.9fr]">
          <div>
            {!hasItems ? (
              <div className="rounded-[1.75rem] border border-black/8 bg-white p-10 text-center shadow-sm">
                <p className="font-display text-2xl font-black uppercase">Cart is empty</p>
                <p className="mt-2 text-sm text-ash">Browse the menu and add your favourites. Same menu the kitchen sees, same prices.</p>
                <Link href="/menu/" className="button button-primary mt-6">Browse menu <ArrowRight size={16} /></Link>
              </div>
            ) : (
              <div className="grid gap-4">
                {entries.map((e) => {
                  const addOnTotal = e.selectedAddOns.reduce((s, a) => s + a.price, 0);
                  const line = (e.item.price + addOnTotal) * e.quantity;
                  return (
                    <article key={e.id} className="flex gap-4 rounded-[1.5rem] border border-black/8 bg-white p-4 shadow-sm">
                      <img src={e.item.imagePath} alt={e.item.name} className="size-20 shrink-0 rounded-2xl object-cover" />
                      <div className="min-w-0 flex-1">
                        <div className="flex items-start justify-between gap-3">
                          <div>
                            <h3 className="font-display text-lg font-black uppercase leading-none">{e.item.name}</h3>
                            <p className="mt-1 text-xs font-semibold text-ash">{e.item.category} • R{e.item.price.toFixed(0)} each {e.spiceLevel ? `• ${e.spiceLevel}` : ""}</p>
                            {e.selectedAddOns.length > 0 && <p className="mt-1 text-xs text-peri-red">+ {e.selectedAddOns.map((a) => `${a.name} (R${a.price.toFixed(0)})`).join(", ")}</p>}
                            {e.notes && <p className="mt-1 line-clamp-2 text-xs italic text-ash/70">&ldquo;{e.notes}&rdquo;</p>}
                          </div>
                          <button onClick={() => remove(e.id)} aria-label="Remove item" className="grid size-9 place-items-center rounded-full border border-black/10 bg-white text-ash hover:text-peri-red">
                            <Trash2 size={16} />
                          </button>
                        </div>
                        <div className="mt-3 flex items-center justify-between gap-3">
                          <div className="flex items-center gap-2">
                            <button onClick={() => dec(e.id)} className="grid size-9 place-items-center rounded-full border border-black/10 bg-white"><Minus size={16} /></button>
                            <span className="min-w-8 text-center font-black">{e.quantity}</span>
                            <button onClick={() => inc(e.id)} className="grid size-9 place-items-center rounded-full border border-black/10 bg-white"><Plus size={16} /></button>
                          </div>
                          <span className="font-display text-xl font-black">R{line.toFixed(2)}</span>
                        </div>
                      </div>
                    </article>
                  );
                })}
                <button onClick={() => clear()} className="self-start rounded-full border border-black/10 bg-white px-4 py-2 text-xs font-extrabold text-ash hover:bg-muted">Clear cart</button>
              </div>
            )}
          </div>

          <aside className="h-fit rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm lg:sticky lg:top-24">
            <h2 className="font-display text-xl font-black uppercase tracking-[-0.02em]">Order summary</h2>
            <div className="mt-4 grid gap-3 text-sm">
              <div className="flex justify-between"><span className="text-ash">Subtotal</span><span className="font-black">R{subtotal.toFixed(2)}</span></div>
              <div className="flex justify-between"><span className="text-ash">Delivery fee (if delivery)</span><span className="font-black">R{deliveryFee.toFixed(2)}</span></div>
              <div className="h-px bg-black/8" />
              <div className="flex justify-between text-base"><span className="font-extrabold">Estimated pickup total</span><span className="font-black">R{subtotal.toFixed(2)}</span></div>
              <div className="flex justify-between text-base text-peri-red"><span className="font-extrabold">Estimated delivery total</span><span className="font-black">R{(subtotal + deliveryFee).toFixed(2)}</span></div>
              <p className="rounded-2xl bg-muted p-3 text-xs leading-5 text-ash">Final total is computed on the server from trusted menu data. If a price changed before you checkout, you’ll see &ldquo;Price changed&rdquo; and can retry — cart stays saved.</p>
            </div>

            <div className="mt-6 grid gap-3">
              <Link href="/checkout/" className={`button button-primary w-full justify-center ${!hasItems ? "pointer-events-none opacity-40" : ""}`}>
                Proceed to checkout <ArrowRight size={18} />
              </Link>
              <Link href="/menu/" className="button w-full justify-center border border-black/10 bg-white text-charcoal">Continue shopping</Link>
            </div>

            <p className="mt-4 text-center text-xs font-semibold text-ash/60">Website and app share the same Supabase orders table — kitchen sees website orders instantly.</p>
          </aside>
        </div>
      </section>
    </main>
  );
}
