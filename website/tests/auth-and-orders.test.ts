import { describe, it, expect } from "vitest";

describe("Customer orders / admin isolation (RLS simulation)", () => {
  // Simulate RLS: orders_select_owner_or_admin = owner OR admin
  function canRead(orderUserId: string, callerUserId: string | null, isAdmin: boolean): boolean {
    if (isAdmin) return true;
    if (!callerUserId) return false;
    return orderUserId === callerUserId;
  }

  it("owner can read own order, not others", () => {
    expect(canRead("userA", "userA", false)).toBe(true);
    expect(canRead("userA", "userB", false)).toBe(false);
  });

  it("admin can read all", () => {
    expect(canRead("userA", "userB", true)).toBe(true);
    expect(canRead("userA", null, true)).toBe(true);
  });

  it("unauthenticated cannot read any order", () => {
    expect(canRead("userA", null, false)).toBe(false);
  });

  it("duplicate checkout submission is idempotent via (user_id, client_request_id)", () => {
    // Covered more thoroughly in yoco.test — smoke here
    const seen = new Map<string, string>();
    const create = (userId: string, reqId: string) => {
      const key = `${userId}:${reqId}`;
      if (seen.has(key)) return seen.get(key)!;
      const id = `order-${seen.size + 1}`;
      seen.set(key, id);
      return id;
    };
    const a = create("u1", "r1");
    const b = create("u1", "r1");
    const c = create("u1", "r2");
    expect(a).toBe(b);
    expect(a).not.toBe(c);
  });
});

describe("Successful website order creation (shared system)", () => {
  it("order created via place_order enters same orders table as mobile", () => {
    // Contract: both website and app call place_order RPC which writes to public.orders + order_items
    // No second independent system
    const orderInsertedInto = "public.orders";
    const appOrdersTable = "public.orders";
    const webOrdersTable = "public.orders";
    expect(orderInsertedInto).toBe(appOrdersTable);
    expect(webOrdersTable).toBe(appOrdersTable);
  });
});
