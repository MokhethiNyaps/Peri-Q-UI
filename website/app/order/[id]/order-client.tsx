"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { ArrowLeft, CheckCircle2, Clock3, CreditCard, MapPin, Phone, Truck, User, XCircle } from "lucide-react";
import { createBrowserClient } from "@/lib/supabase";
import { ensureAnonSession } from "@/lib/auth";
import { useCustomerAuth } from "@/lib/customer-auth";

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
  const { user } = useCustomerAuth();
  const search = useSearchParams();
  const checkout = search.get("checkout"); // success | cancel | failure
  const isNew = search.get("new") === "1";
  const [order, setOrder] = useState<OrderRow | null>(null);
  const [items, setItems] = useState<OrderItemRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [retryingYoco, setRetryingYoco] = useState(false);
  const [info, setInfo] = useState<string | null>(null);
  const [refreshError, setRefreshError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const currentOrder = useRef<OrderRow | null>(null);
  const requestVersion = useRef(0);
  const inFlight = useRef(false);
  const active = useRef(false);

  const fetchOrder = useCallback(async () => {
    if (inFlight.current || !active.current) return;
    const version = requestVersion.current;
    inFlight.current = true;
    setRefreshing(true);
    try {
      const supa = createBrowserClient();
      const { data: { session } } = await supa.auth.getSession();
      if (!session) throw new Error("Sign in using the account or browser you used to place this order.");
      const { data, error: err } = await supa
        .from("orders")
        .select(
          "*,order_items(item_name,unit_price,quantity,item_category,selected_add_ons,notes,spice_level)",
        )
        .eq("id", orderId)
        .maybeSingle();

      if (!active.current || requestVersion.current !== version) return;
      if (err) throw err;
      if (!data) {
        currentOrder.current = null;
        setOrder(null);
        setError("Order not found. It may belong to another device/account. If you ordered as guest on a different browser, the kitchen still has it — contact the restaurant with your order number.");
        return;
      }
      const row = data as unknown as OrderRow & { order_items: OrderItemRow[] };
      const nextOrder = { ...row, payment_status: row.payment_status ?? "unpaid" };
      currentOrder.current = nextOrder;
      setOrder(nextOrder);
      setItems(row.order_items ?? []);
      setError(null);
      setRefreshError(null);
    } catch (e) {
      if (!active.current || requestVersion.current !== version) return;
      const message = e instanceof Error ? e.message : "Could not update your order. Please try again.";
      if (currentOrder.current) setRefreshError(message);
      else setError(message);
    } finally {
      if (active.current && requestVersion.current === version) {
        inFlight.current = false;
        setRefreshing(false);
        setLoading(false);
      }
    }
  }, [orderId]);

  useEffect(() => {
    active.current = true;
    ++requestVersion.current;
    inFlight.current = false;
    currentOrder.current = null;
    setOrder(null);
    setError(null);
    setRefreshError(null);
    setLoading(true);
    void fetchOrder();
    const t = setInterval(() => {
      if (!document.hidden) void fetchOrder();
    }, 8000);
    return () => { active.current = false; clearInterval(t); };
  }, [fetchOrder, user?.id]);

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
      if (!res.ok || !json.redirectUrl) throw new Error(json.error || "Could not start card checkout.");
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
            <Link href="/account/" className="button button-primary">Sign in</Link>
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
    pending: "Payment pending (awaiting confirmation)",
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
  const showCancelBanner = checkout === "cancel" && !isPaid;
  const showFailureBanner = checkout === "failure" && !isPaid;

  return (
    <main id="main-content" className="bg-cream">
      <section className="stage stage-glow grill-lines overflow-hidden py-10">
        <div className="site-shell">
          <Link href="/menu/" className="inline-flex items-center gap-2 text-sm font-bold text-white/60 hover:text-white">
            <ArrowLeft size={16} /> Back to menu
          </Link>
          <h1 className="mt-4 font-display text-6xl font-extrabold uppercase leading-[0.9]">Order #{order.order_number}</h1>
          <p className="mt-2 text-sm text-white/60">ID {order.id} • Created {new Date(order.created_at).toLocaleString("en-ZA", { timeZone: "Africa/Johannesburg" })}</p>
          <div className="mt-4 flex flex-wrap gap-2 text-xs font-black">
            <span className="rounded-full bg-white px-3 py-1.5 text-charcoal">{fulfillmentLabel[order.status] ?? order.status}</span>
            <span className={`rounded-full px-3 py-1.5 ${isPaid ? "bg-leaf text-white" : yocoPending ? "bg-amber-500 text-charcoal" : "bg-white/15 text-white"}`}>{paymentLabel[order.payment_status] ?? order.payment_status}</span>
            {order.yoco_mode === "test" && <span className="rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-white/80">Test payment</span>}
          </div>
        </div>
      </section>

      <section className="section-pad">
        <div className="site-shell grid gap-8 lg:grid-cols-[1.6fr_0.9fr]">
          <div className="grid gap-6">
            <OrderProgress status={order.status} paid={isPaid} estimatedMinutes={order.estimated_minutes} />
            {isNew && isPaid && (
              <div className="rounded-[1.75rem] border border-leaf/20 bg-leaf/10 p-5">
                <p className="flex items-center gap-2 font-display text-xl font-black uppercase text-leaf"><CheckCircle2 size={20} /> Order confirmed #{order.order_number}</p>
                <p className="mt-2 text-sm leading-6 text-ash">Estimated time <strong>{order.estimated_minutes} min</strong>. Follow status updates here or contact the restaurant.</p>
              </div>
            )}
            {showSuccessBanner && !isPaid && (
              <div className="rounded-[1.75rem] border border-amber-200 bg-amber-50 p-5">
                <p className="font-extrabold text-amber-900">Checking your card payment</p>
                <p className="mt-1 text-sm leading-6 text-amber-900/70">You returned from the secure checkout. Your payment is confirmed by the restaurant before your order is prepared. Do not pay again yet — this page refreshes automatically. If it stays pending for a few minutes, check with the restaurant.</p>
              </div>
            )}
            {showCancelBanner && (
              <div className="rounded-[1.75rem] border border-black/10 bg-white p-5">
                <p className="flex items-center gap-2 font-extrabold text-charcoal"><XCircle size={18} className="text-ash" /> Returned from payment</p>
                <p className="mt-1 text-sm text-ash">You returned from card checkout. Your order is saved — retry below when ready. Check the payment status before retrying.</p>
              </div>
            )}
            {showFailureBanner && (
              <div className="rounded-[1.75rem] border border-red-200 bg-red-50 p-5">
                <p className="flex items-center gap-2 font-extrabold text-red-900"><XCircle size={18} /> Payment did not complete</p>
                <p className="mt-1 text-sm text-red-900/70">Payment has not been confirmed. Check the payment status before trying your card again.</p>
              </div>
            )}
            {info && <div className="rounded-2xl border border-black/10 bg-white p-4 text-sm font-bold text-charcoal">{info}</div>}

            {/* Yoco retry */}
            {yocoPending && (
              <div className="rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm">
                <h2 className="flex items-center gap-2 font-display text-xl font-black uppercase"><CreditCard size={20} className="text-peri-red" /> Complete payment</h2>
                <p className="mt-2 text-sm leading-6 text-ash">Continue to the hosted card payment page. Check your payment status before trying again.</p>
                <button onClick={retryYocoCheckout} disabled={retryingYoco} className="button button-primary mt-4 w-full justify-center disabled:opacity-40">
                  {retryingYoco ? "Opening payment…" : "Pay R" + order.total_price.toFixed(2) + " by card"}
                </button>
                <p className="mt-3 text-xs leading-5 text-ash">Your order is prepared after payment is confirmed.</p>
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
                <div className="flex gap-3"><Truck size={18} className="shrink-0 text-peri-red" /><span><strong>{order.order_type === "delivery" ? "Home Delivery" : "Pickup in Store"}</strong> • <span className="text-ash">{isYoco ? "Card" : order.payment_method.replaceAll("_", " ")}</span></span></div>
                {order.delivery_address && <div className="flex gap-3"><MapPin size={18} className="shrink-0 text-peri-red" /><span className="text-ash">{order.delivery_address}</span></div>}
                <div className="flex gap-3"><Clock3 size={18} className="shrink-0 text-peri-red" /><span className="text-ash">Estimated {order.estimated_minutes} min • Created {new Date(order.created_at).toLocaleString("en-ZA")}</span></div>
                <div className="h-px bg-black/8" />
                <div className="flex justify-between font-black"><span>Status (fulfilment)</span><span className="capitalize">{order.status}</span></div>
                <div className="flex justify-between font-black"><span>Status (payment)</span><span className="capitalize">{order.payment_status}{isPaid ? " ✓" : ""}</span></div>
                {order.yoco_checkout_id && <p className="break-all text-xs text-ash">Checkout {order.yoco_checkout_id.slice(0, 24)}…</p>}
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
                        <span className="block text-xs text-ash">{it.item_category}{it.spice_level ? ` • ${it.spice_level}` : ""}</span>
                        {(it.selected_add_ons ?? []).length > 0 && <span className="block text-xs text-peri-red">+ {(it.selected_add_ons ?? []).map((a) => `${a.name} (R${a.price?.toFixed?.(0) ?? a.price})`).join(", ")}</span>}
                        {it.notes && <span className="block text-xs italic text-ash">&ldquo;{it.notes}&rdquo;</span>}
                      </span>
                      <span className="shrink-0 font-black">R{line.toFixed(2)}</span>
                    </li>
                  );
                })}
              </ul>
              <div className="mt-4 flex justify-between border-t border-black/8 pt-4 text-lg font-black"><span>Total</span><span className="text-peri-red">R{order.total_price.toFixed(2)}</span></div>

            </div>
          </div>

          <aside className="h-fit rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm lg:sticky lg:top-24">
            <h2 className="font-display text-lg font-black uppercase">What next?</h2>
            <ul className="mt-3 grid gap-2 text-sm leading-6 text-ash">
              <li>• The kitchen updates your order here and in the app as it moves from received to ready.</li>
              <li>• A paid order still needs to be cooked, so give the grill a little time.</li>
              <li>• If payment still shows as pending a few minutes after paying, contact the restaurant with order #{order.order_number} before paying again.</li>
            </ul>
            <div className="mt-6 grid gap-3">
              <Link href="/menu/" className="button w-full justify-center border border-black/10 bg-white text-charcoal">Back to menu</Link>
              <a href="https://wa.me/27736423549" target="_blank" rel="noreferrer" className="button button-primary w-full justify-center">Chat on WhatsApp</a>
            </div>
            <button onClick={() => void fetchOrder()} disabled={refreshing} className="mt-4 w-full rounded-full bg-muted px-4 py-2 text-xs font-extrabold text-ash hover:bg-black/5 disabled:opacity-60">Refresh status</button>
            <p role="status" aria-live="polite" className="mt-2 min-h-10 text-xs leading-5 text-ash">{refreshError ?? (refreshing ? "Updating status…" : "Status updates automatically.")}</p>
          </aside>
        </div>
      </section>
    </main>
  );
}


