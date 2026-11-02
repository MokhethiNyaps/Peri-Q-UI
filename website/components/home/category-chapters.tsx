"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useRef } from "react";
import { ArrowUpRight } from "lucide-react";
import { getGsap, prefersReducedMotion } from "@/lib/motion";

export type Chapter = {
  name: string;
  count: number;
  fromPrice: number;
  photo: string;
  photoAlt: string;
};

/** One tile per category that has food in it; the photo opens behind grill bars as it scrolls in. */
export function CategoryChapters({ chapters }: { chapters: Chapter[] }) {
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const section = sectionRef.current;
    if (!section || prefersReducedMotion()) return;
    const { gsap } = getGsap();
    const ctx = gsap.context(() => {
      gsap.utils.toArray<HTMLElement>("[data-grill]").forEach((tile) => {
        gsap.fromTo(tile.querySelectorAll(".grill-reveal__bars span"), { scaleX: 1 }, {
          scaleX: 0,
          duration: 0.9,
          stagger: 0.06,
          ease: "power3.inOut",
          scrollTrigger: { trigger: tile, start: "top 80%", once: true },
        });
      });
    }, section);
    return () => ctx.revert();
  }, []);

  if (chapters.length === 0) return null;

  return (
    <section ref={sectionRef} className="stage section-pad border-t border-white/6">
      <div className="site-shell">
        <p className="eyebrow eyebrow-ember">The menu by category</p>
        <h2 className="section-title mt-4 text-cream">Choose your fire.</h2>

        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {chapters.map((chapter, index) => (
            <Link
              key={chapter.name}
              href={`/menu/?category=${encodeURIComponent(chapter.name)}`}
              data-grill
              className={`grill-reveal group relative block overflow-hidden rounded-[1.25rem] border border-white/8 ${
                index === 0 ? "sm:col-span-2 lg:row-span-2 lg:col-span-1" : ""
              }`}
            >
              <div className={`relative ${index === 0 ? "aspect-[4/3] lg:aspect-auto lg:h-full lg:min-h-[28rem]" : "aspect-[4/3]"}`}>
                <Image
                  src={chapter.photo}
                  alt={chapter.photoAlt}
                  fill
                  sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"
                  className="object-cover transition-transform duration-700 ease-out group-hover:scale-[1.04]"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-soot via-soot/35 to-transparent" />
              </div>
              <div className="grill-reveal__bars" aria-hidden="true">
                {Array.from({ length: 6 }).map((_, bar) => (
                  <span key={bar} />
                ))}
              </div>
              <div className="absolute inset-x-0 bottom-0 flex items-end justify-between gap-4 p-5">
                <div>
                  <p className="font-display text-3xl font-extrabold uppercase leading-none text-cream">{chapter.name}</p>
                  <p className="mt-1 text-sm font-semibold text-smoke">
                    {chapter.count} {chapter.count === 1 ? "plate" : "plates"} · from R{chapter.fromPrice.toFixed(0)}
                  </p>
                </div>
                <span className="grid size-11 shrink-0 place-items-center rounded-full bg-peri-red text-white transition-transform group-hover:-rotate-12">
                  <ArrowUpRight size={20} aria-hidden="true" />
                </span>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
