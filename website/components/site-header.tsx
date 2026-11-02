import { Menu } from "lucide-react";
import Link from "next/link";
import { Brand } from "@/components/brand";
import { CartBadge, MobileCartLink } from "@/components/cart-badge";
import { AccountLink } from "@/components/account-link";

const navigation = [
  { href: "/menu/", label: "Menu" },
  { href: "/#how-it-works", label: "How it works" },
  { href: "/#visit", label: "Visit us" },
  { href: "/get-app/", label: "Get the app" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-white/8 bg-soot/88 text-cream backdrop-blur-xl">
      <div className="site-shell flex h-[4.5rem] items-center justify-between gap-5">
        <Brand compact inverted />

        <nav aria-label="Primary navigation" className="hidden items-center gap-6 lg:flex">
          {navigation.map((item) => (
            <Link key={item.href} href={item.href} className="nav-link nav-link-dark">
              {item.label}
            </Link>
          ))}
          <AccountLink />
          <CartBadge />
        </nav>

        <div className="flex items-center gap-2 lg:hidden">
          <CartBadge compact />
          <details className="mobile-menu relative">
            <summary
              className="grid size-11 cursor-pointer list-none place-items-center rounded-full border border-white/12 bg-white/6 text-cream"
              aria-label="Open navigation"
            >
              <Menu size={20} aria-hidden="true" />
            </summary>
            <nav
              aria-label="Mobile navigation"
              className="absolute right-0 top-14 w-64 rounded-3xl border border-white/10 bg-charcoal p-3 shadow-2xl"
            >
              {navigation.map((item) => (
                <Link key={item.href} href={item.href} className="mobile-nav-link mobile-nav-link-dark">
                  {item.label}
                </Link>
              ))}
              <MobileCartLink />
              <AccountLink mobile />
              <Link href="/#contact" className="mobile-nav-link mobile-nav-link-dark">
                Contact us
              </Link>
            </nav>
          </details>
        </div>
      </div>
    </header>
  );
}
