import { beforeEach, describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen, within } from "@testing-library/react";
import CheckoutClient from "../app/checkout/checkout-client";
import { siteConfig } from "../lib/site";

const item = { id: "plate", name: "Pork Plate", description: "", price: 45, category: "Meals", imagePath: "", isAvailable: true, prepMinutes: 20, spiceLevels: ["Hot"], addOns: [{ name: "Cheese", price: 5 }] };
const entries = [{ id: "line-1", item, quantity: 2, spiceLevel: "Hot", notes: "No onions", selectedAddOns: [{ name: "Cheese", price: 5 }] }];

vi.mock("@/lib/cart", () => ({ useCart: () => ({ entries, subtotal: 100, clear: vi.fn() }) }));
vi.mock("@/lib/customer-auth", () => ({ useCustomerAuth: () => ({ user: null, profile: null }) }));
vi.mock("@/lib/supabase", () => ({ isSupabaseConfigured: () => true, createBrowserClient: vi.fn() }));
vi.mock("@/lib/menu", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../lib/menu")>()),
  fetchMenu: async () => ({ items: [], categories: [], appSettings: { storeOpen: true, pickupAvailable: true, deliveryAvailable: true, deliveryFee: 30, openingTime: "00:00", closingTime: "00:00" } }),
}));

beforeEach(() => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response(JSON.stringify({ available: true, mode: "test" }))));
  localStorage.clear();
});

describe("Checkout review (ECTA section 44)", () => {
  it("shows every item with its options, the charges and where the order goes, before payment", async () => {
    render(<CheckoutClient />);
    const review = (await screen.findByRole("heading", { name: "Review your order" })).closest("aside")!;
    const scope = within(review);
    expect(scope.getByText("Pork Plate")).toBeInTheDocument();
    expect(scope.getByText("×2")).toBeInTheDocument();
    expect(scope.getByText("Hot")).toBeInTheDocument();
    expect(scope.getByText("+ Cheese (R5.00)")).toBeInTheDocument();
    expect(scope.getByText("Note: No onions")).toBeInTheDocument();
    expect(scope.getByText("Total to pay now")).toBeInTheDocument();
    expect(scope.getByText(siteConfig.address)).toBeInTheDocument();
    expect(scope.getByRole("link", { name: "Edit cart" }).getAttribute("href")).toMatch(/^\/cart\/?$/);
    expect(scope.getByRole("link", { name: "Cancellations and refunds" }).getAttribute("href")).toMatch(/^\/terms-and-conditions\/?$/);
  });

  it("repeats the delivery address and contact details as they are typed", async () => {
    render(<CheckoutClient />);
    await screen.findByRole("heading", { name: "Review your order" });
    fireEvent.click(screen.getByText("Home Delivery"));
    const details = screen.getByTestId("order-review-details");
    expect(within(details).getByText("Enter your delivery address")).toBeInTheDocument();
    fireEvent.change(screen.getByPlaceholderText("e.g. Thabo Molefe"), { target: { value: "Erin Example" } });
    fireEvent.change(screen.getByPlaceholderText(/House|street|address/i), { target: { value: "12 Test Street, Bloemfontein" } });
    expect(within(details).getByText("12 Test Street, Bloemfontein")).toBeInTheDocument();
    expect(within(details).getByText(/Erin Example/)).toBeInTheDocument();
  });
});
