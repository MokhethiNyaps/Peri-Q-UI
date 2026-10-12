import { NextResponse } from "next/server";
import { createServiceClient, readServerSupabaseConfig } from "@/lib/supabase";
import { getSiteUrl, readYocoEnv } from "@/lib/yoco";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

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
    return NextResponse.json({ error: "Missing orderId (UUID). Create the order first via place_order, then call this endpoint.", code: "missing_order_id" }, { status: 400 });
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
    const { data, error } = await svc.from("orders").select("id,order_number,user_id,total_price,payment_method,payment_status,paid_at,yoco_checkout_id,yoco_mode,client_request_id,created_at").eq("id", orderId.trim()).maybeSingle();
    if (error) throw error;
    order = (data as Record<string, unknown> | null) ?? null;
    if (!order || order.user_id !== auth.user.id) {
      return NextResponse.json({ error: "Order not found. Ensure the order was created with the same Supabase project that the website uses.", code: "order_not_found" }, { status: 404 });
    }
    const paymentStatus = String(order["payment_status"] ?? "unpaid");
    const paidAt = order["paid_at"] as string | null;
    if (paymentStatus === "paid" || !!paidAt) {
      return NextResponse.json({ error: "Order is already paid. Do not pay twice.", code: "already_paid" }, { status: 409 });
    }
    const pm = String(order["payment_method"] ?? "");
    if (pm !== "yoco" && pm !== "card") {
      return NextResponse.json(
        { error: `Order payment_method is '${pm}'. Recreate the order with paymentMethod 'yoco' at checkout, or change payment method to Yoco.`, code: "wrong_payment_method" },
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
    const successUrl = `${siteUrl}/order/${orderId.trim()}/?checkout=success`;
    const cancelUrl = `${siteUrl}/order/${orderId.trim()}/?checkout=cancel`;
    const failureUrl = `${siteUrl}/order/${orderId.trim()}/?checkout=failure`;

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
        .from("orders")
        .update({
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

      // Insert once, then update only unpaid attempts. A retry must not reset
      // an audit row that a concurrent webhook has already marked succeeded.
      const paymentRow =
        {
          order_id: String(order["id"]),
          yoco_checkout_id: checkoutId,
          amount_cents: amountCents,
          currency: "ZAR",
          status: "pending",
          raw_payload: json,
          mode,
          updated_at: new Date().toISOString(),
        };
      const { error: payErr } = await svc2.from("payments").upsert(
        paymentRow,
        { onConflict: "order_id", ignoreDuplicates: true },
      );
      if (payErr) {
        throw payErr;
      }
      const { error: updateError } = await svc2.from("payments")
        .update(paymentRow).eq("order_id", String(order["id"]))
        .neq("status", "succeeded");
      if (updateError) throw updateError;
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
