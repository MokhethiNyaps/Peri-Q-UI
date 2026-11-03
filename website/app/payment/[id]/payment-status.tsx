"use client";

import { useEffect, useEffectEvent, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { CreditCard, ArrowRight, CheckCircle2, XCircle } from "lucide-react";
import { createBrowserClient } from "@/lib/supabase";
import { useCart } from "@/lib/cart";

export default function PaymentStatus({ id }: { id: string }) {
  const [message, setMessage] = useState("Checking payment with the restaurant…");
  const [mobile, setMobile] = useState(false);
  const [mobileResult, setMobileResult] = useState<MobileResult>("success");
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
      // App customers pay in a browser sheet on top of the app. Send them
      // straight back; the app confirms the payment from the database.
      const result = mobileResultFrom(query.get("checkout"));
      setMobile(true);
      setMobileResult(result);
      // Older app versions cannot open the return link; Android then sends
      // them back here with noapp=1 instead of to the Play Store.
      if (query.get("noapp") === "1") {
        setMessage("Return to the app to check your payment. Your order appears after payment is confirmed. If you left checkout, your cart stays saved. Check Orders before paying again.");
        return;
      }
      setMessage(MOBILE_MESSAGES[result]);
      const timer = window.setTimeout(() => {
        try {
          window.location.assign(appReturnLink(id, result, navigator.userAgent, noAppFallback(result)));
        } catch { /* The button below still works. */ }
      }, 500);
      return () => window.clearTimeout(timer);
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

  if (mobile) {
    const success = mobileResult === "success";
    return (
      <main id="main-content" className="stage stage-glow grill-lines grid min-h-[80svh] place-items-center px-5 py-16">
        <section className="w-full max-w-md rounded-[1.5rem] border border-white/10 bg-charcoal p-7 text-center shadow-2xl">
          <Image src="/brand/flame-mark-192.png" alt="" width={72} height={72} className="mx-auto size-16" priority />
          <p className="mt-5 inline-flex items-center gap-2 text-xs font-black uppercase tracking-[0.18em] text-orange">
            {success ? <CheckCircle2 size={15} aria-hidden="true" /> : <XCircle size={15} aria-hidden="true" />}
            {success ? "Payment sent" : mobileResult === "cancel" ? "Payment cancelled" : "Payment not completed"}
          </p>
          <h1 className="mt-3 font-display text-4xl font-extrabold uppercase leading-[0.95] text-cream">
            {success ? "Back to RastasperiQ" : "Your cart is saved"}
          </h1>
          <p role="status" aria-live="polite" className="mt-4 text-sm leading-6 text-smoke">{message}</p>
          <a
            href={appReturnLink(id, mobileResult, typeof navigator === "undefined" ? "" : navigator.userAgent, noAppFallback(mobileResult))}
            className="button button-primary mt-7 w-full"
          >
            Return to the app
            <ArrowRight size={18} aria-hidden="true" />
          </a>
        </section>
      </main>
    );
  }

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

type MobileResult = "success" | "cancel" | "failure";

const MOBILE_MESSAGES: Record<MobileResult, string> = {
  success: "Taking you back to the app to confirm your order. If nothing happens, tap Return to the app.",
  cancel: "You left the payment page before paying. Return to the app to try again or change your order.",
  failure: "The payment did not go through and no order was placed. Return to the app to try again.",
};

function mobileResultFrom(value: string | null): MobileResult {
  return value === "cancel" || value === "failure" ? value : "success";
}

/**
 * Link back into the RastasperiQ Android app. On Android, an intent link
 * opens the app directly (or its Play Store page if it is not installed);
 * elsewhere the plain app scheme is used. The result is only a hint for the
 * app: payment is confirmed from the database.
 */
export function appReturnLink(orderId: string, result: MobileResult, userAgent: string, fallbackUrl?: string): string {
  const query = `order=${encodeURIComponent(orderId)}&result=${result}`;
  if (/android/i.test(userAgent)) {
    const fallback = fallbackUrl ? `S.browser_fallback_url=${encodeURIComponent(fallbackUrl)};` : "";
    return `intent://payment-return?${query}#Intent;scheme=rastasperiq;package=za.co.rastasperiq.ordering;${fallback}end`;
  }
  return `rastasperiq://payment-return?${query}`;
}

/** This page again, without the automatic return, for app versions that cannot open the link. */
function noAppFallback(result: MobileResult): string | undefined {
  if (typeof window === "undefined") return undefined;
  return `${window.location.origin}${window.location.pathname}?checkout=${result}&source=mobile&noapp=1`;
}
