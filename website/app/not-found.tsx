import Link from "next/link";
import { ArrowLeft } from "lucide-react";

export default function NotFound() {
  return (
    <main id="main-content" className="grid min-h-[65svh] place-items-center bg-charcoal px-5 py-20 text-center text-white">
      <div>
        <p className="eyebrow justify-center text-orange">404</p>
        <h1 className="mt-6 font-display text-5xl font-black uppercase tracking-[-0.04em] sm:text-7xl">
          This page missed the flame.
        </h1>
        <p className="mx-auto mt-5 max-w-md leading-7 text-white/60">
          The page you were looking for is not available.
        </p>
        <Link href="/" className="button button-primary mt-8">
          <ArrowLeft size={18} aria-hidden="true" />
          Return home
        </Link>
      </div>
    </main>
  );
}
