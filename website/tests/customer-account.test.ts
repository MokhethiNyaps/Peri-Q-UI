import { beforeEach, describe, expect, it, vi } from "vitest";
import { completeAuthCallback, registerCustomer, saveCustomerProfile, signInCustomer, signOutCustomer } from "../lib/customer-account";
import { POLICY_VERSION } from "../lib/policy-consent";

const api = vi.hoisted(() => ({
  signUp: vi.fn(), signInWithPassword: vi.fn(), signOut: vi.fn(), getUser: vi.fn(),
  exchangeCodeForSession: vi.fn(), setSession: vi.fn(), upsert: vi.fn(),
}));
vi.mock("../lib/supabase", () => ({ createBrowserClient: () => ({ auth: api, from: () => ({ upsert: api.upsert }) }) }));
beforeEach(() => {
  vi.clearAllMocks(); localStorage.clear();
  for (const method of [api.signInWithPassword, api.signOut, api.exchangeCodeForSession, api.setSession, api.upsert]) method.mockResolvedValue({ error: null });
  api.signUp.mockResolvedValue({ data: { user: { id: "customer" }, session: {} }, error: null });
  api.getUser.mockResolvedValue({ data: { user: { id: "customer", email: "customer@example.invalid" } }, error: null });
});
describe("Shared customer accounts", () => {
  it("uses the mobile profile fields during registration", async () => {
    await registerCustomer(" customer@example.invalid ", "password123", " Customer Name ", "071 234 5678");
    expect(api.signUp).toHaveBeenCalledWith(expect.objectContaining({ email: "customer@example.invalid", options: expect.objectContaining({ data: { full_name: "Customer Name", phone: "+27712345678", policy_version: POLICY_VERSION, policy_client: "website" } }) }));
  });
  it("propagates invalid credentials and never claims sign-in succeeded", async () => {
    api.signInWithPassword.mockResolvedValue({ error: new Error("Invalid login credentials") });
    await expect(signInCustomer("customer@example.invalid", "wrong")).rejects.toThrow("Invalid login");
  });
  it("saves only the authenticated user's profile without a role field", async () => {
    await saveCustomerProfile("New Name", "0712345678");
    expect(api.upsert).toHaveBeenCalledWith({ id: "customer", email: "customer@example.invalid", full_name: "New Name", phone: "+27712345678" });
  });
  it("refuses profile writes from guests and invalid phone values", async () => {
    await expect(saveCustomerProfile("Name", "not-a-phone")).rejects.toThrow("phone");
    api.getUser.mockResolvedValue({ data: { user: { id: "guest", is_anonymous: true } }, error: null });
    await expect(saveCustomerProfile("Name", "0712345678")).rejects.toThrow("Sign in");
    expect(api.upsert).not.toHaveBeenCalled();
  });
  it("clears cached customer information on sign-out", async () => {
    localStorage.setItem("peri_q_customer_v1", "private details");
    await signOutCustomer();
    expect(localStorage.getItem("peri_q_customer_v1")).toBeNull();
    expect(api.signOut).toHaveBeenCalledWith({ scope: "local" });
  });
  it("exchanges callback codes and rejects expired/incomplete links", async () => {
    expect(await completeAuthCallback("https://rastasperiq.co.za/auth/callback/?code=test-code&recovery=1")).toBe(true);
    expect(api.exchangeCodeForSession).toHaveBeenCalledWith("test-code");
    await expect(completeAuthCallback("https://rastasperiq.co.za/auth/callback/?error=expired")).rejects.toThrow("expired");
    await expect(completeAuthCallback("https://rastasperiq.co.za/auth/callback/")).rejects.toThrow("incomplete");
  });
  it("restores an implicit recovery session from the full token pair", async () => {
    expect(await completeAuthCallback("https://rastasperiq.co.za/auth/callback/#access_token=test-access&refresh_token=test-refresh&type=recovery")).toBe(true);
    expect(api.setSession).toHaveBeenCalledWith({ access_token: "test-access", refresh_token: "test-refresh" });
  });
});