const PROGRESS_STEPS = [
  { key: "pending", label: "Received" },
  { key: "preparing", label: "On the grill" },
  { key: "ready", label: "Ready" },
  { key: "completed", label: "Done" },
] as const;

/** A flame bar that grows with each status the kitchen confirms. */
function OrderProgress({ status, paid, estimatedMinutes }: { status: string; paid: boolean; estimatedMinutes: number }) {
  if (status === "cancelled") {
    return (
      <div className="rounded-[1.75rem] border border-black/10 bg-white p-6 shadow-sm">
        <p className="font-display text-2xl font-extrabold uppercase text-charcoal">This order was cancelled</p>
        <p className="mt-1 text-sm text-ash">Contact the restaurant if you have questions about it.</p>
      </div>
    );
  }
  const index = Math.max(0, PROGRESS_STEPS.findIndex((step) => step.key === status));
  const percent = paid || index > 0 ? ((index + 1) / PROGRESS_STEPS.length) * 100 : 8;
  return (
    <div className="rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm">
      <div className="flex items-baseline justify-between gap-3">
        <p className="font-display text-2xl font-extrabold uppercase text-charcoal">
          {paid || index > 0 ? PROGRESS_STEPS[index].label : "Waiting for payment"}
        </p>
        {index < 2 && <p className="text-sm font-semibold text-ash">About {estimatedMinutes} min</p>}
      </div>
      <div className="flame-progress mt-4" role="progressbar" aria-label="Order progress" aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(percent)}>
        <span style={{ width: `${percent}%` }} />
      </div>
      <ol className="mt-3 grid grid-cols-4 gap-2 text-[0.7rem] font-extrabold uppercase tracking-[0.08em]">
        {PROGRESS_STEPS.map((step, i) => (
          <li key={step.key} className={(paid || index > 0) && i <= index ? "text-peri-red" : "text-black/30"}>
            {step.label}
          </li>
        ))}
      </ol>
    </div>
  );
}
