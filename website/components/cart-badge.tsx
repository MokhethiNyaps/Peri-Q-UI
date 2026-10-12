"use client";
import Link from "next/link";
import { ShoppingBasket } from "lucide-react";
import { useCart } from "@/lib/cart";

export function CartBadge() {
  const { count } = useCart();
  return (
    <Link href="/cart/" className="relative inline-flex items-center gap-2 rounded-full border border-black/10 bg-white px-4 py-2 text-sm font-extrabold text-charcoal hover:bg-cream">
      <ShoppingBasket size={18} aria-hidden="true" className="text-peri-red" />
      Cart
      {count > 0 && (
        <span className="grid size-6 place-items-center rounded-full bg-peri-red text-xs font-black text-white" aria-label={`${count} items in cart`}>
          {count}
        </span>
      )}
    </Link>
  );
}

export function MobileCartLink() {
  const { count } = useCart();
  return (
    <Link href="/cart/" className="mobile-nav-link flex items-center justify-between">
      <span>Cart</span>
      {count > 0 ? <span className="rounded-full bg-peri-red px-2 py-0.5 text-xs font-black text-white">{count}</span> : null}
    </Link>
  );
}
