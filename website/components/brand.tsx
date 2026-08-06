import Image from "next/image";
import Link from "next/link";

type BrandProps = {
  compact?: boolean;
  inverted?: boolean;
};

export function Brand({ compact = false, inverted = false }: BrandProps) {
  return (
    <Link
      href="/"
      aria-label="RastasperiQ home"
      className="group flex items-center gap-3"
    >
      <span
        className={`grid shrink-0 place-items-center overflow-hidden rounded-2xl border p-1 shadow-sm transition-transform group-hover:-rotate-2 ${
          inverted
            ? "border-white/15 bg-cream"
            : "border-black/10 bg-cream"
        } ${compact ? "size-11" : "size-13"}`}
      >
        <Image
          src="/brand-mark.png"
          alt=""
          width={64}
          height={64}
          priority
          className="h-full w-full scale-[1.45] object-contain"
        />
      </span>
      <span className="leading-none">
        <span
          className={`block font-display text-base font-black uppercase tracking-[-0.02em] ${
            inverted ? "text-white" : "text-charcoal"
          }`}
        >
          RastasperiQ
        </span>
        {!compact && (
          <span
            className={`mt-1 block text-[0.64rem] font-bold uppercase tracking-[0.22em] ${
              inverted ? "text-white/55" : "text-ash"
            }`}
          >
            Flame. Flavour. Vibes.
          </span>
        )}
      </span>
    </Link>
  );
}
