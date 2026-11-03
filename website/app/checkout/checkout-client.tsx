"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { ArrowRight, Clock3, ShieldCheck, Store, Truck } from "lucide-react";
import { useCart } from "@/lib/cart";
import { fetchMenu, isStoreOpenNow, type AppSettings } from "@/lib/menu";
import { ensureAnonSession } from "@/lib/auth";
import { createBrowserClient, isSupabaseConfigured } from "@/lib/supabase";
import { useCustomerAuth } from "@/lib/customer-auth";
import { siteConfig } from "@/lib/site";
import { recordCheckoutAcceptance } from "@/lib/policy-consent";
import { PolicyConsent, PrivacyNotice } from "@/components/policy-consent";

type OrderType = "pickup" | "delivery";
const paymentMethod = "yoco";

export default function CheckoutClient() {
  const { user, profile } = useCustomerAuth();
  const { entries, subtotal } = useCart();
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [loadingSettings, setLoadingSettings] = useState(true);
  const [orderType, setOrderType] = useState<OrderType>("pickup");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");
  const [acceptedPolicies, setAcceptedPolicies] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [yocoAvailable, setYocoAvailable] = useState(false);
  const [yocoTestMode, setYocoTestMode] = useState(false);
  const submittingRef = useRef(false);
  const requestIdRef = useRef<string | null>(null);
  const profileName = profile?.full_name;
  const profilePhone = profile?.phone;
  const accountId = user && !user.is_anonymous ? user.id : null;
  useEffect(() => {
    if (accountId && profileName !== undefined) {
      setName(profileName ?? "");
      setPhone(profilePhone ?? "");
    }
  }, [accountId, profileName, profilePhone]);

  useEffect(() => {
    void fetch("/api/yoco/checkout/")
      .then((res) => res.ok ? res.json() : { available: false })
      .then((data: { available?: boolean; mode?: string }) => {
        setYocoAvailable(data.available === true);
        setYocoTestMode(data.mode === "test");
      })
      .catch(() => setYocoAvailable(false));
    if (!isSupabaseConfigured()) {
      setLoadingSettings(false);
      return;
    }
    void fetchMenu().then(({ appSettings }) => {
      setSettings(appSettings);
      // default order type to available one
      if (!appSettings.pickupAvailable && appSettings.deliveryAvailable) setOrderType("delivery");
    }).catch(() => setError("Could not load store settings. Please refresh and try again.")).finally(() => setLoadingSettings(false));

    // Load saved customer details from localStorage (mirrors mobile SharedPreferences)
    try {
      const saved = localStorage.getItem("peri_q_customer_v1");
      if (saved) {
        const parsed = JSON.parse(saved) as { name?: string; phone?: string; address?: string; orderType?: OrderType; paymentMethod?: string };
        if (parsed.name) setName(parsed.name);
        if (parsed.phone) setPhone(parsed.phone);
        if (parsed.address) setAddress(parsed.address);
        if (parsed.orderType) setOrderType(parsed.orderType);
        
      }
    } catch {}
  }, []);

  useEffect(() => {
    try {
      localStorage.setItem("peri_q_customer_v1", JSON.stringify({ name, phone, address, orderType, paymentMethod }));
    } catch {}
  }, [name, phone, address, orderType]);

  const deliveryFee = settings?.deliveryFee ?? 30;
  const totalForType = (t: OrderType) => subtotal + (t === "delivery" ? deliveryFee : 0);
  const canPickup = settings?.pickupAvailable ?? true;
  const canDelivery = settings?.deliveryAvailable ?? true;
  const storeOpen = settings ? isStoreOpenNow(settings) : false;
  const globalStoreOpen = settings?.storeOpen ?? false;

  const validate = (): boolean => {
    const fe: Record<string, string> = {};
    if (!settings) fe.store = "Store settings are unavailable. Please refresh and try again.";
    if (!name.trim() || (name.trim().length < 2 || name.trim().length > 100)) fe.name = "Enter your full name (2–100 chars).";
    if (!phone.trim() || (phone.trim().length < 7 || phone.trim().length > 30)) fe.phone = "Enter a valid phone (7–30 chars).";
    if (entries.length === 0) fe.cart = "Your cart is empty. Add items from the menu.";
    if (settings && !globalStoreOpen) fe.store = "Ordering is paused by the restaurant right now.";
    else if (!storeOpen) fe.store = `Store is closed. Hours ${settings?.openingTime}–${settings?.closingTime} (Africa/Johannesburg).`;
    if (orderType === "delivery" && address.trim().length < 8) fe.address = "Enter a full delivery address (at least 8 chars, house + street).";
    if (paymentMethod === "yoco" && !yocoAvailable) fe.payment = "Online card payments are unavailable. Your cart stays saved. Please try again later.";
    if (!canPickup && orderType === "pickup") fe.orderType = "Pickup is unavailable right now.";
    if (!canDelivery && orderType === "delivery") fe.orderType = "Delivery is unavailable right now.";
    if (!acceptedPolicies) fe.consent = "Accept the terms and conditions to continue.";
    setFieldErrors(fe);
    return Object.keys(fe).length === 0;
  };

  const handleSubmit = async () => {
    if (submittingRef.current) return;
    setError(null);
    if (!validate()) return;
    if (!isSupabaseConfigured()) {
      setError("Ordering is temporarily unavailable. Your cart is saved. Please try again later.");
      return;
    }
    setSubmitting(true);
    submittingRef.current = true;
    try {
      const anon = await ensureAnonSession();
      if (!anon) throw new Error("Could not start a checkout session. Please try again; your cart is saved.");
      const supa = createBrowserClient();
      // Ensure we use fresh session token if available
      const { data: sessData } = await supa.auth.getSession();
      const accessToken = sessData.session?.access_token ?? anon.accessToken;

      requestIdRef.current ??= `web-${crypto.randomUUID()}`;

      const payloadItems = entries.map((e) => ({
        menu_item_id: e.item.id,
        quantity: e.quantity,
        spice_level: e.spiceLevel ?? null,
        notes: e.notes ?? "",
        selected_add_ons: e.selectedAddOns.map((a) => ({ name: a.name })),
      }));

      const expectedTotal = totalForType(orderType);
      const fingerprint = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256",new TextEncoder().encode(JSON.stringify({payloadItems,orderType,expectedTotal,name,phone,address,owner:anon.userId}))))).map(b=>b.toString(16).padStart(2,"0")).join("");
      try {
        const saved=JSON.parse(localStorage.getItem("peri_q_checkout_request") ?? "null") as {fingerprint:string;requestId:string}|null;
        if(saved?.fingerprint===fingerprint) requestIdRef.current=saved.requestId;
        else requestIdRef.current=`web-${crypto.randomUUID()}`;
        localStorage.setItem("peri_q_checkout_request",JSON.stringify({fingerprint,requestId:requestIdRef.current}));
      } catch { /* Checkout still uses in-memory retry protection if storage is unavailable. */ }
      const clientRequestId=requestIdRef.current;

      const rpcPayment = paymentMethod;

      const { data, error: rpcError } = await supa.rpc("prepare_card_checkout", {
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
        throw new Error("Could not prepare your order. Check your details and try again; your cart is saved.");
      }

      const orderId = (data as { id?: string })?.id;
      if (!orderId) throw new Error("Store did not return an order confirmation. Please try again.");
      // Saved before payment opens, against the draft that becomes the order.
      await recordCheckoutAcceptance(orderId);


      try {
        localStorage.setItem("peri_q_pending_payment", JSON.stringify({ orderId, cart: JSON.stringify(entries) }));
      } catch { /* Confirmation must still work when storage is unavailable. */ }
      // Initiate checkout server-side using the trusted total.
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
        if (json.code === "already_paid") { window.location.href = `/payment/${orderId}/`; return; }
        if (!res.ok || !json.redirectUrl) {
          // The cart remains saved if checkout cannot start.
          throw new Error(json.error ?? "Payment could not start. Your cart is saved.");
        }
        // Only the signed payment webhook can create the order.
        window.location.href = json.redirectUrl;
        return;
      }


    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not place order. Check your connection and try again.");
    } finally {
      setSubmitting(false);
      submittingRef.current = false;
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
      <section className="stage stage-glow grill-lines overflow-hidden py-10">
        <div className="site-shell">
          <h1 className="font-display text-6xl font-extrabold uppercase leading-[0.9]">Checkout</h1>
          <p className="mt-3 max-w-2xl text-sm leading-7 text-white/60">Enter your details to place an order with the restaurant. Confirm your items and choose collection or delivery below.</p>
          <div className="mt-4 flex flex-wrap gap-2 text-xs font-black">
            <span className={`rounded-full px-3 py-1.5 ${!globalStoreOpen ? "bg-amber-500 text-charcoal" : storeOpen ? "bg-leaf text-white" : "bg-white/15 text-white"}`}>
              {!settings ? "Store status unavailable" : !globalStoreOpen ? "Ordering paused" : storeOpen ? `Open now • Closes ${settings?.closingTime}` : `Closed • Opens ${settings?.openingTime}`}
            </span>
            <span className="rounded-full bg-white/10 px-3 py-1.5 text-white/70">{settings ? `Delivery fee R${deliveryFee.toFixed(0)}` : "Delivery fee confirmed when store settings load"}</span>
          </div>
        </div>
      </section>

      <section className="section-pad">
        <div className="site-shell grid gap-8 lg:grid-cols-[1.6fr_0.9fr]">
          <div className="grid gap-6">
            {fieldErrors.store && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-bold text-amber-900">{fieldErrors.store}</div>}
            {fieldErrors.cart && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-bold text-amber-900">{fieldErrors.cart}</div>}
            {error && <div role="alert" className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold leading-6 text-red-900">{error}</div>}

            {/* Details */}
            <div className="rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm">
              <h2 className="font-display text-xl font-black uppercase">Your details</h2>
              <div className="mt-4 grid gap-4">
                <label>
                  <span className="text-xs font-black uppercase tracking-[0.14em] text-ash">Full name</span>
                  <input autoComplete="name" maxLength={100} aria-invalid={!!fieldErrors.name} value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Thabo Molefe" className="mt-1.5 h-12 w-full rounded-2xl border border-black/10 px-4 text-sm font-semibold focus:border-orange/60 focus:outline-none" />
                  {fieldErrors.name && <span className="mt-1 block text-xs font-bold text-red-600">{fieldErrors.name}</span>}
                </label>
                <label>
                  <span className="text-xs font-black uppercase tracking-[0.14em] text-ash">Phone</span>
                  <input type="tel" autoComplete="tel" maxLength={30} aria-invalid={!!fieldErrors.phone} value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+27 71 234 5678" inputMode="tel" className="mt-1.5 h-12 w-full rounded-2xl border border-black/10 px-4 text-sm font-semibold focus:border-orange/60 focus:outline-none" />
                  {fieldErrors.phone && <span className="mt-1 block text-xs font-bold text-red-600">{fieldErrors.phone}</span>}
                </label>
              </div>
              <div className="mt-4">
                <PrivacyNotice purpose="We use your name, phone number and, for delivery, your address only to prepare, deliver and support your order." />
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
                    disabled={!enabled}
                    aria-pressed={orderType === id}
                    onClick={() => {
                      if (!enabled) return;
                      setOrderType(id);
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
                    <textarea autoComplete="street-address" aria-invalid={!!fieldErrors.address} value={address} onChange={(e) => setAddress(e.target.value)} placeholder="House number, street, area and landmark — e.g. 12 Main Rd, Heidedal, Bloemfontein — Ring side gate bell" rows={3} className="mt-1.5 w-full rounded-2xl border border-black/10 px-4 py-3 text-sm font-semibold focus:border-orange/60 focus:outline-none" />
                    {fieldErrors.address && <span className="mt-1 block text-xs font-bold text-red-600">{fieldErrors.address}</span>}
                  </label>
                </div>
              )}
            </div>

            {/* Payment */}
            <div className="rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm">
              <h2 className="font-display text-xl font-black uppercase">Payment method</h2>
              <p className="mt-2 text-sm leading-6 text-ash">Pay before we start preparing your food.</p>
              <div className="mt-4 flex items-start gap-3 rounded-2xl bg-muted p-4">
                <ShieldCheck size={22} className="mt-0.5 shrink-0 text-leaf" aria-hidden="true" />
                <div>
                  <p className="font-bold text-charcoal">Pay by card</p>
                  <p className="mt-1 text-sm leading-6 text-ash">Continue to a secure hosted payment page, then return here for confirmation. We don’t store your card details.</p>
                  {yocoTestMode && <p className="mt-2 text-sm font-bold text-peri-red">Test mode — no real payment is collected.</p>}
                  {!yocoAvailable && <p role="status" className="mt-2 text-sm font-bold text-peri-red">Card payments are temporarily unavailable. Your cart is saved.</p>}
                </div>
              </div>
              {fieldErrors.payment && <p role="alert" className="mt-3 text-sm font-bold text-peri-red">{fieldErrors.payment}</p>}
            </div>
          </div>

          {/* Summary */}
          <aside className="h-fit rounded-[1.75rem] border border-black/8 bg-white p-6 shadow-sm lg:sticky lg:top-24">
            {/* Everything the customer pays for, reviewable and changeable before payment (ECTA s44). */}
            <div className="flex items-baseline justify-between gap-3">
              <h2 className="font-display text-xl font-black uppercase">Review your order</h2>
              <Link href="/cart/" className="text-sm font-bold underline">Edit cart</Link>
            </div>
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
                          {e.spiceLevel ? <span className="block text-xs text-ash">{e.spiceLevel}</span> : null}
                          {e.selectedAddOns.map((addOn) => <span key={addOn.name} className="block text-xs text-ash">+ {addOn.name} (R{addOn.price.toFixed(2)})</span>)}
                          {e.notes?.trim() ? <span className="block text-xs text-ash">Note: {e.notes.trim()}</span> : null}
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
              <div className="flex justify-between text-[1.05rem]"><span className="font-black">Total to pay now</span><span className="font-black text-peri-red">R{totalForType(orderType).toFixed(2)}</span></div>
              <p className="flex items-center gap-2 rounded-2xl bg-muted p-3 text-xs leading-5 text-ash"><ShieldCheck size={16} className="shrink-0 text-leaf" /> Your card details stay on the hosted payment page.</p>
            </div>

            <dl data-testid="order-review-details" className="mt-4 grid gap-2 border-t border-black/8 pt-4 text-sm">
              <div><dt className="text-xs font-black uppercase tracking-[0.14em] text-ash">{orderType === "delivery" ? "Delivery to" : "Collect from"}</dt>
                <dd className="mt-0.5 font-semibold">{orderType === "delivery" ? (address.trim() || "Enter your delivery address") : siteConfig.address}</dd></div>
              <div><dt className="text-xs font-black uppercase tracking-[0.14em] text-ash">Contact</dt>
                <dd className="mt-0.5 font-semibold">{[name.trim(), phone.trim()].filter(Boolean).join(", ") || "Enter your name and phone"}</dd></div>
            </dl>
            <p className="mt-3 text-xs leading-5 text-ash">
              You pay the full amount by card now, and we start preparing your order once the payment is confirmed. Until you pay, you can change or leave your order and nothing is charged.{" "}
              <Link href="/terms-and-conditions/" className="font-bold underline">Cancellations and refunds</Link>.
            </p>

            <div className="mt-5">
              <PolicyConsent checked={acceptedPolicies} onChange={(value) => { setAcceptedPolicies(value); if (value) setFieldErrors((current) => { const rest = { ...current }; delete rest.consent; return rest; }); }} error={fieldErrors.consent} />
            </div>

            <button onClick={handleSubmit} disabled={submitting || entries.length === 0 || !yocoAvailable || !settings || !storeOpen || !globalStoreOpen} aria-busy={submitting} className="button button-primary mt-6 w-full justify-center disabled:opacity-40">
              {submitting ? "Opening payment…" : `Pay by card • R${totalForType(orderType).toFixed(2)}`}
              {!submitting && <ArrowRight size={18} />}
            </button>

            <div className="mt-4 flex items-center gap-2 text-xs font-semibold text-ash">
              <Clock3 size={14} /> {orderType === "delivery" ? "45–60 min (incl. delivery)" : "~25 min"}
            </div>
            <p className="mt-3 text-center text-xs font-semibold text-ash">Flame-grilled in Bloemfontein. Prepared after payment.</p>
          </aside>
        </div>
      </section>
    </main>
  );
}

