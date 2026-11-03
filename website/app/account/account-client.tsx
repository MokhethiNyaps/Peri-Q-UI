"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import Link from "next/link";
import { useCustomerAuth } from "@/lib/customer-auth";
import { useCart } from "@/lib/cart";
import { createBrowserClient, isSupabaseConfigured } from "@/lib/supabase";
import { registerCustomer, requestPasswordReset, saveCustomerProfile, setCustomerPassword, signInCustomer, signOutCustomer } from "@/lib/customer-account";
import { PolicyConsent, PrivacyNotice } from "@/components/policy-consent";
import { PrivacyPanel } from "@/components/privacy-panel";

type Mode = "signin" | "signup" | "reset" | "password";
type OrderSummary = { id: string; order_number: number; created_at: string; status: string; total_price: number };
const fieldClass = "mt-2 w-full rounded-xl border border-black/20 bg-white px-4 py-3 text-base focus:border-peri-red focus:outline-none focus:ring-2 focus:ring-peri-red/20";

export default function AccountClient() {
  const { user, profile, loading, profileError, refreshProfile } = useCustomerAuth();
  const { clear } = useCart();
  const [mode, setMode] = useState<Mode>("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [acceptedPolicies, setAcceptedPolicies] = useState(false);
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [orders, setOrders] = useState<OrderSummary[]>([]);
  const [ordersLoading, setOrdersLoading] = useState(false);
  const [ordersError, setOrdersError] = useState<string | null>(null);
  const [orderRevision, setOrderRevision] = useState(0);
  const signedIn = !!user && !user.is_anonymous;
  const accountId = signedIn ? user.id : null;
  const profileId = profile?.id;
  const savedName = profile?.full_name;
  const savedPhone = profile?.phone;

  useEffect(() => {
    if (new URLSearchParams(window.location.search).get("mode") === "password") setMode("password");
  }, []);
  useEffect(() => {
    if (profileId) { setName(savedName ?? ""); setPhone(savedPhone ?? ""); }
    else if (!signedIn) { setName(""); setPhone(""); }
  }, [profileId, savedName, savedPhone, signedIn]);
  useEffect(() => {
    let active = true;
    setOrders([]);
    setOrdersError(null);
    if (!accountId) return;
    setOrdersLoading(true);
    void createBrowserClient().from("orders")
      .select("id,order_number,created_at,status,total_price")
      .eq("user_id", accountId).order("created_at", { ascending: false }).limit(50)
      .then(({ data, error: orderError }) => {
        if (!active) return;
        if (orderError) setOrdersError("Could not load your orders. Please try again.");
        else setOrders((data ?? []) as OrderSummary[]);
        setOrdersLoading(false);
      }, () => {
        if (active) {
          setOrdersError("Could not load your orders. Please try again.");
          setOrdersLoading(false);
        }
      });
    return () => { active = false; };
  }, [accountId, orderRevision]);

  const perform = async (action: () => Promise<void>) => {
    if (busyRef.current) return;
    busyRef.current = true; setBusy(true); setError(null); setMessage(null);
    try { await action(); }
    catch (cause) { setError(cause instanceof Error ? cause.message : "Could not complete this request. Please try again."); }
    finally { busyRef.current = false; setBusy(false); }
  };
  const submitAuth = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    void perform(async () => {
      if (mode === "reset") {
        await requestPasswordReset(email);
        setMessage("If an account exists for this email, you’ll receive a password reset link. Check your inbox and spam folder.");
      } else if (mode === "signup") {
        if (password !== confirmPassword) throw new Error("The passwords do not match.");
        if (!acceptedPolicies) throw new Error("Accept the terms and conditions to create an account.");
        const result = await registerCustomer(email, password, name, phone);
        setPassword(""); setConfirmPassword("");
        if (!result.session) setMessage("Account created. Check your email to confirm it, then sign in.");
        else setMessage("Your account is ready.");
      } else {
        await signInCustomer(email, password); setPassword("");
      }
    });
  };
  const submitProfile = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    void perform(async () => { await saveCustomerProfile(name, phone); await refreshProfile(); setMessage("Your details are saved."); });
  };
  const submitPassword = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    void perform(async () => {
      if (password !== confirmPassword) throw new Error("The passwords do not match.");
      await setCustomerPassword(password); setPassword(""); setConfirmPassword(""); setMode("signin");
      window.history.replaceState(null, "", "/account/"); setMessage("Your password is updated.");
    });
  };
  const changeMode = (next: Mode) => { setMode(next); setError(null); setMessage(null); setPassword(""); setConfirmPassword(""); };

  return <main id="main-content" className="bg-cream">
    <section className="stage stage-glow grill-lines overflow-hidden py-10"><div className="site-shell">
      <h1 className="font-display text-4xl font-black uppercase sm:text-5xl">{signedIn ? "My account" : mode === "signup" ? "Create an account" : mode === "reset" ? "Reset your password" : "Sign in"}</h1>
      <p className="mt-3 max-w-xl text-sm leading-6 text-white/75">Use the same email and password as the RastasperiQ mobile app. Your details and orders are available here too.</p>
    </div></section>
    <section className="site-shell py-10">
      {loading ? <p role="status" className="py-8">Loading your account…</p> : !isSupabaseConfigured() ? <p role="alert">Accounts are temporarily unavailable. Please try again later.</p> : <>
        {error && <p role="alert" className="mb-6 rounded-xl border border-red-200 bg-red-50 p-4 text-red-900">{error}</p>}
        {message && <p role="status" className="mb-6 rounded-xl border border-leaf/20 bg-leaf/10 p-4">{message}</p>}
        {!signedIn ? <div className="max-w-lg border border-black/10 bg-white p-6 sm:p-8">
          <form onSubmit={submitAuth} className="grid gap-5">
            {mode === "signup" && <>
              <label className="font-bold">Full name<input className={fieldClass} autoComplete="name" required minLength={2} maxLength={100} value={name} onChange={(e) => setName(e.target.value)} /></label>
              <label className="font-bold">Phone number<input className={fieldClass} type="tel" autoComplete="tel" required maxLength={30} value={phone} onChange={(e) => setPhone(e.target.value)} /></label>
            </>}
            <label className="font-bold">Email address<input className={fieldClass} type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} /></label>
            {mode !== "reset" && <label className="font-bold">Password<input className={fieldClass} type="password" autoComplete={mode === "signup" ? "new-password" : "current-password"} required minLength={mode === "signup" ? 8 : undefined} value={password} onChange={(e) => setPassword(e.target.value)} /></label>}
            {mode === "signup" && <label className="font-bold">Confirm password<input className={fieldClass} type="password" autoComplete="new-password" required minLength={8} value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} /></label>}
            {mode === "signup" && <>
              <PrivacyNotice purpose="We use your name, email and phone number to run your account and your orders." />
              <PolicyConsent checked={acceptedPolicies} onChange={setAcceptedPolicies} />
            </>}
            <button disabled={busy} className="button button-primary justify-center disabled:opacity-50">{busy ? "Please wait…" : mode === "signup" ? "Create account" : mode === "reset" ? "Send reset link" : "Sign in"}</button>
          </form>
          <div className="mt-6 flex flex-wrap gap-x-5 gap-y-3 text-sm">
            {mode !== "signin" && <button disabled={busy} onClick={() => changeMode("signin")} className="underline">Back to sign in</button>}
            {mode === "signin" && <><button onClick={() => changeMode("signup")} className="font-bold underline">Create account</button><button onClick={() => changeMode("reset")} className="underline">Forgot password?</button></>}
          </div>
          {mode === "signup" && <p className="mt-5 text-sm leading-6 text-ash">Guest orders placed before registration remain linked to that guest session. Sign in before placing new orders to save them in your account.</p>}
          <Link href="/menu/" className="mt-6 inline-block text-sm font-bold underline">Continue browsing the menu</Link>
        </div> : <div className="grid items-start gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.3fr)]">
          <div className="border border-black/10 bg-white p-6 sm:p-8">
            <h2 className="font-display text-2xl font-bold uppercase">Your details</h2>
            <p className="mt-2 break-all text-sm text-ash">{user.email}</p>
            {profileError && <div role="alert" className="mt-4 text-red-800">{profileError} <button onClick={() => void perform(refreshProfile)} className="underline">Refresh profile</button></div>}
            <form onSubmit={submitProfile} className="mt-6 grid gap-5">
              <label className="font-bold">Full name<input className={fieldClass} autoComplete="name" required minLength={2} maxLength={100} value={name} onChange={(e) => setName(e.target.value)} /></label>
              <label className="font-bold">Phone number<input className={fieldClass} type="tel" autoComplete="tel" required maxLength={30} value={phone} onChange={(e) => setPhone(e.target.value)} /></label>
              <button disabled={busy} className="button button-primary justify-center disabled:opacity-50">{busy ? "Saving…" : "Save details"}</button>
            </form>
            {mode === "password" ? <form onSubmit={submitPassword} className="mt-8 grid gap-4 border-t border-black/10 pt-6">
              <h2 className="font-display text-xl font-bold uppercase">Choose a new password</h2>
              <label className="font-bold">New password<input className={fieldClass} type="password" autoComplete="new-password" required minLength={8} value={password} onChange={(e) => setPassword(e.target.value)} /></label>
              <label className="font-bold">Confirm new password<input className={fieldClass} type="password" autoComplete="new-password" required minLength={8} value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} /></label>
              <button disabled={busy} className="button button-primary justify-center disabled:opacity-50">Update password</button>
            </form> : <button onClick={() => changeMode("password")} className="mt-6 text-sm underline">Change password</button>}
            <button disabled={busy} onClick={() => void perform(async () => { await signOutCustomer(); clear(); setName(""); setPhone(""); setOrders([]); setMode("signin"); })} className="mt-6 ml-6 text-sm font-bold underline">Sign out</button>
          </div>
          <div>
            <h2 className="font-display text-2xl font-bold uppercase">Your orders</h2>
            {ordersLoading ? <p role="status" className="mt-6">Loading your orders…</p> : ordersError ? <p role="alert" className="mt-6">{ordersError} <button onClick={() => setOrderRevision((v) => v + 1)} className="underline">Retry</button></p> : !orders.length ? <p className="mt-6 text-ash">You haven’t placed an order with this account yet. <Link href="/menu/" className="font-bold underline">Browse the menu</Link>.</p> : <ul className="mt-4 divide-y divide-black/15 border-y border-black/15">
              {orders.map((order) => <li key={order.id}><Link href={`/order/${order.id}/`} className="flex flex-wrap items-center justify-between gap-3 py-5 hover:text-peri-red">
                <span><span className="block font-bold">Order #{order.order_number}</span><span className="mt-1 block text-sm text-ash">{new Date(order.created_at).toLocaleDateString("en-ZA", { timeZone: "Africa/Johannesburg" })} · <span className="capitalize">{order.status}</span></span></span>
                <span className="font-bold">R{Number(order.total_price).toFixed(2)} <span aria-hidden="true">→</span></span>
              </Link></li>)}
            </ul>}
          </div>
          <div className="lg:col-span-2"><PrivacyPanel userId={user.id} onDeleted={() => { clear(); setName(""); setPhone(""); setOrders([]); setMode("signin"); setMessage("Your account has been deleted."); }} /></div>
        </div>}
      </>}
    </section>
  </main>;
}
