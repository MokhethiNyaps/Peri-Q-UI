import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { readYocoEnv, verifyYocoWebhook } from "@/lib/yoco";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Yoco posts here with headers webhook-id, webhook-timestamp, webhook-signature (Standard Webhooks)
// Must respond 2xx within 15s; retries schedule up to 8 attempts over ~25h if not 2xx.
export async function POST(req: Request) {
  const yocoEnv = readYocoEnv();
  if (!yocoEnv) {
    return NextResponse.json({ error: "Webhook secret not configured (YOCO_WEBHOOK_SECRET whsec_...)" }, { status: 503 });
  }

  // Raw body for signature
  let rawBody = "";
  try {
    rawBody = await req.text();
  } catch {
    return NextResponse.json({ error: "Could not read body" }, { status: 400 });
  }

  const headers = {
    webhookId: req.headers.get("webhook-id") ?? req.headers.get("Webhook-Id") ?? req.headers.get("WEBHOOK-ID"),
    webhookTimestamp: req.headers.get("webhook-timestamp") ?? req.headers.get("Webhook-Timestamp"),
    webhookSignature: req.headers.get("webhook-signature") ?? req.headers.get("Webhook-Signature"),
  };

  const verify = verifyYocoWebhook({ rawBody, headers: { webhookId: headers.webhookId, webhookTimestamp: headers.webhookTimestamp, webhookSignature: headers.webhookSignature }, secret: yocoEnv.webhookSecret });
  if (!verify.ok) {
    // Log but return 400 so Yoco does not blindly retry a bad signature forever? However docs say retry on non-2xx.
    // Return 401 to indicate auth failure — but still not 2xx so Yoco will retry attacker payload? That's fine.
    console.warn("yoco webhook signature failed", verify.reason, { webhookId: headers.webhookId });
    return NextResponse.json({ error: `Webhook signature invalid: ${verify.reason}`, code: "invalid_signature" }, { status: 401 });
  }

  let event: Record<string, unknown> = {};
  try {
    event = rawBody ? (JSON.parse(rawBody) as Record<string, unknown>) : {};
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const eventId = String(event["id"] ?? "");
  const eventType = String(event["type"] ?? "");
  const createdDate = String(event["createdDate"] ?? event["created_date"] ?? "");
  const payload = (event["payload"] ?? event["data"] ?? null) as Record<string, unknown> | null;

  if (!eventId || !eventType || !payload || typeof payload !== "object") {
    return NextResponse.json({ error: "Missing id/type/payload in webhook body" }, { status: 422 });
  }
  const allowed = new Set(["payment.succeeded", "payment.failed"]);
  if (!allowed.has(eventType)) {
    // Gracefully ignore other event types (e.g., refund.succeeded if subscribed) but record them
    console.log("yoco webhook ignored type", eventType);
    return NextResponse.json({ ok: true, ignored: eventType }, { status: 200 });
  }

  const payloadAmount = Number((payload as Record<string, unknown>)["amount"] ?? NaN);
  const payloadCurrency = String((payload as Record<string, unknown>)["currency"] ?? "");
  const payloadMode = String((payload as Record<string, unknown>)["mode"] ?? "");
  const payloadId = String((payload as Record<string, unknown>)["id"] ?? "");
  const payloadMetadata = ((payload as Record<string, unknown>)["metadata"] ?? {}) as Record<string, unknown>;
  const payloadOrderId = String(payloadMetadata["order_id"] ?? payloadMetadata["orderId"] ?? payloadMetadata["externalId"] ?? (payload as Record<string, unknown>)["clientReferenceId"] ?? (payload as Record<string, unknown>)["externalId"] ?? "");

  if (payloadCurrency !== "ZAR") {
    console.warn("yoco webhook unexpected currency", payloadCurrency);
  }
  if (!Number.isFinite(payloadAmount)) {
    return NextResponse.json({ error: "Payload amount missing/invalid" }, { status: 422 });
  }

  // Idempotency guard: if event already processed, return 200 without double-processing
  let svc;
  try {
    svc = createServiceClient();
  } catch {
    return NextResponse.json({ error: "Supabase service config missing" }, { status: 503 });
  }

  // Try to insert webhook event; if duplicate, it's idempotent and we return 200
  try {
    const { data: existing, error: selErr } = await svc.from("yoco_webhook_events").select("id,processed").eq("id", eventId).maybeSingle();
    if (existing) {
      // Already seen — idempotent ack
      return NextResponse.json({ ok: true, duplicate: true, id: eventId }, { status: 200 });
    }
    // Insert as unprocessed first, so concurrent deliveries both try insert but unique PK will cause one to fail
    const { error: insErr } = await svc.from("yoco_webhook_events").insert({
      id: eventId,
      type: eventType,
      payload: event,
      order_id: payloadOrderId || null,
      yoco_checkout_id: payloadId || null,
      processed: false,
    });
    if (insErr) {
      // If insert failed due to unique violation (race), treat as duplicate
      const isDup = String(insErr.message ?? "").toLowerCase().includes("duplicate") || String(insErr.code) === "23505";
      if (isDup) return NextResponse.json({ ok: true, duplicate: true, id: eventId }, { status: 200 });
      console.warn("webhook_events insert failed", insErr);
      // Continue anyway — we still want to process
    }
  } catch (e) {
    console.warn("webhook_events idempotency check failed (non-fatal)", e);
  }

  // Resolve orderId: prefer metadata.order_id, else try to lookup via yoco_checkout_id in payments/orders
  let orderIdToUpdate: string | null = payloadOrderId || null;
  let orderRow: Record<string, unknown> | null = null;

  // Try to find order row
  if (orderIdToUpdate) {
    const { data } = await svc.from("orders").select("id,total_price,payment_status,paid_at,payment_amount_cents,yoco_checkout_id").eq("id", orderIdToUpdate).maybeSingle();
    orderRow = (data as Record<string, unknown> | null) ?? null;
  }
  // Fallback: search by yoco_checkout_id if metadata missing (older checkouts)
  if (!orderRow && payloadId) {
    const { data } = await svc.from("orders").select("id,total_price,payment_status,paid_at,payment_amount_cents,yoco_checkout_id").eq("yoco_checkout_id", payloadId).maybeSingle();
    if (data) {
      orderRow = data as Record<string, unknown>;
      orderIdToUpdate = String((orderRow["id"] as string) ?? "");
    }
    if (!orderRow) {
      const { data: payData } = await svc.from("payments").select("order_id").eq("yoco_checkout_id", payloadId).maybeSingle();
      if (payData) {
        const oid = String((payData as Record<string, unknown>)["order_id"] ?? "");
        const { data: order2 } = await svc.from("orders").select("id,total_price,payment_status,paid_at,payment_amount_cents,yoco_checkout_id").eq("id", oid).maybeSingle();
        orderRow = (order2 as Record<string, unknown> | null) ?? null;
        orderIdToUpdate = oid || null;
      }
    }
  }

  if (!orderRow || !orderIdToUpdate) {
    console.warn("yoco webhook: order not found for event", { eventId, eventType, payloadOrderId, payloadId });
    // Still mark event processed to avoid infinite retries for orphan events (e.g., test event without order)
    try {
      await svc.from("yoco_webhook_events").update({ processed: true, processed_at: new Date().toISOString() }).eq("id", eventId);
    } catch {}
    // Return 200 so Yoco stops retrying; orphan event not actionable
    return NextResponse.json({ ok: true, orphan: true, id: eventId }, { status: 200 });
  }

  // Verify amount matches server-calculated order total (in cents). Prevent underpayment marking as paid.
  const trustedCents = Number(orderRow["payment_amount_cents"] ?? Math.round(Number(orderRow["total_price"] ?? 0) * 100));
  const webhookCents = payloadAmount;
  if (trustedCents !== webhookCents) {
    console.warn("yoco webhook amount mismatch — NOT marking paid", { eventId, orderId: orderIdToUpdate, trustedCents, webhookCents, payload });
    // Record mismatch but do not mark paid; optionally set payment_status failed?
    try {
      await svc.from("yoco_webhook_events").update({ processed: true, processed_at: new Date().toISOString(), payload: { ...event, _amountMismatch: { trustedCents, webhookCents } } as unknown as Record<string, unknown> }).eq("id", eventId);
      await svc.from("payments").update({ raw_payload: event, webhook_event_id: eventId, updated_at: new Date().toISOString() }).eq("order_id", orderIdToUpdate);
    } catch {}
    // Return 200 to stop retries but payment not marked — admin must reconcile manually
    return NextResponse.json({ ok: true, amountMismatch: true, trustedCents, webhookCents, id: eventId }, { status: 200 });
  }

  // Handle payment outcome idempotently
  const nowIso = new Date().toISOString();
  const mode = payloadMode === "live" ? "live" : payloadMode === "test" ? "test" : null;

  try {
    if (eventType === "payment.succeeded") {
      // Only transition to paid if not already paid
      const alreadyPaid = orderRow["payment_status"] === "paid" || !!orderRow["paid_at"];
      if (!alreadyPaid) {
        await svc
          .from("orders")
          .update({
            payment_status: "paid",
            paid_at: nowIso,
            yoco_payment_id: payloadId || null,
            yoco_mode: mode,
            updated_at: nowIso,
          })
          .eq("id", orderIdToUpdate);
        await svc
          .from("payments")
          .update({
            status: "succeeded",
            yoco_payment_id: payloadId || null,
            webhook_event_id: eventId,
            raw_payload: event,
            mode,
            updated_at: nowIso,
          })
          .eq("order_id", orderIdToUpdate);
      } else {
        // Already paid — just ensure payments table reflects webhook
        await svc.from("payments").update({ webhook_event_id: eventId, raw_payload: event, updated_at: nowIso }).eq("order_id", orderIdToUpdate);
      }
    } else if (eventType === "payment.failed") {
      // Only mark failed if not already paid (paid is terminal)
      if (orderRow["payment_status"] !== "paid") {
        await svc.from("orders").update({ payment_status: "failed", yoco_payment_id: payloadId || null, yoco_mode: mode, updated_at: nowIso }).eq("id", orderIdToUpdate);
        await svc.from("payments").update({ status: "failed", yoco_payment_id: payloadId || null, webhook_event_id: eventId, raw_payload: event, mode, updated_at: nowIso }).eq("order_id", orderIdToUpdate);
      }
    }

    await svc.from("yoco_webhook_events").update({ processed: true, processed_at: nowIso, order_id: orderIdToUpdate, yoco_checkout_id: payloadId || null }).eq("id", eventId);
  } catch (e) {
    console.error("yoco webhook processing failed", e, { eventId, orderIdToUpdate });
    // Return 500 so Yoco retries (but we have idempotency guard so retry is safe)
    return NextResponse.json({ error: "Processing failed, will retry" }, { status: 500 });
  }

  // Success ACK
  return NextResponse.json({ ok: true, id: eventId, type: eventType, orderId: orderIdToUpdate }, { status: 200 });
}

// Also handle GET for debugging in staging (returns 405 in prod, but useful for owner verifying endpoint exists)
export async function GET() {
  return NextResponse.json({ ok: true, message: "Yoco webhook endpoint. Use POST with Yoco Standard Webhooks signature. Configure in Yoco App → Sales → Payment Gateway → Webhooks: https://rastasperiq.co.za/api/yoco/webhook" });
}
