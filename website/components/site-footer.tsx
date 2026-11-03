import { MapPin } from "lucide-react";
import Link from "next/link";
import { Brand } from "@/components/brand";
import { SocialLinks } from "@/components/social-links";
import { siteConfig } from "@/lib/site";

export function SiteFooter() {
  return (
    <footer className="bg-charcoal text-white">
      <div className="site-shell grid gap-12 py-14 lg:grid-cols-[1.25fr_0.75fr_0.75fr]">
        <div className="max-w-md">
          <Brand inverted />
          <p className="mt-5 text-sm leading-7 text-white/60">
            Flame-grilled favourites, simple mobile ordering, and proper chesanyama
            flavour in the heart of Bloemfontein.
          </p>
          <div className="mt-6">
            <SocialLinks compact />
          </div>
        </div>

        <div>
          <p className="footer-title">Explore</p>
          <div className="mt-4 grid gap-3 text-sm text-white/65">
            <Link href="/#how-it-works">How it works</Link>
            <Link href="/#visit">Visit us</Link>
            <Link href="/get-app/">Get the app</Link>
            <Link href="/privacy-policy/">Privacy policy</Link>
            <Link href="/terms-and-conditions/">Terms and conditions</Link>
            <Link href="/complaints/">Complaints</Link>
            <Link href="/legal/">All legal and policies</Link>
            <Link href="/delete-account/">Delete account</Link>
          </div>
        </div>

        <div>
          <p className="footer-title">Find us</p>
          <a
            href={siteConfig.mapsUrl}
            target="_blank"
            rel="noreferrer"
            className="mt-4 flex gap-3 text-sm leading-6 text-white/65 transition-colors hover:text-white"
          >
            <MapPin className="mt-1 shrink-0 text-orange" size={18} aria-hidden="true" />
            {siteConfig.address}
          </a>
        </div>
      </div>

      <div className="border-t border-white/10">
        <div className="site-shell flex flex-col gap-2 py-5 text-xs text-white/45 sm:flex-row sm:items-center sm:justify-between">
          <p>© {new Date().getFullYear()} RastasperiQ.</p>
          <p>Flame. Flavour. Vibes.</p>
        </div>
      </div>
    </footer>
  );
}
