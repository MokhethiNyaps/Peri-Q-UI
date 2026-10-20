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
      await checked(svc.from("checkout_intents").update({ payment_status: "failed" })
        .eq("yoco_checkout_id", checkoutId).is("paid_at", null)
        .not("payment_status", "in", "(paid,refunded)"));
      // Draft failures have no order row. Keep their verified audit record
      // without inventing an unpaid kitchen order or storing card details.
      await checked(svc.from("yoco_webhook_events").upsert({
        id: eventId, type: eventType,
        payload: { id: eventId, type: eventType, payload: { id: paymentId, amount, currency: "ZAR", mode, metadata: { checkoutId } } },
        yoco_checkout_id: checkoutId, processed: true, processed_at: new Date().toISOString(),
      }, { onConflict: "id", ignoreDuplicates: true }));
      return NextResponse.json({ ok: true });
    }
    const order = await checked(svc.from("orders")
      .select("id,total_price,payment_status,paid_at,payment_amount_cents,yoco_checkout_id,yoco_mode,payment_method")
      .eq("yoco_checkout_id", checkoutId).maybeSingle());
    if (!order || !["paid", "refunded"].includes(order.payment_status)) throw new Error("Order finalization did not persist a confirmed payment.");
    const trustedAmount = Number(order.payment_amount_cents ?? Math.round(Number(order.total_price) * 100));
    if (trustedAmount !== amount || order.yoco_mode !== mode || !["yoco", "card"].includes(order.payment_method)) {
      return NextResponse.json({ error: "Payment does not match this order." }, { status: 422 });
    }
    const inserted = await svc.from("yoco_webhook_events").upsert({
      id: eventId, type: eventType, payload: { id: eventId, type: eventType, payload: { id: paymentId, amount, currency: "ZAR", mode, metadata: { checkoutId } } }, order_id: order.id,
      yoco_checkout_id: checkoutId, processed: false,
    }, { onConflict: "id", ignoreDuplicates: true });
    if (inserted.error) throw inserted.error;

    const now = new Date().toISOString();
    // finalize_card_checkout is the only writer that creates a paid order.
    // Its row lock and transaction protect duplicate/concurrent deliveries.
    if (order.payment_status !== "refunded") {
      await checked(svc.from("payments").upsert({
        order_id: order.id, yoco_checkout_id: checkoutId, amount_cents: amount,
        currency: "ZAR", status: "succeeded", yoco_payment_id: paymentId,
        webhook_event_id: eventId, mode, updated_at: now,
      }, { onConflict: "order_id" }));
    }
    await checked(svc.from("yoco_webhook_events").update({ processed: true, processed_at: now }).eq("id", eventId));
    return NextResponse.json({ ok: true, id: eventId, orderId: order.id });
  } catch (error) {
    console.error("Payment event processing failed", { eventId, type: error instanceof Error ? error.name : "database" });
    return NextResponse.json({ error: "Processing failed. Retry later." }, { status: 503 });
  }
}

export async function GET() {
  return NextResponse.json({ ok: true, message: "Yoco webhook endpoint. Send signed events using POST." });
}

