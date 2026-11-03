import { act, cleanup, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import PaymentStatus, { appReturnLink } from "../app/payment/[id]/payment-status";

const mocks = vi.hoisted(() => ({ query: vi.fn(), clear: vi.fn(), entries: [] as { id: string }[] }));
vi.mock("@/lib/supabase", () => ({ createBrowserClient: () => ({ from: () => ({ select: () => ({ eq: () => ({ maybeSingle: mocks.query }) }) }) }) }));
vi.mock("@/lib/cart", () => ({ useCart: () => ({ clear: mocks.clear, entries: mocks.entries }) }));

beforeEach(() => {
  vi.useFakeTimers();
  mocks.clear.mockReset(); mocks.query.mockReset(); mocks.entries = [];
  mocks.query.mockResolvedValue({ data: { payment_status: "pending" }, error: null });
  window.history.replaceState({}, "", "/payment/order-1/?checkout=success");
  localStorage.clear();
  Object.defineProperty(document, "visibilityState", { configurable: true, value: "visible" });
  vi.spyOn(window.location, "replace").mockImplementation(() => {});
});
afterEach(() => { cleanup(); vi.restoreAllMocks(); vi.useRealTimers(); });
const mount = () => act(async () => { render(<PaymentStatus id="order-1" />); });

describe("Authoritative payment return status", () => {
  it("does not treat a success or failure redirect as proof of payment", async () => {
    window.history.replaceState({}, "", "/payment/order-1/?checkout=failure");
    await mount();
    expect(screen.getByRole("status")).toHaveTextContent("Waiting for payment confirmation");
    expect(mocks.clear).not.toHaveBeenCalled();
    expect(window.location.replace).not.toHaveBeenCalled();
  });
  it("shows a database-confirmed failure", async () => {
    mocks.query.mockResolvedValue({ data: { payment_status: "failed" }, error: null });
    await mount();
    expect(screen.getByRole("status")).toHaveTextContent("Payment could not be completed");
    expect(mocks.clear).not.toHaveBeenCalled();
  });
  it("does not overlap slow requests and stops polling after unmount", async () => {
    mocks.query.mockReturnValue(new Promise(() => {}));
    await mount();
    await act(async () => { vi.advanceTimersByTime(12000); });
    expect(mocks.query).toHaveBeenCalledTimes(1);
    cleanup();
    await act(async () => { vi.advanceTimersByTime(12000); });
    expect(mocks.query).toHaveBeenCalledTimes(1);
  });
  it("recovers after a network exception without losing the cart", async () => {
    mocks.query.mockRejectedValueOnce(new Error("offline"));
    await mount();
    expect(screen.getByRole("status")).toHaveTextContent("try again automatically");
    await act(async () => { vi.advanceTimersByTime(3000); });
    expect(screen.getByRole("status")).toHaveTextContent("Waiting for payment confirmation");
    expect(mocks.clear).not.toHaveBeenCalled();
  });
  it("returns app customers to the app automatically, with a button as fallback", async () => {
    const assign = vi.spyOn(window.location, "assign").mockImplementation(() => {});
    window.history.replaceState({}, "", "/payment/order-1/?source=mobile&checkout=cancel");
    await mount();
    expect(screen.getByRole("status")).toHaveTextContent("Return to the app");
    expect(screen.getByRole("link", { name: /Return to the app/ })).toHaveAttribute("href", expect.stringContaining("payment-return?order=order-1&result=cancel"));
    await act(async () => { vi.advanceTimersByTime(600); });
    expect(assign).toHaveBeenCalledWith(expect.stringContaining("payment-return?order=order-1&result=cancel"));
    expect(mocks.query).not.toHaveBeenCalled();
  });
  it("builds an Android intent link and a plain app link elsewhere", () => {
    expect(appReturnLink("a b", "success", "Mozilla/5.0 (Linux; Android 14)")).toBe(
      "intent://payment-return?order=a%20b&result=success#Intent;scheme=rastasperiq;package=za.co.rastasperiq.ordering;end",
    );
    expect(appReturnLink("x", "failure", "Mozilla/5.0 (iPhone)")).toBe("rastasperiq://payment-return?order=x&result=failure");
    expect(appReturnLink("x", "cancel", "Android", "https://rastasperiq.co.za/payment/x/?noapp=1")).toContain(
      "S.browser_fallback_url=https%3A%2F%2Frastasperiq.co.za%2Fpayment%2Fx%2F%3Fnoapp%3D1;end",
    );
  });
  it("does not loop back to the app for app versions without the return link", async () => {
    const assign = vi.spyOn(window.location, "assign").mockImplementation(() => {});
    window.history.replaceState({}, "", "/payment/order-1/?source=mobile&checkout=success&noapp=1");
    await mount();
    await act(async () => { vi.advanceTimersByTime(2000); });
    expect(assign).not.toHaveBeenCalled();
    expect(screen.getByRole("status")).toHaveTextContent("Return to the app");
  });
  it("sends mobile browser returns back to the authenticated app", async () => {
    window.history.replaceState({}, "", "/payment/order-1/?source=mobile&checkout=success");
    await mount();
    expect(screen.getByRole("status")).toHaveTextContent("Return to the app");
    expect(mocks.query).not.toHaveBeenCalled();
  });
  it("clears only the cart associated with the confirmed checkout", async () => {
    mocks.entries = [{ id: "paid-item" }];
    localStorage.setItem("peri_q_pending_payment", JSON.stringify({ orderId: "order-1", cart: JSON.stringify(mocks.entries) }));
    mocks.query.mockResolvedValue({ data: { payment_status: "paid" }, error: null });
    await mount();
    expect(mocks.clear).toHaveBeenCalledTimes(1);
    expect(window.location.replace).toHaveBeenCalledWith("/order/order-1/?new=1");
  });
  it("preserves newer cart items when an earlier payment completes", async () => {
    mocks.entries = [{ id: "new-item" }];
    localStorage.setItem("peri_q_pending_payment", JSON.stringify({ orderId: "order-1", cart: JSON.stringify([{ id: "old-item" }]) }));
    mocks.query.mockResolvedValue({ data: { payment_status: "paid" }, error: null });
    await mount();
    expect(mocks.clear).not.toHaveBeenCalled();
    expect(window.location.replace).toHaveBeenCalled();
  });
});
