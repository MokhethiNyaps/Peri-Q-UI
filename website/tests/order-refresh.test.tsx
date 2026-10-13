import { act, cleanup, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import OrderClient from "../app/order/[id]/order-client";

const query = vi.hoisted(() => ({ getSession: vi.fn(), maybeSingle: vi.fn() }));
vi.mock("next/navigation", () => ({ useSearchParams: () => new URLSearchParams("new=1") }));
vi.mock("@/lib/customer-auth", () => ({ useCustomerAuth: () => ({ user: { id: "customer" } }) }));
vi.mock("@/lib/supabase", () => ({ createBrowserClient: () => ({ auth: { getSession: query.getSession }, from: () => ({ select: () => ({ eq: () => ({ maybeSingle: query.maybeSingle }) }) }) }) }));
const order = { id: "order-1", order_number: 42, customer_name: "Test Customer", customer_phone: "0700000000", order_type: "pickup", payment_method: "cash_collection", total_price: 45, status: "pending", estimated_minutes: 25, created_at: "2026-10-13T10:00:00Z", payment_status: "unpaid", order_items: [] };
beforeEach(() => {
  vi.useFakeTimers(); query.getSession.mockResolvedValue({ data: { session: { user: { id: "customer" } } } });
  query.maybeSingle.mockReset(); query.maybeSingle.mockResolvedValue({ data: order, error: null });
});
afterEach(() => { cleanup(); vi.useRealTimers(); });
async function mount() {
  await act(async () => { render(<OrderClient orderId="order-1" />); });
  return screen.getByRole("heading", { name: "Order details", exact: true });
}
describe("Order status refresh without scrolling jumps", () => {
  it("keeps the same content mounted while the next poll is slow", async () => {
    const details = await mount();
    let finish!: (value: unknown) => void;
    query.maybeSingle.mockReturnValue(new Promise(resolve => { finish = resolve; }));
    await act(async () => { vi.advanceTimersByTime(8000); });
    expect(screen.getByRole("heading", { name: "Order details", exact: true })).toBe(details);
    expect(screen.getByText("Updating status…")).toBeInTheDocument();
    await act(async () => { vi.advanceTimersByTime(16000); });
    expect(query.maybeSingle).toHaveBeenCalledTimes(2);
    await act(async () => { finish({ data: { ...order, status: "preparing" }, error: null }); });
    expect(screen.getByRole("heading", { name: "Order details", exact: true })).toBe(details);
    expect(screen.getByText("Preparing", { exact: true })).toBeInTheDocument();
  });
  it("keeps the order visible if a background request fails", async () => {
    const details = await mount();
    query.maybeSingle.mockRejectedValue(new Error("Connection interrupted"));
    await act(async () => { vi.advanceTimersByTime(8000); });
    expect(screen.getByRole("heading", { name: "Order details", exact: true })).toBe(details);
    expect(screen.getByRole("status")).toHaveTextContent("Connection interrupted");
  });
  it("stops polling after leaving the page", async () => {
    await mount(); cleanup();
    await act(async () => { vi.advanceTimersByTime(24000); });
    expect(query.maybeSingle).toHaveBeenCalledTimes(1);
  });
});
