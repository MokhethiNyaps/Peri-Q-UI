import Image from "next/image";
import Link from "next/link";

type BrandProps = {
  compact?: boolean;
  inverted?: boolean;
};

export function Brand({ compact = false, inverted = false }: BrandProps) {
  return (
    <Link href="/" aria-label="RastasperiQ home" className="group flex items-center gap-2.5">
      <Image
        src="/brand/flame-mark-192.png"
        alt=""
        width={96}
        height={96}
        priority
        className={`shrink-0 transition-transform duration-300 group-hover:-rotate-6 ${compact ? "size-10" : "size-12"} ${
          inverted ? "drop-shadow-[0_0_14px_rgba(240,120,32,0.35)]" : ""
        }`}
      />
      <span className="leading-none">
        <span
          className={`block font-display text-[1.45rem] font-extrabold uppercase tracking-[0.01em] ${
            inverted ? "text-cream" : "text-charcoal"
          }`}
        >
          Rastasperi<span className="text-orange">Q</span>
        </span>
        {!compact && (
          <span
            className={`mt-1 block text-[0.64rem] font-bold uppercase tracking-[0.22em] ${
              inverted ? "text-smoke" : "text-ash"
            }`}
          >
            Flame. Flavour. Vibes.
          </span>
        )}
      </span>
    </Link>
  );
}
