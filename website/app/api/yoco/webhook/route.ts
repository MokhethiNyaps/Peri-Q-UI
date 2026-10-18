import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { readYocoEnv, verifyYocoWebhook } from "@/lib/yoco";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Supabase returns database errors rather than throwing them. Never acknowledge
// a payment event until every required write has succeeded.
async function checked<T>(query: PromiseLike<{ data: T; error: unknown }>): Promise<T> {
  const result = await query;
  if (result.error) throw result.error;
  return result.data;
}

export async function POST(req: Request) {
  const env = readYocoEnv();
  if (!env) return NextResponse.json({ error: "Payments are unavailable." }, { status: 503 });
  const rawBody = await req.text();
  const verification = verifyYocoWebhook({
    rawBody,
    headers: {
      webhookId: req.headers.get("webhook-id"),
      webhookTimestamp: req.headers.get("webhook-timestamp"),
      webhookSignature: req.headers.get("webhook-signature"),
    },
    secret: env.webhookSecret,
  });
  if (!verification.ok) return NextResponse.json({ error: "Invalid signature." }, { status: 401 });

  let event: Record<string, unknown>;
  try {
    event = JSON.parse(rawBody);
    if (!event || typeof event !== "object") throw new Error();
  } catch {
    return NextResponse.json({ error: "Invalid event." }, { status: 400 });
  }
  const eventId = String(event.id ?? "");
  const eventType = String(event.type ?? "");
  if (!eventId || !eventType) return NextResponse.json({ error: "Missing event ID or type." }, { status: 422 });
  if (!["payment.succeeded", "payment.failed"].includes(eventType)) {
    return NextResponse.json({ ok: true, ignored: eventType });
  }
  const payload = event.payload as Record<string, unknown> | undefined;
  const metadata = payload?.metadata as Record<string, unknown> | undefined;
  // payload.id is a PAYMENT ID; metadata.checkoutId identifies our checkout.
  const checkoutId = String(metadata?.checkoutId ?? "");
  const paymentId = String(payload?.id ?? "");
  const amount = Number(payload?.amount);
  const mode = payload?.mode;
  const expectedMode = env.secretKey.startsWith("sk_live_") ? "live" : "test";
  if (!checkoutId || !paymentId || !Number.isSafeInteger(amount) || amount < 200 || payload?.currency !== "ZAR" || mode !== expectedMode) {
    return NextResponse.json({ error: "Invalid payment details." }, { status: 422 });
  }

  try {
    const svc = createServiceClient();
    const existing = await checked(svc.from("yoco_webhook_events").select("processed").eq("id", eventId).maybeSingle());
    if (existing?.processed) return NextResponse.json({ ok: true, duplicate: true });
    const draft = await checked(svc.from("checkout_intents").select("payment_amount_cents,yoco_mode,payment_method").eq("yoco_checkout_id",checkoutId).maybeSingle());
    if (!draft) return NextResponse.json({error:"Checkout not yet linked. Retry later."},{status:503});
    if (draft.payment_amount_cents !== amount || draft.yoco_mode !== mode || draft.payment_method !== "yoco") return NextResponse.json({error:"Payment mismatch."},{status:422});
    if (eventType === "payment.succeeded") {
      const result = await svc.rpc("finalize_card_checkout", { p_checkout_id: checkoutId, p_payment_id: paymentId, p_amount: amount, p_mode: mode });
      if (result.error) throw result.error;
    } else {
      await checked(svc.from("checkout_intents").update({payment_status:"failed"}).eq("yoco_checkout_id",checkoutId).is("paid_at",null));
      return NextResponse.json({ok:true});
    }
    const order = await checked(svc.from("orders")
      .select("id,total_price,payment_status,paid_at,payment_amount_cents,yoco_checkout_id,yoco_mode,payment_method")
      .eq("yoco_checkout_id", checkoutId).maybeSingle());
    if (!order) throw new Error("Order finalization did not persist.");
    const trustedAmount = Number(order.payment_amount_cents ?? Math.round(Number(order.total_price) * 100));
    if (trustedAmount !== amount || order.yoco_mode !== mode || !["yoco", "card"].includes(order.payment_method)) {
      return NextResponse.json({ error: "Payment does not match this order." }, { status: 422 });
    }
    const inserted = await svc.from("yoco_webhook_events").upsert({
      id: eventId, type: eventType, payload: event, order_id: order.id,
      yoco_checkout_id: checkoutId, processed: false,
    }, { onConflict: "id", ignoreDuplicates: true });
    if (inserted.error) throw inserted.error;

    const now = new Date().toISOString();
    const success = eventType === "payment.succeeded";
    // Conditional writes protect a paid/refunded order from late failure events.
    if (success) {
      await checked(svc.from("orders").update({
        payment_status: "paid", paid_at: order.paid_at ?? now,
        yoco_payment_id: paymentId, updated_at: now,
      }).eq("id", order.id).neq("payment_status", "refunded"));
    } else {
      await checked(svc.from("orders").update({
        payment_status: "failed", yoco_payment_id: paymentId, updated_at: now,
      }).eq("id", order.id).is("paid_at", null).not("payment_status", "in", "(paid,refunded)"));
    }
    const current = await checked(svc.from("orders").select("payment_status").eq("id", order.id).single());
    if (!current) throw new Error("Order disappeared during payment processing.");
    if (current.payment_status !== "refunded") {
      const payment = {
        order_id: order.id, yoco_checkout_id: checkoutId, amount_cents: amount,
        currency: "ZAR", status: current.payment_status === "paid" ? "succeeded" : "failed",
        yoco_payment_id: paymentId, webhook_event_id: eventId, raw_payload: event, mode, updated_at: now,
      };
      if (success || current.payment_status === "paid") {
        await checked(svc.from("payments").upsert(payment, { onConflict: "order_id" }));
      } else {
        // Never downgrade a succeeded payment if another webhook arrived concurrently.
        await checked(svc.from("payments").update(payment).eq("order_id", order.id).neq("status", "succeeded"));
      }
    }
    await checked(svc.from("yoco_webhook_events").update({ processed: true, processed_at: now }).eq("id", eventId));
    return NextResponse.json({ ok: true, id: eventId, orderId: order.id });
  } catch (error) {
    console.error("Yoco event processing failed", error);
    return NextResponse.json({ error: "Processing failed. Retry later." }, { status: 503 });
  }
}

export async function GET() {
  return NextResponse.json({ ok: true, message: "Yoco webhook endpoint. Send signed events using POST." });
}
