"use client";

import { useEffect, useEffectEvent, useState } from "react";
import Link from "next/link";
import { CreditCard, ArrowRight } from "lucide-react";
import { createBrowserClient } from "@/lib/supabase";
import { useCart } from "@/lib/cart";

export default function PaymentStatus({ id }: { id: string }) {
  const [message, setMessage] = useState("Checking payment with the restaurant…");
  const [mobile, setMobile] = useState(false);
  const { clear, entries } = useCart();
  const finishPayment = useEffectEvent(() => {
    try {
      const saved = JSON.parse(localStorage.getItem("peri_q_pending_payment") ?? "null");
      // A delayed payment must not erase items added in another tab or later visit.
      if (saved?.orderId === id) {
        if (saved.cart === JSON.stringify(entries)) clear();
        localStorage.removeItem("peri_q_pending_payment");
        localStorage.removeItem("peri_q_checkout_request");
      }
    } catch { /* Storage is optional; database confirmation remains authoritative. */ }
    window.location.replace(`/order/${id}/?new=1`);
  });

  useEffect(() => {
    const query = new URLSearchParams(window.location.search);
    if (query.get("source") === "mobile") {
      setMobile(true);
      setMessage("Return to the app to check your payment. Your order appears after payment is confirmed. If you left checkout, your cart stays saved. Check Orders before paying again.");
      return;
    }
    let stopped = false;
    let checking = false;
    let confirmed = false;
    const check = async () => {
      if (stopped || checking || confirmed || document.visibilityState === "hidden") return;
      checking = true;
      try {
        const { data, error } = await createBrowserClient().from("checkout_intents")
          .select("payment_status").eq("id", id).maybeSingle();
        if (stopped) return;
        if (error) throw error;
        if (!data) {
          setMessage("This checkout is unavailable in this browser. Sign in with the account you used to pay, or return to the app. Check your orders before paying again.");
          return;
        }
        if (data.payment_status === "paid") {
          confirmed = true;
          finishPayment();
          return;
        }
        const status = String(data.payment_status);
        setMessage(status === "failed" ? "Payment could not be completed. Your cart is saved. You can return to checkout to try your card again."
          : status === "cancelled" ? "Payment was cancelled. Your cart is saved."
          : status === "expired" ? "This payment session expired. Contact the restaurant before paying again."
          : status === "refunded" ? "This payment has been refunded. Contact the restaurant if you need help."
          : query.get("checkout") === "cancel" ? "You returned from card checkout. Payment has not been confirmed yet. Your cart is saved; check your orders before paying again."
          : "Waiting for payment confirmation. You can close this page; a confirmed payment will still create your order. Check your orders before paying again.");
      } catch {
        if (!stopped) setMessage("Could not check payment. We’ll try again automatically. Your cart is saved; check your orders before paying again.");
      } finally {
        checking = false;
      }
    };
    void check();
    const timer = window.setInterval(() => void check(), 3000);
    const resume = () => void check();
    document.addEventListener("visibilitychange", resume);
    window.addEventListener("online", resume);
    return () => {
      stopped = true;
      window.clearInterval(timer);
      document.removeEventListener("visibilitychange", resume);
      window.removeEventListener("online", resume);
    };
  }, [id]);

  return (
    <main id="main-content" className="site-shell py-16 sm:py-24">
      <section className="mx-auto max-w-xl rounded-2xl border border-black/10 bg-white p-6 sm:p-10">
        <CreditCard size={32} className="text-peri-red" aria-hidden="true" />
        <h1 className="mt-6 text-3xl font-bold tracking-tight">Your card payment</h1>
        <p role="status" aria-live="polite" className="my-6 text-base leading-7 text-ash">{message}</p>
        <div className="flex flex-wrap gap-3">
          {!mobile && <Link className="button button-dark" href="/account/">View my orders <ArrowRight size={16} aria-hidden="true" /></Link>}
          <Link className="button border-black/15 text-charcoal" href="/checkout/">Return to checkout</Link>
        </div>
      </section>
    </main>
  );
}
