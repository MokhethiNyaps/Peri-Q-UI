import { Menu } from "lucide-react";
import Link from "next/link";
import { Brand } from "@/components/brand";
import { CartBadge, MobileCartLink } from "@/components/cart-badge";
import { AccountLink } from "@/components/account-link";

const navigation = [
  { href: "/menu/", label: "Menu & Order" },
  { href: "/#how-it-works", label: "How it works" },
  { href: "/#visit", label: "Visit us" },
  { href: "/privacy-policy/", label: "Privacy" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-black/8 bg-cream/92 backdrop-blur-xl">
      <div className="site-shell flex h-20 items-center justify-between gap-5">
        <Brand compact />

        <nav aria-label="Primary navigation" className="hidden items-center gap-5 lg:flex">
          {navigation.map((item) => (
            <Link key={item.href} href={item.href} className="nav-link">
              {item.label}
            </Link>
          ))}
          <CartBadge />
          <AccountLink />
          <Link href="/#contact" className="button button-sm button-dark">
            Contact us
          </Link>
        </nav>

        <details className="mobile-menu relative lg:hidden">
          <summary
            className="grid size-11 cursor-pointer list-none place-items-center rounded-full border border-black/10 bg-white text-charcoal"
            aria-label="Open navigation"
          >
            <Menu size={20} aria-hidden="true" />
          </summary>
          <nav
            aria-label="Mobile navigation"
            className="absolute right-0 top-14 w-64 rounded-3xl border border-black/10 bg-white p-3 shadow-2xl"
          >
            {navigation.map((item) => (
              <Link key={item.href} href={item.href} className="mobile-nav-link">
                {item.label}
              </Link>
            ))}
            <MobileCartLink />
            <AccountLink mobile />
            <Link href="/#contact" className="button button-dark mt-2 w-full">
              Contact us
            </Link>
          </nav>
        </details>
      </div>
    </header>
  );
}
