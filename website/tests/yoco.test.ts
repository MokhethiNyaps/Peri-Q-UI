// @vitest-environment node
import { describe, it, expect, beforeEach, vi } from "vitest";
import crypto from "node:crypto";
import { verifyYocoWebhook } from "../lib/yoco";
import { POST as webhook } from "../app/api/yoco/webhook/route";
import { POST as checkout, GET as paymentReadiness } from "../app/api/yoco/checkout/route";

type Result = { data: unknown; error: unknown };
const db = vi.hoisted(() => ({ results: [] as { data: unknown; error: unknown }[], rpcResults: {} as Record<string, { data: unknown; error: unknown }[]>, calls: [] as { table: string; method: string; args: unknown[] }[], userId: "user-a" }));
vi.mock("@/lib/supabase", () => ({
  readServerSupabaseConfig: () => ({ url: "https://example.supabase.co", serviceRoleKey: "test" }),
  createServiceClient: () => ({
    auth: { getUser: async () => { db.calls.push({ table: "auth", method: "getUser", args: [] }); return { data: { user: { id: db.userId } }, error: null }; } },
    rpc: async (name:string,args:unknown) => {
      db.calls.push({table:name,method:"rpc",args:[args]});
      const queued = db.rpcResults[name]?.shift();
      if (queued) return queued;
      return name === "consume_rate_limit" ? { data: true, error: null } : { data: { status: "processed", order_id: "order-1" }, error: null };
    },
    from: (table: string) => {
      const chain: Record<string, unknown> = {};
      for (const method of ["select", "eq", "maybeSingle", "single", "update", "upsert", "is", "not", "neq", "limit"]) {
        chain[method] = (...args: unknown[]) => { db.calls.push({ table, method, args }); return chain; };
      }
      chain.then = (resolve: (result: unknown) => unknown) => Promise.resolve(db.results.shift() ?? { data: null, error: null }).then(resolve);
      return chain;
    },
  }),
}));
const secret = `whsec_${Buffer.from("test-secret-for-verification").toString("base64")}`;
const event = { id: "evt-1", type: "payment.succeeded", payload: { id: "pay-1", amount: 12500, currency: "ZAR", mode: "test", metadata: { checkoutId: "ch-1" } } };
const order = { id: "order-1", user_id: "user-a", payment_method: "yoco", payment_status: "pending", total_price: 125, payment_amount_cents: 12500, yoco_mode: "test", yoco_checkout_id: "ch-1", paid_at: null };
const ok = (data: unknown = null) => ({ data, error: null });
function signedRequest(value: object = event, timestamp = String(Math.floor(Date.now() / 1000))) {
  const rawBody = JSON.stringify(value);
  const signature = crypto.createHmac("sha256", Buffer.from(secret.slice(6), "base64")).update(`delivery-1.${timestamp}.${rawBody}`).digest("base64");
  return new Request("https://example.com/api/yoco/webhook", { method: "POST", body: rawBody, headers: { "webhook-id": "delivery-1", "webhook-timestamp": timestamp, "webhook-signature": `v1,${signature}` } });
}
beforeEach(() => {
  vi.unstubAllGlobals();
  db.results = []; db.rpcResults = {}; db.calls = []; db.userId = "user-a";
  vi.stubEnv("YOCO_SECRET_KEY", "sk_test_example"); vi.stubEnv("YOCO_WEBHOOK_SECRET", secret);
});

