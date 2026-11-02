"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { ArrowRight, ShoppingBasket } from "lucide-react";
import { useCart } from "@/lib/cart";

// Pages where the cart is already the task, or where a floating bar would sit
// on top of payment or order status.
const HIDDEN_ON = ["/cart", "/checkout", "/payment", "/order", "/account", "/auth"];

export function MobileCartBar() {
  const { count, subtotal } = useCart();
  const pathname = usePathname() ?? "/";
  if (count === 0 || HIDDEN_ON.some((path) => pathname.startsWith(path))) return null;

  return (
    <div className="cart-bar md:hidden">
      <Link
        href="/cart/"
        className="flex min-h-14 items-center justify-between gap-3 rounded-2xl bg-peri-red px-5 text-white shadow-[0_18px_40px_rgba(0,0,0,0.45)]"
      >
        <span className="flex items-center gap-3 font-extrabold">
          <ShoppingBasket size={20} aria-hidden="true" />
          View cart · {count} {count === 1 ? "item" : "items"}
        </span>
        <span className="flex items-center gap-2 font-display text-xl font-extrabold tabular-nums">
          R{subtotal.toFixed(0)}
          <ArrowRight size={18} aria-hidden="true" />
        </span>
      </Link>
    </div>
  );
}
