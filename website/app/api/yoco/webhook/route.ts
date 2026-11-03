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

type EventResult = { status?: string; order_id?: string | null } | null;

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
  const expectedMode = env.secretKey.startsWith("sk_live_") ? "live" : "test";
  if (eventType === "refund.succeeded") return recordRefund(event, eventId, expectedMode);
  if (!["payment.succeeded", "payment.failed"].includes(eventType)) {
    // refund.failed changes nothing: the payment stays as it was.
    return NextResponse.json({ ok: true, ignored: eventType });
  }
  const payload = event.payload as Record<string, unknown> | undefined;
  const metadata = payload?.metadata as Record<string, unknown> | undefined;
  // payload.id is a PAYMENT ID; metadata.checkoutId identifies our checkout.
  const checkoutId = String(metadata?.checkoutId ?? "");
  const paymentId = String(payload?.id ?? "");
  const amount = Number(payload?.amount);
  const mode = payload?.mode;
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
    if (eventType === "payment.failed") {
      await checked(svc.from("checkout_intents").update({ payment_status: "failed" })
        .eq("yoco_checkout_id", checkoutId).is("paid_at", null)
        .not("payment_status", "in", "(paid,refunded)"));
      // Draft failures have no order row. Keep their verified audit record
      // without inventing an unpaid kitchen order or storing card details.
      await checked(svc.from("yoco_webhook_events").upsert({
        id: eventId, type: eventType,
        payload: { id: eventId, type: eventType, payload: { id: paymentId, amount, currency: "ZAR", mode, metadata: { checkoutId } } },
        yoco_checkout_id: checkoutId, processed: true, processed_at: new Date().toISOString(), outcome: "processed",
      }, { onConflict: "id", ignoreDuplicates: true }));
      return NextResponse.json({ ok: true });
    }
    // One database transaction creates the paid order, saves the payment and
    // marks the event processed, so "processed" is never set on a partial write.
    const result = await checked<EventResult>(svc.rpc("record_card_payment_event", {
      p_event_id: eventId, p_checkout_id: checkoutId, p_payment_id: paymentId, p_amount: amount, p_mode: mode,
    }));
    if (result?.status === "duplicate") return NextResponse.json({ ok: true, duplicate: true });
    return NextResponse.json({ ok: true, id: eventId, orderId: result?.order_id ?? null });
  } catch (error) {
    console.error("Payment event processing failed", { eventId, type: error instanceof Error ? error.name : "database" });
    return NextResponse.json({ error: "Processing failed. Retry later." }, { status: 503 });
  }
}

// Refund events (Yoco Checkout API): payload.id is the REFUND ID, payload.amount
// is the refunded amount in cents, and metadata.checkoutId links our checkout.
async function recordRefund(event: Record<string, unknown>, eventId: string, expectedMode: string) {
  const payload = event.payload as Record<string, unknown> | undefined;
  const metadata = payload?.metadata as Record<string, unknown> | undefined;
  const refundId = String(payload?.id ?? "");
  const amount = Number(payload?.amount);
  const checkoutId = typeof metadata?.checkoutId === "string" ? metadata.checkoutId : "";
  if (!refundId || !Number.isSafeInteger(amount) || amount <= 0 || payload?.currency !== "ZAR"
      || payload?.mode !== expectedMode || (payload?.status !== undefined && payload.status !== "succeeded")) {
    return NextResponse.json({ error: "Invalid refund details." }, { status: 422 });
  }
  try {
    const result = await checked<EventResult>(createServiceClient().rpc("record_card_refund", {
      p_event_id: eventId, p_checkout_id: checkoutId || null, p_refund_id: refundId,
      p_amount: amount, p_currency: "ZAR", p_mode: payload.mode,
    }));
    const status = result?.status ?? "processed";
    // A retry cannot fix an unmatched or oversized refund. It is saved for
    // manual review and acknowledged so Yoco stops resending it.
    if (status === "unmatched" || status === "rejected") {
      console.warn("Card refund needs manual review", { eventId, status });
    }
    return NextResponse.json({ ok: true, refund: status, ...(status === "duplicate" ? { duplicate: true } : {}) });
  } catch (error) {
    console.error("Refund event processing failed", { eventId, type: error instanceof Error ? error.name : "database" });
    return NextResponse.json({ error: "Processing failed. Retry later." }, { status: 503 });
  }
}

export async function GET() {
  return NextResponse.json({ ok: true, message: "Yoco webhook endpoint. Send signed events using POST." });
}