describe("Production webhook verification", () => {
  it("accepts a valid signature and rejects tampering", async () => {
    const req = signedRequest(); const rawBody = await req.text();
    const headers = { webhookId: req.headers.get("webhook-id"), webhookTimestamp: req.headers.get("webhook-timestamp"), webhookSignature: req.headers.get("webhook-signature") };
    expect(verifyYocoWebhook({ rawBody, headers, secret }).ok).toBe(true);
    expect(verifyYocoWebhook({ rawBody: rawBody + " ", headers, secret }).ok).toBe(false);
    expect(verifyYocoWebhook({ rawBody, headers: { ...headers, webhookSignature: headers.webhookSignature!.replace("v1,", "v2,") }, secret }).ok).toBe(false);
  });
  it("rejects a correctly signed stale event before database access", async () => {
    expect((await webhook(signedRequest(event, String(Math.floor(Date.now() / 1000) - 600)))).status).toBe(401);
    expect(db.calls).toHaveLength(0);
  });
  it("matches the checkout ID and records the payment in one database transaction", async () => {
    db.results = [ok(), ok(order)];
    const response = await webhook(signedRequest());
    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({ ok: true, orderId: "order-1" });
    expect(db.calls).toContainEqual({ table: "checkout_intents", method: "eq", args: ["yoco_checkout_id", "ch-1"] });
    expect(db.calls).toContainEqual({ table: "record_card_payment_event", method: "rpc", args: [{ p_event_id: "evt-1", p_checkout_id: "ch-1", p_payment_id: "pay-1", p_amount: 12500, p_mode: "test" }] });
    // The route itself never flips "processed"; only the transaction does.
    expect(db.calls.some(c => c.method === "update" || c.method === "upsert")).toBe(false);
  });
  it("retries an unprocessed event when the database transaction fails", async () => {
    db.results = [ok({ processed: false }), ok(order)];
    db.rpcResults.record_card_payment_event = [{ data: null, error: { message: "temporary failure" } }];
    expect((await webhook(signedRequest())).status).toBe(503);
    expect(db.calls.some(c => c.method === "update" && (c.args[0] as { processed?: boolean }).processed)).toBe(false);
  });
  it("acknowledges only fully processed duplicates", async () => {
    db.results = [ok({ processed: true })];
    expect(await (await webhook(signedRequest())).json()).toMatchObject({ duplicate: true });
    expect(db.calls.filter(c => c.method === "update")).toHaveLength(0);
  });
  it("retries when checkout linkage is not yet saved", async () => {
    db.results = [ok(), ok()];
    expect((await webhook(signedRequest())).status).toBe(503);
  });
  it("rejects wrong amount, currency, and mode", async () => {
    for (const overrides of [{ currency: "USD" }, { mode: "live" }, { amount: 12499 }]) {
      db.results = [ok(), ok(order)]; db.calls = [];
      expect((await webhook(signedRequest({ ...event, payload: { ...event.payload, ...overrides } }))).status).toBe(422);
      expect(db.calls.filter(c => c.method === "update")).toHaveLength(0);
    }
  });
  it("does not downgrade paid orders on a late failure", async () => {
    db.results = [ok(), ok({ ...order, payment_status: "paid", paid_at: "2026-10-12" }), ok(), ok(), ok({ payment_status: "paid" }), ok(), ok()];
    expect((await webhook(signedRequest({ ...event, type: "payment.failed" }))).status).toBe(200);
    expect(db.calls).toContainEqual({table:"checkout_intents",method:"is",args:["paid_at",null]});
    expect(db.calls.some(c=>c.table==="orders" && c.method==="update")).toBe(false);
  });
});

describe("Checkout ownership", () => {
  it("keeps card payments unavailable without Yoco credentials", async () => {
    vi.stubEnv("YOCO_SECRET_KEY", "");
    expect(await (await paymentReadiness()).json()).toEqual({ available: false });
    expect(db.calls).toHaveLength(0);
  });
  it("enables payments only when the payment schema is accessible", async () => {
    db.results = [ok([]), ok([])];
    expect(await (await paymentReadiness()).json()).toEqual({ available: true, mode: "test" });
    db.results = [ok([]), { data: null, error: { message: "missing table" } }];
    expect(await (await paymentReadiness()).json()).toEqual({ available: false });
  });
  it("requires a session token", async () => {
    const req = new Request("https://example.com/api/yoco/checkout", { method: "POST", body: JSON.stringify({ orderId: "order-1" }) });
    expect((await checkout(req)).status).toBe(401);
  });
  it("refuses another user's order before contacting Yoco", async () => {
    db.results = [ok({ ...order, user_id: "user-b" })];
    const req = new Request("https://example.com/api/yoco/checkout", { method: "POST", body: JSON.stringify({ orderId: "order-1" }), headers: { Authorization: "Bearer test-token" } });
    expect((await checkout(req)).status).toBe(404);
    expect(db.calls.filter(c => c.method === "update")).toHaveLength(0);
  });
});



