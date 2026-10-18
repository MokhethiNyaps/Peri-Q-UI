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
          "Yoco is not configured on the server. Owner: add YOCO_SECRET_KEY (sk_test_/sk_live_) and YOCO_WEBHOOK_SECRET (whsec_...) in Vercel → Project Settings → Environment Variables and redeploy. Test keys work immediately; live keys need verified domain.",
        code: "yoco_not_configured",
      },
      { status: 503 },
    );
  }
  const supaCfg = readServerSupabaseConfig();
  if (!supaCfg) {
    return NextResponse.json(
      { error: "Supabase server env missing: set SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY in Vercel (Production) and redeploy.", code: "supabase_not_configured" },
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
    return NextResponse.json({ error: "Missing orderId (UUID). Prepare a card checkout first, then call this endpoint.", code: "missing_order_id" }, { status: 400 });
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
      return NextResponse.json({ error: "Order not found. Ensure the order was created with the same Supabase project that the website uses.", code: "order_not_found" }, { status: 404 });
    }
    if (order.redirect_url) return NextResponse.json({ redirectUrl: order.redirect_url, checkoutId: order.yoco_checkout_id });
    const paymentStatus = String(order["payment_status"] ?? "unpaid");
    const paidAt = order["paid_at"] as string | null;
    if (paymentStatus === "paid" || !!paidAt) {
      return NextResponse.json({ error: "Order is already paid. Do not pay twice.", code: "already_paid" }, { status: 409 });
    }
    const pm = String(order["payment_method"] ?? "");
    if (pm !== "yoco" && pm !== "card") {
      return NextResponse.json(
        { error: `Order payment_method is '${pm}'. Prepare checkout with paymentMethod 'yoco' at checkout, or change payment method to Yoco.`, code: "wrong_payment_method" },
        { status: 409 },
      );
    }

    const totalPrice = Number(order["total_price"] ?? 0);
    const amountCents = Math.round(totalPrice * 100);
    if (!Number.isFinite(amountCents) || amountCents < 200) {
      // Yoco minimum R2.00 = 200c
      return NextResponse.json({ error: `Order amount R${totalPrice.toFixed(2)} is below Yoco minimum R2.00 or invalid. Check menu prices.`, code: "amount_too_small" }, { status: 422 });
    }
    if (String(order["payment_status"]) === "refunded") {
      return NextResponse.json({ error: "Order was refunded; cannot create a new checkout.", code: "refunded" }, { status: 409 });
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
      source: "website",
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
    });

    const text = await res.text();
    let json: Record<string, unknown> = {};
    try {
      json = text ? (JSON.parse(text) as Record<string, unknown>) : {};
    } catch {
      json = { raw: text };
    }

    if (!res.ok) {
      const detail = (json["description"] as string) || (json["error"] as string) || text || `Yoco returned ${res.status}`;
      // Map common errors
      return NextResponse.json(
        {
          error: `Yoco checkout failed: ${detail}. Check YOCO_SECRET_KEY (test vs live), amount >= R2.00, and that site URL is ${siteUrl} (live requires verified domain).`,
          code: "yoco_error",
          yocoStatus: res.status,
          yocoBody: json,
        },
        { status: 502 },
      );
    }

    const checkoutId = String(json["id"] ?? "");
    const redirectUrl = String(json["redirectUrl"] ?? json["redirect_url"] ?? "");
    const processingMode = (json["processingMode"] as string) ?? (json["processing_mode"] as string) ?? (yocoEnv.secretKey.startsWith("sk_test_") ? "test" : "live");
    const mode = processingMode === "test" ? "test" : processingMode === "live" ? "live" : null;

    if (!checkoutId || !redirectUrl) {
      return NextResponse.json({ error: "Yoco did not return redirectUrl. Response: " + text.slice(0, 800), code: "yoco_bad_response", yocoBody: json }, { status: 502 });
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

    } catch (e) {
      console.error("Could not persist Yoco checkout", e);
      return NextResponse.json({ error: "Could not save payment details. Please retry from your order page.", code: "payment_save_failed" }, { status: 503 });
    }

    return NextResponse.json({ checkoutId, redirectUrl, amountCents, mode, orderId: String(order["id"]) });
  } catch (e) {
    console.error("yoco checkout error", e);
    return NextResponse.json({ error: e instanceof Error ? e.message : "Could not create Yoco checkout.", code: "internal" }, { status: 500 });
  }
}
