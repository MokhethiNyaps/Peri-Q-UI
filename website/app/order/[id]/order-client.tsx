"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { ArrowLeft, CheckCircle2, Clock3, CreditCard, MapPin, Phone, Truck, User, XCircle } from "lucide-react";
import { createBrowserClient } from "@/lib/supabase";
import { ensureAnonSession } from "@/lib/auth";

type OrderRow = {
  id: string;
  order_number: number;
  customer_name: string;
  customer_phone: string;
  order_type: string;
  payment_method: string;
  total_price: number;
  status: string;
  estimated_minutes: number;
  delivery_address: string | null;
  created_at: string;
  yoco_checkout_id: string | null;
  payment_status: string;
  paid_at: string | null;
  yoco_mode: string | null;
};

type OrderItemRow = {
  item_name: string;
  unit_price: number;
  quantity: number;
  item_category: string;
  selected_add_ons: { name: string; price: number }[] | null;
  notes: string | null;
  spice_level: string | null;
};

export default function OrderClient({ orderId }: { orderId: string }) {
  const search = useSearchParams();
  const checkout = search.get("checkout"); // success | cancel | failure
  const isNew = search.get("new") === "1";
  const [order, setOrder] = useState<OrderRow | null>(null);
  const [items, setItems] = useState<OrderItemRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [retryingYoco, setRetryingYoco] = useState(false);
  const [info, setInfo] = useState<string | null>(null);

  const fetchOrder = async () => {
    try {
      setLoading(true);
      const supa = createBrowserClient();
      // Ensure at least an anon session so RLS `orders_select_owner_or_admin` passes (owner OR admin)
      await ensureAnonSession();
      const { data, error: err } = await supa
        .from("orders")
        .select(
          "id,order_number,customer_name,customer_phone,order_type,payment_method,total_price,status,estimated_minutes,delivery_address,created_at,yoco_checkout_id,payment_status,paid_at,yoco_mode,order_items(item_name,unit_price,quantity,item_category,selected_add_ons,notes,spice_level)",
        )
        .eq("id", orderId)
        .maybeSingle();

      if (err) throw err;
      if (!data) {
        setError("Order not found. It may belong to another device/account. If you ordered as guest on a different browser, the kitchen still has it — contact the restaurant with your order number.");
        setLoading(false);
        return;
      }
      const row = data as unknown as OrderRow & { order_items: OrderItemRow[] };
      setOrder(row);
      setItems(row.order_items ?? []);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load order.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchOrder();
    // Realtime poll fallback every 8s while pending payment?
    const t = setInterval(() => {
      // only poll if payment pending/paid not yet reflected?
      void fetchOrder();
    }, 8000);
    return () => clearInterval(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [orderId]);

  const retryYocoCheckout = async () => {
    if (!order) return;
    setRetryingYoco(true);
    setInfo(null);
    try {
      const anon = await ensureAnonSession();
      const supa = createBrowserClient();
      const { data: sess } = await supa.auth.getSession();
      const token = sess.session?.access_token ?? anon?.accessToken ?? null;
      const res = await fetch("/api/yoco/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json", ...(token ? { Authorization: `Bearer ${token}` } : {}) },
        body: JSON.stringify({ orderId: order.id }),
      });
      const json = (await res.json().catch(() => ({}))) as { redirectUrl?: string; error?: string };
      if (!res.ok || !json.redirectUrl) throw new Error(json.error || "Could not start Yoco checkout.");
      window.location.href = json.redirectUrl;
    } catch (e) {
      setInfo(e instanceof Error ? e.message : "Failed to retry payment.");
    } finally {
      setRetryingYoco(false);
    }
  };

  if (loading) {
    return (
      <main id="main-content" className="bg-cream py-20">
        <div className="site-shell h-40 animate-pulse rounded-[1.75rem] bg-muted" />
      </main>
    );
  }

  if (error || !order) {
    return (
      <main id="main-content" className="bg-cream py-14">
        <div className="site-shell max-w-2xl rounded-[1.75rem] border border-amber-200 bg-amber-50 p-8">
          <h1 className="font-display text-3xl font-black uppercase">Order not found</h1>
          <p className="mt-3 text-sm leading-6 text-amber-900/80">{error}</p>
          <div className="mt-6 flex flex-wrap gap-3">
            <Link href="/menu/" className="button button-primary">Back to menu</Link>
            <Link href="/checkout/" className="button border border-black/10 bg-white text-charcoal">Checkout</Link>
          </div>
        </div>
      </main>
    );
  }

  const fulfillmentLabel: Record<string, string> = {
    pending: "Pending — kitchen received",
    preparing: "Preparing",
    ready: "Ready",
    completed: "Completed",
    cancelled: "Cancelled",
  };
  const paymentLabel: Record<string, string> = {
    unpaid: "Awaiting payment",
    pending: "Payment pending (awaiting Yoco confirmation)",
    paid: "Paid",
    failed: "Payment failed",
    cancelled: "Payment cancelled",
    expired: "Payment expired",
    refunded: "Refunded",
  };
  const isPaid = order.payment_status === "paid" || !!order.paid_at;
  const isYoco = order.payment_method === "yoco" || order.payment_method === "card";
  const yocoPending = isYoco && !isPaid && (order.payment_status === "pending" || order.payment_status === "unpaid");
  const showSuccessBanner = checkout === "success";
  const showCancelBanner = checkout === "cancel";
  const showFailureBanner = checkout === "failure";

  return (
    <main id="main-content" className="bg-cream">
      <section className="bg-charcoal py-10 text-white">
        <div className="site-shell">
          <Link href="/menu/" className="inline-flex items-center gap-2 text-sm font-bold text-white/60 hover:text-white">
            <ArrowLeft size={16} /> Back to menu
          </Link>
          <h1 className="mt-4 font-display text-5xl font-black uppercase tracking-[-0.05em]">Order #{order.order_number}</h1>
          <p className="mt-2 text-sm text-white/60">ID {order.id} • Created {new Date(order.created_at).toLocaleString("en-ZA", { timeZone: "Africa/Johannesburg" })}</p>
          <div className="mt-4 flex flex-wrap gap-2 text-xs font-black">
            <span className="rounded-full bg-white px-3 py-1.5 text-charcoal">{fulfillmentLabel[order.status] ?? order.status}</span>
            <span className={`rounded-full px-3 py-1.5 ${isPaid ? "bg-leaf text-white" : yocoPending ? "bg-amber-500 text-charcoal" : "bg-white/15 text-white"}`}>{paymentLabel[order.payment_status] ?? order.payment_status}</span>
            {order.yoco_mode && <span className="rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-white/80">Yoco {order.yoco_mode}</span>}
          </div>
        </div>
      </section>

      <section className="section-pad">
        <div className="site-shell grid gap-8 lg:grid-cols-[1.6fr_0.9fr]">
          <div className="grid gap-6">
            {isNew && (
              <div className="rounded-[1.75rem] border border-leaf/20 bg-leaf/10 p-5">
                <p className="flex items-center gap-2 font-display text-xl font-black uppercase text-leaf"><CheckCircle2 size={20} /> Order confirmed #{order.order_number}</p>
                <p className="mt-2 text-sm leading-6 text-ash">Estimated time <strong>{order.estimated_minutes} min</strong>. The restaurant sees this order in the same system as app orders (Supabase Realtime). Follow status updates here or contact the store.</p>
              </div>
            )}
            {showSuccessBanner && !isPaid && (
              <div className="rounded-[1.75rem] border border-amber-200 bg-amber-50 p-5">
                <p className="font-extrabold text-amber-900">Return from Yoco — verifying payment</p>
                <p className="mt-1 text-sm leading-6 text-amber-900/70">You returned from the secure checkout. Your order is only marked <em>paid</em> after the server verifies the Yoco webhook (usually seconds). Do not pay again yet — this page refreshes automatically. If it stays pending for a few minutes, check with the restaurant.</p>
              </div>
            )}
            {showCancelBanner && (
              <div className="rounded-[1.75rem] border border-black/10 bg-white p-5">
                <p className="flex items-center gap-2 font-extrabold text-charcoal"><XCircle size={18} className="text-ash" /> Payment was cancelled</p>
                <p className="mt-1 text-sm text-ash">You left the Yoco checkout without completing. Your order is saved — retry below when ready. No card was charged.</p>
              </div>
            )}
            {showFailureBanner && (
              <div className="rounded-[1.75rem] border border-red-200 bg-red-50 p-5">
                <p className="flex items-center gap-2 font-extrabold text-red-900"><XCircle size={18} /> Payment did not complete</p>
                <p className="mt-1 text-sm text-red-900/70">Card declined or checkout failed. Retry below or try another payment method.</p>
              </div>
            )}
            {info && <div className="rounded-2xl border border-black/10 bg-white p-4 text-sm font-bold text-charcoal">{info}</div>}

            {/* Yoco retry */}
            {yocoPending && (
              <div className="rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm">
                <h2 className="flex items-center gap-2 font-display text-xl font-black uppercase"><CreditCard size={20} className="text-peri-red" /> Complete payment</h2>
                <p className="mt-2 text-sm leading-6 text-ash">This order requires online card payment. Continue to Yoco’s secure checkout. Do not refresh repeatedly — the checkout link is idempotent, and the server verifies the amount before marking paid.</p>
                <button onClick={retryYocoCheckout} disabled={retryingYoco} className="button button-primary mt-4 w-full justify-center disabled:opacity-40">
                  {retryingYoco ? "Opening Yoco…" : "Pay R" + order.total_price.toFixed(2) + " with Yoco"}
                </button>
                <p className="mt-3 text-xs leading-5 text-ash/60">Payment succeeds only after the Yoco webhook is verified server-side. The browser success page alone never marks the order paid.</p>
              </div>
            )}

            {isPaid && (
              <div className="rounded-[1.75rem] border border-leaf/20 bg-white p-6 shadow-sm">
                <p className="flex items-center gap-2 font-display text-xl font-black uppercase text-leaf"><CheckCircle2 size={20} /> Payment verified</p>
                <p className="mt-1 text-sm text-ash">Paid at {order.paid_at ? new Date(order.paid_at).toLocaleString("en-ZA") : "recently"}. Kitchen will now fulfill the order.</p>
              </div>
            )}

            <div className="rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm">
              <h2 className="font-display text-xl font-black uppercase">Order details</h2>
              <div className="mt-4 grid gap-3 text-sm">
                <div className="flex gap-3"><User size={18} className="shrink-0 text-peri-red" /><span><strong>{order.customer_name}</strong> • <span className="inline-flex items-center gap-1"><Phone size={14} />{order.customer_phone}</span></span></div>
                <div className="flex gap-3"><Truck size={18} className="shrink-0 text-peri-red" /><span><strong>{order.order_type === "delivery" ? "Home Delivery" : "Pickup in Store"}</strong> • <span className="text-ash">{order.payment_method.replaceAll("_", " ")}</span></span></div>
                {order.delivery_address && <div className="flex gap-3"><MapPin size={18} className="shrink-0 text-peri-red" /><span className="text-ash">{order.delivery_address}</span></div>}
                <div className="flex gap-3"><Clock3 size={18} className="shrink-0 text-peri-red" /><span className="text-ash">Estimated {order.estimated_minutes} min • Created {new Date(order.created_at).toLocaleString("en-ZA")}</span></div>
                <div className="h-px bg-black/8" />
                <div className="flex justify-between font-black"><span>Status (fulfilment)</span><span className="capitalize">{order.status}</span></div>
                <div className="flex justify-between font-black"><span>Status (payment)</span><span className="capitalize">{order.payment_status}{isPaid ? " ✓" : ""}</span></div>
                {order.yoco_checkout_id && <p className="break-all text-xs text-ash/60">Checkout {order.yoco_checkout_id.slice(0, 24)}…</p>}
              </div>
            </div>

            <div className="rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm">
              <h2 className="font-display text-xl font-black uppercase">Items</h2>
              <ul className="mt-4 divide-y divide-black/8">
                {items.map((it, idx) => {
                  const addOnSum = (it.selected_add_ons ?? []).reduce((s, a) => s + (a.price ?? 0), 0);
                  const line = (it.unit_price + addOnSum) * it.quantity;
                  return (
                    <li key={idx} className="flex justify-between gap-3 py-3 text-sm">
                      <span className="min-w-0 flex-1">
                        <span className="font-extrabold">{it.item_name}</span> <span className="text-ash">×{it.quantity}</span>
                        <span className="block text-xs text-ash/70">{it.item_category}{it.spice_level ? ` • ${it.spice_level}` : ""}</span>
                        {(it.selected_add_ons ?? []).length > 0 && <span className="block text-xs text-peri-red">+ {(it.selected_add_ons ?? []).map((a) => `${a.name} (R${a.price?.toFixed?.(0) ?? a.price})`).join(", ")}</span>}
                        {it.notes && <span className="block text-xs italic text-ash/60">&ldquo;{it.notes}&rdquo;</span>}
                      </span>
                      <span className="shrink-0 font-black">R{line.toFixed(2)}</span>
                    </li>
                  );
                })}
              </ul>
              <div className="mt-4 flex justify-between border-t border-black/8 pt-4 text-lg font-black"><span>Total</span><span className="text-peri-red">R{order.total_price.toFixed(2)}</span></div>
              <p className="mt-2 text-xs text-ash/60">Total calculated on server from trusted menu. Order is in the same Postgres table staff manage from the app admin dashboard.</p>
            </div>
          </div>

          <aside className="h-fit rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm lg:sticky lg:top-24">
            <h2 className="font-display text-lg font-black uppercase">What next?</h2>
            <ul className="mt-3 grid gap-2 text-sm leading-6 text-ash">
              <li>• Kitchen advances status: <strong>pending → preparing → ready → completed</strong> (visible here and in the app).</li>
              <li>• Payment and fulfilment are separate — a paid order still needs preparation.</li>
              <li>• If payment stays pending after a successful card payment, contact the store with order #{order.order_number} — they can verify in Supabase `payments` table.</li>
            </ul>
            <div className="mt-6 grid gap-3">
              <Link href="/menu/" className="button w-full justify-center border border-black/10 bg-white text-charcoal">Back to menu</Link>
              <a href="https://wa.me/27736423549" target="_blank" rel="noreferrer" className="button button-primary w-full justify-center">Chat on WhatsApp</a>
            </div>
            <button onClick={() => void fetchOrder()} className="mt-4 w-full rounded-full bg-muted px-4 py-2 text-xs font-extrabold text-ash hover:bg-black/5">Refresh status</button>
          </aside>
        </div>
      </section>
    </main>
  );
}
