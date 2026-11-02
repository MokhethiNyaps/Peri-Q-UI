"use client";
import Link from "next/link";
import { ShoppingBasket } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { useCart } from "@/lib/cart";

function useBump(count: number) {
  const [bump, setBump] = useState(false);
  const previous = useRef(count);
  useEffect(() => {
    if (count > previous.current) {
      setBump(true);
      const timer = setTimeout(() => setBump(false), 450);
      previous.current = count;
      return () => clearTimeout(timer);
    }
    previous.current = count;
  }, [count]);
  return bump;
}

export function CartBadge({ compact = false }: { compact?: boolean }) {
  const { count, subtotal } = useCart();
  const bump = useBump(count);
  const label = count > 0 ? `Cart, ${count} ${count === 1 ? "item" : "items"}, R${subtotal.toFixed(0)}` : "Cart, empty";

  return (
    <Link
      href="/cart/"
      aria-label={label}
      data-cart-target={compact ? "mobile" : "desktop"}
      className="relative inline-flex min-h-11 items-center gap-2 rounded-full border border-white/12 bg-white/6 px-3.5 text-sm font-extrabold text-cream transition-colors hover:border-orange/60 hover:bg-orange/12"
    >
      <ShoppingBasket size={18} aria-hidden="true" className="text-orange" />
      {!compact && <span>Cart</span>}
      {count > 0 && (
        <>
          <span
            className={`grid min-w-6 place-items-center rounded-full bg-peri-red px-1.5 py-0.5 text-xs font-black text-white ${bump ? "badge-bump" : ""}`}
          >
            {count}
          </span>
          {!compact && <span className="tabular-nums text-smoke">R{subtotal.toFixed(0)}</span>}
        </>
      )}
    </Link>
  );
}

export function MobileCartLink() {
  const { count } = useCart();
  return (
    <Link href="/cart/" className="mobile-nav-link mobile-nav-link-dark flex items-center justify-between">
      <span>Cart</span>
      {count > 0 ? <span className="rounded-full bg-peri-red px-2 py-0.5 text-xs font-black text-white">{count}</span> : null}
    </Link>
  );
}
