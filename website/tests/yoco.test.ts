// @vitest-environment node
import { describe, it, expect, beforeEach, vi } from "vitest";
import crypto from "node:crypto";
import { verifyYocoWebhook } from "../lib/yoco";
import { POST as webhook } from "../app/api/yoco/webhook/route";
import { POST as checkout, GET as paymentReadiness } from "../app/api/yoco/checkout/route";

const db = vi.hoisted(() => ({ results: [] as { data: unknown; error: unknown }[], calls: [] as { table: string; method: string; args: unknown[] }[], userId: "user-a" }));
vi.mock("@/lib/supabase", () => ({
  readServerSupabaseConfig: () => ({ url: "https://example.supabase.co", serviceRoleKey: "test" }),
  createServiceClient: () => ({
    auth: { getUser: async () => ({ data: { user: { id: db.userId } }, error: null }) },
    rpc: async (name:string,args:unknown) => {db.calls.push({table:name,method:"rpc",args:[args]});return {data:"order-1",error:null};},
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
function signedRequest(value = event, timestamp = String(Math.floor(Date.now() / 1000))) {
  const rawBody = JSON.stringify(value);
  const signature = crypto.createHmac("sha256", Buffer.from(secret.slice(6), "base64")).update(`delivery-1.${timestamp}.${rawBody}`).digest("base64");
  return new Request("https://example.com/api/yoco/webhook", { method: "POST", body: rawBody, headers: { "webhook-id": "delivery-1", "webhook-timestamp": timestamp, "webhook-signature": `v1,${signature}` } });
}
beforeEach(() => {
  db.results = []; db.calls = []; db.userId = "user-a";
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
  it("matches the checkout ID, saves payment, then acknowledges", async () => {
    db.results = [ok(), ok(order), ok(order), ok(), ok(), ok({ payment_status: "paid" }), ok(), ok()];
    expect((await webhook(signedRequest())).status).toBe(200);
    expect(db.calls).toContainEqual({ table: "orders", method: "eq", args: ["yoco_checkout_id", "ch-1"] });
    expect(db.calls.some(c => c.table === "yoco_webhook_events" && c.method === "update" && (c.args[0] as { processed?: boolean }).processed)).toBe(true);
  });
  it("retries an unprocessed event when a database write fails", async () => {
    db.results = [ok({ processed: false }), ok(order), ok(), { data: null, error: { message: "temporary failure" } }];
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
