import { beforeEach, describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen } from "@testing-library/react";
import { exportMyData, submitPrivacyRequest } from "../lib/customer-account";
import { POLICY_VERSION, recordCheckoutAcceptance } from "../lib/policy-consent";
import { PolicyConsent } from "../components/policy-consent";

const db = vi.hoisted(() => ({
  calls: [] as { table: string; method: string; args: unknown[] }[],
  rows: {} as Record<string, unknown[]>,
  rpcError: null as { message: string } | null,
}));
vi.mock("../lib/supabase", () => ({
  createBrowserClient: () => ({
    rpc: async (name: string, args: unknown) => { db.calls.push({ table: name, method: "rpc", args: [args] }); return { data: "id-1", error: db.rpcError }; },
    from: (table: string) => {
      const chain: Record<string, unknown> = {};
      for (const method of ["select", "in", "eq", "order", "limit"]) {
        chain[method] = (...args: unknown[]) => { db.calls.push({ table, method, args }); return chain; };
      }
      chain.then = (resolve: (value: unknown) => unknown) => Promise.resolve({ data: db.rows[table] ?? [], error: null }).then(resolve);
      return chain;
    },
  }),
}));
beforeEach(() => { db.calls = []; db.rows = {}; db.rpcError = null; });

describe("Policy acceptance", () => {
  it("records the checkout acceptance against the checkout draft", async () => {
    await recordCheckoutAcceptance("draft-1");
    expect(db.calls).toEqual([{ table: "record_policy_acceptance", method: "rpc", args: [{ p_version: POLICY_VERSION, p_context: "checkout", p_client: "website", p_checkout_id: "draft-1" }] }]);
  });
  it("stops checkout when the acceptance cannot be recorded", async () => {
    db.rpcError = { message: "network" };
    await expect(recordCheckoutAcceptance("draft-1")).rejects.toThrow("Could not record your acceptance");
  });
  it("links to the terms and privacy policy and reports changes", async () => {
    const onChange = vi.fn();
    render(<PolicyConsent checked={false} onChange={onChange} error="Accept the terms and conditions to continue." />);
    // Next.js may drop the trailing slash when rendering links in tests.
    expect(screen.getByRole("link", { name: "terms and conditions" }).getAttribute("href")).toMatch(/^\/terms-and-conditions\/?$/);
    expect(screen.getByRole("link", { name: "privacy policy" }).getAttribute("href")).toMatch(/^\/privacy-policy\/?$/);
    expect(screen.getByRole("alert")).toHaveTextContent("Accept the terms");
    fireEvent.click(screen.getByRole("checkbox"));
    expect(onChange).toHaveBeenCalledWith(true);
  });
});

describe("Privacy rights", () => {
  it("exports only the signed-in customer's own rows, even for an admin", async () => {
    db.rows.orders = [{ id: "order-a" }];
    const data = await exportMyData("user-a");
    const filters = db.calls.filter((call) => call.method === "in").map((call) => [call.table, ...call.args]);
    expect(filters).toEqual(expect.arrayContaining([
      ["profiles", "id", ["user-a"]], ["orders", "user_id", ["user-a"]],
      ["policy_acceptances", "user_id", ["user-a"]], ["privacy_requests", "user_id", ["user-a"]],
      ["payments", "order_id", ["order-a"]], ["payment_refunds", "order_id", ["order-a"]],
    ]));
    expect(db.calls.some((call) => ["payments", "payment_refunds"].includes(call.table) && call.method === "select" && !filters.some((f) => f[0] === call.table))).toBe(false);
    expect(data.orders).toEqual([{ id: "order-a" }]);
  });
  it("does not read payment rows when the customer has no orders", async () => {
    await exportMyData("user-a");
    expect(db.calls.some((call) => call.table === "payments")).toBe(false);
  });
  it("validates privacy requests before sending them", async () => {
    await expect(submitPrivacyRequest("access", "   ")).rejects.toThrow("Tell us what you need");
    await expect(submitPrivacyRequest("access", "x".repeat(2001))).rejects.toThrow("under 2,000");
    await submitPrivacyRequest("correction", "  My phone number is wrong.  ");
    expect(db.calls.at(-1)).toEqual({ table: "submit_privacy_request", method: "rpc", args: [{ p_request_type: "correction", p_details: "My phone number is wrong." }] });
  });
  it("explains the open-request limit", async () => {
    db.rpcError = { message: "You already have three open privacy requests." };
    await expect(submitPrivacyRequest("other", "Another one")).rejects.toThrow("We will reply to those first");
  });
});
