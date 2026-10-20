import { act, cleanup, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import PaymentStatus from "../app/payment/[id]/payment-status";

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