describe("Safe checkout initiation and retries", () => {
  const request = () => new Request("https://example.com/api/yoco/checkout", {
    method: "POST", body: JSON.stringify({ orderId: "order-1", source: "mobile" }),
    headers: { Authorization: "Bearer test-token" },
  });
  const draft = () => ({ ...order, created_at: new Date().toISOString(), client_request_id: "request-1" });
  it("rejects paid checkouts before returning a previously saved payment link", async () => {
    db.results = [ok({ ...draft(), payment_status: "paid", redirect_url: "https://c.yoco.com/old" })];
    expect(await (await checkout(request())).json()).toMatchObject({ code: "already_paid" });
  });
  it("uses the trusted amount, stable idempotency key and mobile metadata", async () => {
    db.results = [ok(draft()), ok()];
    const fetchMock = vi.fn().mockResolvedValue(new Response(JSON.stringify({ id: "ch-1", redirectUrl: "https://c.yoco.com/checkout/one", processingMode: "test" })));
    vi.stubGlobal("fetch", fetchMock);
    expect((await checkout(request())).status).toBe(200);
    const options = fetchMock.mock.calls[0][1];
    expect(JSON.parse(options.body)).toMatchObject({ amount: 12500, currency: "ZAR", metadata: { source: "mobile" } });
    expect(options.headers["Idempotency-Key"]).toBe("request-1");
  });
  it("does not recreate an uncertain checkout beyond the provider idempotency window", async () => {
    db.results = [ok({ ...draft(), created_at: new Date(Date.now() - 25 * 3600_000).toISOString() })];
    const fetchMock = vi.fn(); vi.stubGlobal("fetch", fetchMock);
    expect(await (await checkout(request())).json()).toMatchObject({ code: "checkout_expired" });
    expect(fetchMock).not.toHaveBeenCalled();
  });
  it("does not expose provider responses or configuration details to customers", async () => {
    db.results = [ok(draft())];
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(JSON.stringify({ description: "sensitive-upstream-detail" }), { status: 403 })));
    const response = await checkout(request());
    expect(response.status).toBe(502);
    const body = await response.text();
    expect(body).not.toContain("sensitive-upstream-detail");
    expect(body).not.toContain("YOCO_SECRET_KEY");
    expect(body).not.toContain("Yoco");
  });
  it("audits verified failed payments without creating kitchen orders", async () => {
    db.results = [ok(), ok(order), ok(), ok()];
    expect((await webhook(signedRequest({ ...event, type: "payment.failed" }))).status).toBe(200);
    expect(db.calls.some(c => c.table === "yoco_webhook_events" && c.method === "upsert")).toBe(true);
    expect(db.calls.some(c => c.method === "rpc")).toBe(false);
  });
});

describe("Webhook signatures, replays and duplicates", () => {
  const rpcCalls = (name: string) => db.calls.filter(c => c.table === name && c.method === "rpc");
  it("rejects an invalid signature before database access", async () => {
    const req = signedRequest();
    const forged = new Request(req.url, { method: "POST", body: await req.text(), headers: { ...Object.fromEntries(req.headers), "webhook-signature": `v1,${Buffer.from("forged-signature-value-0000000000").toString("base64")}` } });
    expect((await webhook(forged)).status).toBe(401);
    expect(db.calls).toHaveLength(0);
  });
  it("rejects events signed with another secret", async () => {
    vi.stubEnv("YOCO_WEBHOOK_SECRET", `whsec_${Buffer.from("a-different-secret").toString("base64")}`);
    expect((await webhook(signedRequest())).status).toBe(401);
    expect(db.calls).toHaveLength(0);
  });
  it("rejects a replayed delivery whose body was changed", async () => {
    const req = signedRequest();
    const tampered = new Request(req.url, { method: "POST", body: JSON.stringify({ ...event, payload: { ...event.payload, amount: 1 } }), headers: Object.fromEntries(req.headers) });
    expect((await webhook(tampered)).status).toBe(401);
    expect(db.calls).toHaveLength(0);
  });
  it("acknowledges a replay of an already processed event without paying twice", async () => {
    db.results = [ok(), ok(order)];
    expect((await webhook(signedRequest())).status).toBe(200);
    db.results = [ok({ processed: true })];
    expect(await (await webhook(signedRequest())).json()).toMatchObject({ ok: true, duplicate: true });
    expect(rpcCalls("record_card_payment_event")).toHaveLength(1);
  });
  it("reports a concurrent duplicate that the database transaction caught", async () => {
    db.results = [ok(), ok(order)];
    db.rpcResults.record_card_payment_event = [ok({ status: "duplicate", order_id: "order-1" })];
    const response = await webhook(signedRequest());
    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({ duplicate: true });
  });
});

