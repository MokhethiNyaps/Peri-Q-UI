import { NextResponse } from "next/server";
import { createServiceClient, readServerSupabaseConfig } from "@/lib/supabase";
import { getSiteUrl, readYocoEnv } from "@/lib/yoco";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Expose readiness, never credentials. Checkout stays unavailable until the
// server keys and payment schema are present.
export async function GET() {
  let available = false;
  if (readYocoEnv() && readServerSupabaseConfig()) {
    try {
      const svc = createServiceClient();
      const [orders, payments] = await Promise.all([
        svc.from("checkout_intents").select("yoco_checkout_id,payment_status").limit(0),
        svc.from("payments").select("id").limit(0),
      ]);
      available = !orders.error && !payments.error;
    } catch {
      // Missing configuration or a database outage must fail closed.
    }
  }
  const mode = readYocoEnv()?.secretKey.startsWith("sk_test_") ? "test" : "live";
  return NextResponse.json(available ? { available, mode } : { available }, { headers: { "Cache-Control": "no-store" } });
}

// POST { orderId: string }
export async function POST(req: Request) {
  const yocoEnv = readYocoEnv();
  if (!yocoEnv) {
    return NextResponse.json(
      {
        error:
          "Card payments are temporarily unavailable. Your cart is saved. Please try again later.",
        code: "yoco_not_configured",
      },
      { status: 503 },
    );
  }
  const supaCfg = readServerSupabaseConfig();
  if (!supaCfg) {
    return NextResponse.json(
      { error: "Ordering is temporarily unavailable. Your cart is saved. Please try again later.", code: "supabase_not_configured" },
      { status: 503 },
    );
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body. Expected { orderId }.", code: "bad_request" }, { status: 400 });
  }
  const orderId = (body as { orderId?: unknown })?.orderId;
  if (typeof orderId !== "string" || !orderId.trim()) {
    return NextResponse.json({ error: "Please return to checkout and try again.", code: "missing_order_id" }, { status: 400 });
  }

  const token = req.headers.get("authorization")?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) {
    return NextResponse.json({ error: "Sign in before paying for an order.", code: "unauthorized" }, { status: 401 });
  }

  let order: Record<string, unknown> | null = null;
  try {
    const svc = createServiceClient();
    const { data: auth, error: authError } = await svc.auth.getUser(token);
    if (authError || !auth.user) {
      return NextResponse.json({ error: "Your session has expired. Please try again.", code: "unauthorized" }, { status: 401 });
    }
    const { data, error } = await svc.from("checkout_intents").select("id,order_number,redirect_url,user_id,total_price,payment_method,payment_status,paid_at,yoco_checkout_id,yoco_mode,client_request_id,created_at").eq("id", orderId.trim()).maybeSingle();
    if (error) throw error;
    order = (data as Record<string, unknown> | null) ?? null;
    if (!order || order.user_id !== auth.user.id) {
      return NextResponse.json({ error: "Checkout not found for your account. Please return to checkout.", code: "order_not_found" }, { status: 404 });
    }
    const paymentStatus = String(order["payment_status"] ?? "unpaid");
    const paidAt = order["paid_at"] as string | null;
    if (paymentStatus === "paid" || !!paidAt) {
      return NextResponse.json({ error: "Order is already paid. Do not pay twice.", code: "already_paid" }, { status: 409 });
    }
    const pm = String(order["payment_method"] ?? "");
    if (pm !== "yoco" && pm !== "card") {
      return NextResponse.json(
        { error: "Only card payments are supported. Please return to checkout.", code: "wrong_payment_method" },
        { status: 409 },
      );
    }

    const totalPrice = Number(order["total_price"] ?? 0);
    const amountCents = Math.round(totalPrice * 100);
    if (!Number.isSafeInteger(amountCents) || amountCents < 200) {
      // Yoco minimum R2.00 = 200c
      return NextResponse.json({ error: "The order total must be at least R2.00. Please review your cart.", code: "amount_too_small" }, { status: 422 });
    }
    if (String(order["payment_status"]) === "refunded") {
      return NextResponse.json({ error: "Order was refunded; cannot create a new checkout.", code: "refunded" }, { status: 409 });
    }

    const expectedMode = yocoEnv.secretKey.startsWith("sk_test_") ? "test" : "live";
    if (order.yoco_checkout_id && order.yoco_mode !== expectedMode) {
      return NextResponse.json({ error: "This checkout is no longer available. Contact the restaurant before paying again.", code: "checkout_mode_changed" }, { status: 409 });
    }
    if (order.redirect_url) return NextResponse.json({ redirectUrl: order.redirect_url, checkoutId: order.yoco_checkout_id });
    // Provider idempotency keys expire after 24 hours. Never recreate an
    // uncertain session after that window, even if its linkage write failed.
    const createdAt = Date.parse(String(order.created_at ?? ""));
    if (!Number.isFinite(createdAt) || Date.now() - createdAt >= 23 * 60 * 60 * 1000) {
      return NextResponse.json({ error: "This checkout needs a payment check. Contact the restaurant before paying again.", code: "checkout_expired" }, { status: 409 });
    }

    const siteUrl = getSiteUrl();
    const mobile = (body as {source?:string}).source === "mobile";
    const successUrl = `${siteUrl}/payment/${orderId.trim()}/?checkout=success${mobile ? "&source=mobile" : ""}`;
    const cancelUrl = `${siteUrl}/payment/${orderId.trim()}/?checkout=cancel${mobile ? "&source=mobile" : ""}`;
    const failureUrl = `${siteUrl}/payment/${orderId.trim()}/?checkout=failure${mobile ? "&source=mobile" : ""}`;

    const idempotencyKey = String(order["client_request_id"] ?? order["id"] ?? `${orderId}-web`);

    // Build display line items limit? Yoco lineItems are display-only. Keep minimal for now (amount alone is authoritative).
    const metadata: Record<string, unknown> = {
      order_id: String(order["id"]),
      order_number: String(order["order_number"] ?? ""),
      source: mobile ? "mobile" : "website",
    };

    const yocoBody = {
      amount: amountCents,
      currency: "ZAR",
      successUrl,
      cancelUrl,
      failureUrl,
      metadata,
    };

    // Call Yoco Checkout API
    const res = await fetch("https://payments.yoco.com/api/checkouts", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${yocoEnv.secretKey}`,
        "Content-Type": "application/json",
        "Idempotency-Key": idempotencyKey,
      },
      body: JSON.stringify(yocoBody),
      signal: AbortSignal.timeout(20_000),
    });

    const text = await res.text();
    let json: Record<string, unknown> = {};
    try {
      json = text ? (JSON.parse(text) as Record<string, unknown>) : {};
    } catch {
      json = { raw: text };
    }

    if (!res.ok) {
      console.error("Card checkout provider request failed", { status: res.status });
      return NextResponse.json({ error: "Payment could not start. Please try again; your cart is saved.", code: "yoco_error" }, { status: 502 });
    }

    const checkoutId = String(json["id"] ?? "");
    const redirectUrl = String(json["redirectUrl"] ?? json["redirect_url"] ?? "");
    const processingMode = (json["processingMode"] as string) ?? (json["processing_mode"] as string) ?? (yocoEnv.secretKey.startsWith("sk_test_") ? "test" : "live");
    const mode = processingMode === "test" ? "test" : processingMode === "live" ? "live" : null;

    if (!checkoutId || !redirectUrl || mode !== expectedMode) {
      return NextResponse.json({ error: "Payment could not start. Please try again; your cart is saved.", code: "yoco_bad_response" }, { status: 502 });
    }

    // Persist checkout linkage (idempotent)
    try {
      const svc2 = createServiceClient();
      // Update orders with checkout id + ensure payment_status pending
      const { error: orderError } = await svc2
        .from("checkout_intents")
        .update({
          redirect_url: redirectUrl,
          yoco_checkout_id: checkoutId,
          payment_status: "pending",
          yoco_mode: mode,
          payment_amount_cents: amountCents,
          updated_at: new Date().toISOString(),
        })
        .eq("id", order["id"] as string)
        .is("paid_at", null)
        .not("payment_status", "in", "(paid,refunded)");
      if (orderError) throw orderError;

    } catch {
      console.error("Could not persist card checkout", { checkoutId });
      return NextResponse.json({ error: "Could not save payment details. Please retry from your order page.", code: "payment_save_failed" }, { status: 503 });
    }

    return NextResponse.json({ checkoutId, redirectUrl, amountCents, mode, orderId: String(order["id"]) });
  } catch (e) {
    console.error("Card checkout request failed", { type: e instanceof Error ? e.name : "unknown" });
    return NextResponse.json({ error: "Payment could not start. Please try again; your cart is saved.", code: "internal" }, { status: 503 });
  }
}

