"use client";

import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { MenuItem } from "./menu";

export type CartAddOn = { name: string; price: number };
export type CartEntry = {
  id: string; // unique cart line id
  item: MenuItem;
  quantity: number;
  spiceLevel?: string | null;
  notes?: string;
  selectedAddOns: CartAddOn[];
};

type CartContextValue = {
  entries: CartEntry[];
  count: number;
  subtotal: number;
  add: (item: MenuItem, opts?: { quantity?: number; spiceLevel?: string | null; notes?: string; selectedAddOns?: CartAddOn[] } ) => void;
  inc: (id: string) => void;
  dec: (id: string) => void;
  remove: (id: string) => void;
  clear: () => void;
  setEntries: (entries: CartEntry[]) => void;
};

const STORAGE_KEY = "peri_q_cart_v1";

const CartContext = createContext<CartContextValue | null>(null);

function loadFromStorage(): CartEntry[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as CartEntry[];
    if (!Array.isArray(parsed)) return [];
    return parsed.filter((e) => e && e.item && typeof e.quantity === "number");
  } catch {
    return [];
  }
}

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [entries, setEntriesState] = useState<CartEntry[]>(() => []);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setEntriesState(loadFromStorage());
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
    } catch {}
  }, [entries, hydrated]);

  const setEntries = (next: CartEntry[]) => setEntriesState(next);

  const add = (item: MenuItem, opts: { quantity?: number; spiceLevel?: string | null; notes?: string; selectedAddOns?: CartAddOn[] } = {}) => {
    const qty = opts.quantity ?? 1;
    if (qty < 1 || qty > 50) throw new Error("Quantity must be 1–50");
    if (!item.isAvailable) throw new Error("This item is currently unavailable.");
    const entry: CartEntry = {
      id: `${item.id}-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
      item,
      quantity: qty,
      spiceLevel: opts.spiceLevel ?? null,
      notes: (opts.notes ?? "").slice(0, 500),
      selectedAddOns: (opts.selectedAddOns ?? []).map((a) => ({ name: a.name, price: a.price })),
    };
    setEntriesState((prev) => [...prev, entry]);
  };

  const inc = (id: string) => {
    setEntriesState((prev) => prev.map((e) => (e.id === id ? { ...e, quantity: Math.min(50, e.quantity + 1) } : e)));
  };
  const dec = (id: string) => {
    setEntriesState((prev) => {
      const target = prev.find((e) => e.id === id);
      if (!target) return prev;
      if (target.quantity <= 1) return prev.filter((e) => e.id !== id);
      return prev.map((e) => (e.id === id ? { ...e, quantity: e.quantity - 1 } : e));
    });
  };
  const remove = (id: string) => setEntriesState((prev) => prev.filter((e) => e.id !== id));
  const clear = useCallback(() => setEntriesState([]), []);

  const count = useMemo(() => entries.reduce((s, e) => s + e.quantity, 0), [entries]);
  const subtotal = useMemo(
    () =>
      entries.reduce((s, e) => {
        const addOnSum = e.selectedAddOns.reduce((a, ad) => a + (ad.price ?? 0), 0);
        return s + (e.item.price + addOnSum) * e.quantity;
      }, 0),
    [entries],
  );

  const value: CartContextValue = { entries, count, subtotal, add, inc, dec, remove, clear, setEntries };
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart must be used within CartProvider");
  return ctx;
}