describe("Refund events", () => {
  const refund = { id: "evt-r1", type: "refund.succeeded", createdDate: "2026-11-03T10:00:00Z", payload: { id: "rfd-1", type: "refund", status: "succeeded", amount: 5000, currency: "ZAR", mode: "test", createdDate: "2026-11-03T10:00:00Z", refundableAmount: 7500, metadata: { checkoutId: "ch-1" } } };
  const refundCalls = () => db.calls.filter(c => c.table === "record_card_refund" && c.method === "rpc");
  it("records a refund against the paid order", async () => {
    const response = await webhook(signedRequest(refund));
    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({ ok: true, refund: "processed" });
    expect(refundCalls()).toEqual([{ table: "record_card_refund", method: "rpc", args: [{ p_event_id: "evt-r1", p_checkout_id: "ch-1", p_refund_id: "rfd-1", p_amount: 5000, p_currency: "ZAR", p_mode: "test" }] }]);
  });
  it("acknowledges a duplicate refund event without recording it twice", async () => {
    db.rpcResults.record_card_refund = [ok({ status: "duplicate", order_id: "order-1" })];
    expect(await (await webhook(signedRequest(refund))).json()).toMatchObject({ ok: true, duplicate: true });
  });
  it("keeps unmatched refunds for review and stops retries", async () => {
    db.rpcResults.record_card_refund = [ok({ status: "unmatched", order_id: null })];
    const unlinked = { ...refund, payload: { ...refund.payload, metadata: {} } };
    const response = await webhook(signedRequest(unlinked));
    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({ refund: "unmatched" });
    expect((refundCalls()[0].args[0] as { p_checkout_id: unknown }).p_checkout_id).toBeNull();
  });
  it("rejects malformed refunds before database access", async () => {
    for (const overrides of [{ currency: "USD" }, { mode: "live" }, { amount: 0 }, { amount: 12.5 }, { id: "" }, { status: "failed" }]) {
      db.calls = [];
      expect((await webhook(signedRequest({ ...refund, payload: { ...refund.payload, ...overrides } }))).status).toBe(422);
      expect(db.calls).toHaveLength(0);
    }
  });
  it("asks Yoco to retry when the refund cannot be saved", async () => {
    db.rpcResults.record_card_refund = [{ data: null, error: { message: "temporary failure" } }];
    expect((await webhook(signedRequest(refund))).status).toBe(503);
  });
  it("ignores failed refunds without changing the payment", async () => {
    const response = await webhook(signedRequest({ ...refund, type: "refund.failed", payload: { ...refund.payload, status: "failed" } }));
    expect(await response.json()).toMatchObject({ ok: true, ignored: "refund.failed" });
    expect(db.calls).toHaveLength(0);
  });
});

describe("Checkout rate limiting", () => {
  const request = (ip = "198.51.100.7") => new Request("https://example.com/api/yoco/checkout", {
    method: "POST", body: JSON.stringify({ orderId: "order-1" }),
    headers: { Authorization: "Bearer test-token", "x-real-ip": ip },
  });
  const limitCalls = () => db.calls.filter(c => c.table === "consume_rate_limit");
  it("limits by IP before checking the session, without storing the raw IP", async () => {
    db.rpcResults.consume_rate_limit = [ok(false)];
    const fetchMock = vi.fn(); vi.stubGlobal("fetch", fetchMock);
    const response = await checkout(request());
    expect(response.status).toBe(429);
    expect(response.headers.get("Retry-After")).toBe("600");
    expect(await response.json()).toMatchObject({ code: "rate_limited" });
    expect(db.calls.some(c => c.method === "getUser")).toBe(false);
    expect(fetchMock).not.toHaveBeenCalled();
    const bucket = (limitCalls()[0].args[0] as { p_bucket: string }).p_bucket;
    expect(bucket).toMatch(/^checkout:ip:[0-9a-f]{32}$/);
    expect(bucket).not.toContain("198.51.100.7");
  });
  it("limits each signed-in customer", async () => {
    db.rpcResults.consume_rate_limit = [ok(true), ok(false)];
    const fetchMock = vi.fn(); vi.stubGlobal("fetch", fetchMock);
    expect((await checkout(request())).status).toBe(429);
    expect((limitCalls()[1].args[0] as { p_bucket: string; p_limit: number }).p_bucket).toBe("checkout:user:user-a");
    expect(fetchMock).not.toHaveBeenCalled();
  });
  it("allows checkout when the limiter is unavailable", async () => {
    db.rpcResults.consume_rate_limit = [{ data: null, error: { message: "function missing" } } as Result, { data: null, error: { message: "function missing" } }];
    db.results = [ok({ ...order, created_at: new Date().toISOString(), client_request_id: "request-1" }), ok()];
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(JSON.stringify({ id: "ch-1", redirectUrl: "https://c.yoco.com/checkout/one", processingMode: "test" }))));
    expect((await checkout(request())).status).toBe(200);
  });
});
