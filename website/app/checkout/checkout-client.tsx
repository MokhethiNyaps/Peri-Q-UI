"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowRight, Clock3, ShieldCheck, Store, Truck } from "lucide-react";
import { useCart } from "@/lib/cart";
import { fetchMenu, isStoreOpenNow, type AppSettings } from "@/lib/menu";
import { ensureAnonSession } from "@/lib/auth";
import { createBrowserClient, isSupabaseConfigured } from "@/lib/supabase";

type OrderType = "pickup" | "delivery";
type PaymentMethod = "cash_collection" | "cash_delivery" | "eft" | "yoco";

export default function CheckoutClient() {
  const { entries, subtotal, clear } = useCart();
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [loadingSettings, setLoadingSettings] = useState(true);
  const [orderType, setOrderType] = useState<OrderType>("pickup");
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("cash_collection");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (!isSupabaseConfigured()) {
      setLoadingSettings(false);
      return;
    }
    void fetchMenu().then(({ appSettings }) => {
      setSettings(appSettings);
      // default order type to available one
      if (!appSettings.pickupAvailable && appSettings.deliveryAvailable) setOrderType("delivery");
    }).catch(() => {}).finally(() => setLoadingSettings(false));

    // Load saved customer details from localStorage (mirrors mobile SharedPreferences)
    try {
      const saved = localStorage.getItem("peri_q_customer_v1");
      if (saved) {
        const parsed = JSON.parse(saved) as { name?: string; phone?: string; address?: string; orderType?: OrderType; paymentMethod?: PaymentMethod };
        if (parsed.name) setName(parsed.name);
        if (parsed.phone) setPhone(parsed.phone);
        if (parsed.address) setAddress(parsed.address);
        if (parsed.orderType) setOrderType(parsed.orderType);
        if (parsed.paymentMethod) setPaymentMethod(parsed.paymentMethod);
      }
    } catch {}
  }, []);

  useEffect(() => {
    try {
      localStorage.setItem("peri_q_customer_v1", JSON.stringify({ name, phone, address, orderType, paymentMethod }));
    } catch {}
  }, [name, phone, address, orderType, paymentMethod]);

  const deliveryFee = settings?.deliveryFee ?? 30;
  const totalForType = (t: OrderType) => subtotal + (t === "delivery" ? deliveryFee : 0);
  const canPickup = settings?.pickupAvailable ?? true;
  const canDelivery = settings?.deliveryAvailable ?? true;
  const storeOpen = settings ? isStoreOpenNow(settings) : true;
  const globalStoreOpen = settings?.storeOpen ?? true;

  const validate = (): boolean => {
    const fe: Record<string, string> = {};
    if (!name.trim() || name.trim().length < 2) fe.name = "Enter your full name (2–100 chars).";
    if (!phone.trim() || phone.trim().length < 7) fe.phone = "Enter a valid phone (7–30 chars).";
    if (entries.length === 0) fe.cart = "Your cart is empty. Add items from the menu.";
    if (!globalStoreOpen) fe.store = "Ordering is paused by the restaurant right now.";
    else if (!storeOpen) fe.store = `Store is closed. Hours ${settings?.openingTime}–${settings?.closingTime} (Africa/Johannesburg).`;
    if (orderType === "delivery" && address.trim().length < 8) fe.address = "Enter a full delivery address (at least 8 chars, house + street).";
    if (orderType === "pickup" && paymentMethod === "cash_delivery") fe.payment = "Cash on Delivery is only for delivery orders.";
    if (!canPickup && orderType === "pickup") fe.orderType = "Pickup is unavailable right now.";
    if (!canDelivery && orderType === "delivery") fe.orderType = "Delivery is unavailable right now.";
    setFieldErrors(fe);
    return Object.keys(fe).length === 0;
  };

  const mapPaymentForRpc = (pm: PaymentMethod, ot: OrderType): string => {
    if (pm === "yoco") return "yoco";
    if (pm === "cash_delivery" && ot === "pickup") return "cash_collection";
    return pm;
  };

  const handleSubmit = async () => {
    setError(null);
    if (!validate()) return;
    if (!isSupabaseConfigured()) {
      setError("Website is not connected to Supabase. Owner must configure Vercel env.");
      return;
    }
    setSubmitting(true);
    try {
      const anon = await ensureAnonSession();
      if (!anon) throw new Error("Could not create a guest session. In Supabase Dashboard → Auth → enable Anonymous sign-ins and retry.");
      const supa = createBrowserClient();
      // Ensure we use fresh session token if available
      const { data: sessData } = await supa.auth.getSession();
      const accessToken = sessData.session?.access_token ?? anon.accessToken;

      const clientRequestId = `web-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
      const payloadItems = entries.map((e) => ({
        menu_item_id: e.item.id,
        quantity: e.quantity,
        spice_level: e.spiceLevel ?? null,
        notes: e.notes ?? "",
        selected_add_ons: e.selectedAddOns.map((a) => ({ name: a.name })),
      }));

      const expectedTotal = totalForType(orderType);
      const rpcPayment = mapPaymentForRpc(paymentMethod, orderType);

      const { data, error: rpcError } = await supa.rpc("place_order", {
        p_customer_name: name.trim(),
        p_customer_phone: phone.trim(),
        p_order_type: orderType,
        p_payment_method: rpcPayment,
        p_delivery_address: orderType === "delivery" ? address.trim() : null,
        p_expected_total: expectedTotal,
        p_client_request_id: clientRequestId,
        p_items: payloadItems,
      });

      if (rpcError) {
        const msg = rpcError.message || "";
        if (msg.toLowerCase().includes("price changed")) throw new Error("Price changed before checkout — a menu price or delivery fee changed while you were ordering. Your cart is still saved; review the updated total and try again.");
        if (msg.toLowerCase().includes("store is closed") || msg.toLowerCase().includes("ordering is paused")) throw new Error("Ordering is paused or the store is closed. Try during store hours.");
        if (msg.toLowerCase().includes("delivery is unavailable") || msg.toLowerCase().includes("pickup is unavailable")) throw new Error(msg);
        if (msg.toLowerCase().includes("unavailable") || msg.toLowerCase().includes("not found")) throw new Error("An item in your cart is no longer available. Return to the menu and update your cart.");
        throw new Error(msg || "Could not place order. Check your connection and try again. Cart is still saved.");
      }

      const orderId = (data as { id?: string })?.id;
      if (!orderId) throw new Error("Store did not return an order confirmation. Please try again.");

      // If Yoco, initiate checkout session server-side (trusted amount)
      if (paymentMethod === "yoco") {
        const res = await fetch("/api/yoco/checkout", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
          },
          body: JSON.stringify({ orderId }),
        });
        const json = (await res.json().catch(() => ({}))) as { redirectUrl?: string; error?: string; code?: string };
        if (!res.ok || !json.redirectUrl) {
          // Order already exists as pending/awaiting payment; show order page with retry
          throw new Error(json.error || "Order created but Yoco checkout could not be started. Your order is saved — open it to retry payment. (No card was charged.)");
        }
        // Do not clear cart until payment succeeds — but order is at least created.
        // Keep cart for now; order page will allow clearing after paid.
        window.location.href = json.redirectUrl;
        return;
      }

      // Cash/EFT: success
      clear();
      window.location.href = `/order/${orderId}/?new=1`;
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not place order. Check your connection and try again.");
    } finally {
      setSubmitting(false);
    }
  };

  if (loadingSettings) {
    return (
      <main id="main-content" className="bg-cream py-20">
        <div className="site-shell h-40 animate-pulse rounded-[1.75rem] bg-muted" />
      </main>
    );
  }

  return (
    <main id="main-content" className="bg-cream">
      <section className="bg-charcoal py-10 text-white">
        <div className="site-shell">
          <h1 className="font-display text-5xl font-black uppercase tracking-[-0.05em]">Checkout</h1>
          <p className="mt-3 max-w-2xl text-sm leading-7 text-white/60">Enter your details. Orders go into the same Supabase table the restaurant app uses — kitchen sees website orders instantly. Prices and totals are calculated on the server.</p>
          <div className="mt-4 flex flex-wrap gap-2 text-xs font-black">
            <span className={`rounded-full px-3 py-1.5 ${!globalStoreOpen ? "bg-amber-500 text-charcoal" : storeOpen ? "bg-leaf text-white" : "bg-white/15 text-white"}`}>
              {!globalStoreOpen ? "Ordering paused" : storeOpen ? `Open now • Closes ${settings?.closingTime}` : `Closed • Opens ${settings?.openingTime}`}
            </span>
            <span className="rounded-full bg-white/10 px-3 py-1.5 text-white/70">Delivery fee R{deliveryFee.toFixed(0)}</span>
          </div>
        </div>
      </section>

      <section className="section-pad">
        <div className="site-shell grid gap-8 lg:grid-cols-[1.6fr_0.9fr]">
          <div className="grid gap-6">
            {fieldErrors.store && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-bold text-amber-900">{fieldErrors.store}</div>}
            {fieldErrors.cart && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-bold text-amber-900">{fieldErrors.cart}</div>}
            {error && <div className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold leading-6 text-red-900">{error}</div>}

            {/* Details */}
            <div className="rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm">
              <h2 className="font-display text-xl font-black uppercase">Your details</h2>
              <div className="mt-4 grid gap-4">
                <label>
                  <span className="text-xs font-black uppercase tracking-[0.14em] text-ash">Full name</span>
                  <input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Thabo Molefe" className="mt-1.5 h-12 w-full rounded-2xl border border-black/10 px-4 text-sm font-semibold focus:border-orange/60 focus:outline-none" />
                  {fieldErrors.name && <span className="mt-1 block text-xs font-bold text-red-600">{fieldErrors.name}</span>}
                </label>
                <label>
                  <span className="text-xs font-black uppercase tracking-[0.14em] text-ash">Phone</span>
                  <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+27 71 234 5678" inputMode="tel" className="mt-1.5 h-12 w-full rounded-2xl border border-black/10 px-4 text-sm font-semibold focus:border-orange/60 focus:outline-none" />
                  {fieldErrors.phone && <span className="mt-1 block text-xs font-bold text-red-600">{fieldErrors.phone}</span>}
                </label>
              </div>
            </div>

            {/* Fulfilment */}
            <div className="rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm">
              <h2 className="font-display text-xl font-black uppercase">Fulfilment</h2>
              {fieldErrors.orderType && <p className="mt-2 text-xs font-bold text-red-600">{fieldErrors.orderType}</p>}
              <div className="mt-4 grid gap-3 sm:grid-cols-2">
                {[
                  { id: "pickup" as const, icon: Store, title: "Pickup in Store", subtitle: "No delivery fee • Ready in ~25 min", enabled: canPickup },
                  { id: "delivery" as const, icon: Truck, title: "Home Delivery", subtitle: `+R${deliveryFee.toFixed(0)} delivery fee • 45–60 min`, enabled: canDelivery },
                ].map(({ id, icon: Icon, title, subtitle, enabled }) => (
                  <button
                    key={id}
                    onClick={() => {
                      if (!enabled) return;
                      setOrderType(id);
                      if (id === "pickup" && paymentMethod === "cash_delivery") setPaymentMethod("cash_collection");
                      if (id === "delivery" && paymentMethod === "cash_collection") setPaymentMethod("cash_delivery");
                    }}
                    className={`rounded-2xl border p-4 text-left transition ${orderType === id ? "border-charcoal bg-charcoal text-white" : enabled ? "border-black/10 bg-white hover:bg-muted" : "border-black/5 bg-muted opacity-50"}`}
                  >
                    <Icon size={20} className={orderType === id ? "text-orange" : "text-peri-red"} aria-hidden="true" />
                    <p className="mt-2 text-sm font-extrabold">{title}</p>
                    <p className={`mt-1 text-xs ${orderType === id ? "text-white/60" : "text-ash"}`}>{subtitle} {!enabled && " • Unavailable"}</p>
                  </button>
                ))}
              </div>

              {orderType === "delivery" && (
                <div className="mt-4">
                  <label>
                    <span className="text-xs font-black uppercase tracking-[0.14em] text-ash">Delivery address (required)</span>
                    <textarea value={address} onChange={(e) => setAddress(e.target.value)} placeholder="House number, street, area and landmark — e.g. 12 Main Rd, Heidedal, Bloemfontein — Ring side gate bell" rows={3} className="mt-1.5 w-full rounded-2xl border border-black/10 px-4 py-3 text-sm font-semibold focus:border-orange/60 focus:outline-none" />
                    {fieldErrors.address && <span className="mt-1 block text-xs font-bold text-red-600">{fieldErrors.address}</span>}
                  </label>
                </div>
              )}
            </div>

            {/* Payment */}
            <div className="rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm">
              <h2 className="font-display text-xl font-black uppercase">Payment method</h2>
              <p className="mt-1 text-xs font-semibold text-ash/70">Cash stays preserved. Yoco is for online card payments. Server validates the total — browser amount is never trusted.</p>
              <div className="mt-4 grid gap-3">
                {[
                  { id: "cash_collection" as const, label: "Cash on Collection (pickup)", hint: "Pay in store when you collect", show: true },
                  { id: "cash_delivery" as const, label: "Cash on Delivery", hint: "Pay the driver on arrival", show: orderType === "delivery" },
                  { id: "eft" as const, label: "EFT + proof upload", hint: "Upload proof after confirming — staff verifies manually", show: true },
                  { id: "yoco" as const, label: "Pay online with Card (Yoco)", hint: "Secure Yoco hosted checkout — Visa, Mastercard, etc.", show: true },
                ].filter((m) => m.show).map((m) => (
                  <label key={m.id} className={`flex cursor-pointer items-center gap-3 rounded-2xl border p-4 ${paymentMethod === m.id ? "border-charcoal bg-charcoal text-white" : "border-black/10 bg-white"}`}>
                    <input type="radio" name="payment" checked={paymentMethod === m.id} onChange={() => setPaymentMethod(m.id)} className="size-5 accent-peri-red" />
                    <span className="flex-1">
                      <span className={`block text-sm font-extrabold ${paymentMethod === m.id ? "text-white" : "text-charcoal"}`}>{m.label}</span>
                      <span className={`block text-xs ${paymentMethod === m.id ? "text-white/60" : "text-ash"}`}>{m.hint}</span>
                    </span>
                  </label>
                ))}
                {fieldErrors.payment && <p className="text-xs font-bold text-red-600">{fieldErrors.payment}</p>}
              </div>
              {paymentMethod === "yoco" && (
                <div className="mt-4 rounded-2xl bg-muted p-4 text-xs leading-6 text-ash">
                  <p className="font-extrabold text-charcoal">How Yoco works</p>
                  <p>You’ll be redirected to Yoco’s secure hosted checkout. After payment, you return here. Your order is only marked <em>paid</em> after the server verifies the Yoco webhook — not just the browser redirect.</p>
                </div>
              )}
              {paymentMethod === "eft" && (
                <p className="mt-3 text-xs leading-6 text-ash">After confirming, you can upload EFT proof from the order page. Order stays <em>pending</em> until staff verifies.</p>
              )}
            </div>
          </div>

          {/* Summary */}
          <aside className="h-fit rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm lg:sticky lg:top-24">
            <h2 className="font-display text-xl font-black uppercase">Summary</h2>
            <div className="mt-4 max-h-[22rem] overflow-auto pr-1">
              {entries.length === 0 ? (
                <p className="rounded-2xl bg-amber-50 p-4 text-sm font-bold text-amber-900">Cart empty — <Link href="/menu/" className="underline">add items</Link>.</p>
              ) : (
                <ul className="divide-y divide-black/8">
                  {entries.map((e) => {
                    const addOnSum = e.selectedAddOns.reduce((s, a) => s + a.price, 0);
                    const line = (e.item.price + addOnSum) * e.quantity;
                    return (
                      <li key={e.id} className="flex justify-between gap-3 py-3 text-sm">
                        <span className="min-w-0 flex-1 font-semibold">
                          <span className="font-extrabold">{e.item.name}</span> <span className="text-ash">×{e.quantity}</span>
                          {e.spiceLevel ? <span className="block text-xs text-ash/70">{e.spiceLevel}</span> : null}
                        </span>
                        <span className="shrink-0 font-black">R{line.toFixed(2)}</span>
                      </li>
                    );
                  })}
                </ul>
              )}
            </div>

            <div className="mt-4 grid gap-2 border-t border-black/8 pt-4 text-sm">
              <div className="flex justify-between"><span className="text-ash">Subtotal</span><span className="font-black">R{subtotal.toFixed(2)}</span></div>
              <div className="flex justify-between"><span className="text-ash">Delivery fee</span><span className="font-black">{orderType === "delivery" ? `R${deliveryFee.toFixed(2)}` : "—"}</span></div>
              <div className="flex justify-between text-[1.05rem]"><span className="font-black">Total to pay</span><span className="font-black text-peri-red">R{totalForType(orderType).toFixed(2)}</span></div>
              <p className="flex items-center gap-2 rounded-2xl bg-muted p-3 text-xs leading-5 text-ash"><ShieldCheck size={16} className="shrink-0 text-leaf" /> Server validates amount. Never trust client total.</p>
            </div>

            <button onClick={handleSubmit} disabled={submitting || entries.length === 0} className="button button-primary mt-6 w-full justify-center disabled:opacity-40">
              {submitting ? "Placing order…" : paymentMethod === "yoco" ? "Place order & Pay with Yoco" : "Confirm order"}
              {!submitting && <ArrowRight size={18} />}
            </button>

            <div className="mt-4 flex items-center gap-2 text-xs font-semibold text-ash/60">
              <Clock3 size={14} /> {orderType === "delivery" ? "45–60 min (incl. delivery)" : "~25 min"}
            </div>
            <p className="mt-3 text-center text-xs font-semibold text-ash/60">Orders from website use the same authoritative orders table as the mobile app.</p>
          </aside>
        </div>
      </section>
    </main>
  );
}
