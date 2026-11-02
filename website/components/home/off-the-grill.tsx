"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useRef } from "react";
import { ArrowRight } from "lucide-react";
import { getGsap, prefersReducedMotion } from "@/lib/motion";

export type GrillDish = {
  id: string;
  name: string;
  category: string;
  price: number;
  photo: string;
  cutout: string | null;
  available: boolean;
};

/** Every dish on the current menu, set down one plate at a time as the section scrolls in. */
export function OffTheGrill({ dishes }: { dishes: GrillDish[] }) {
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const section = sectionRef.current;
    if (!section || prefersReducedMotion()) return;
    const { gsap } = getGsap();
    const ctx = gsap.context(() => {
      gsap.from("[data-plate-turn]", {
        rotate: -70,
        scale: 0.82,
        opacity: 0,
        duration: 1.1,
        stagger: 0.09,
        ease: "power3.out",
        scrollTrigger: { trigger: section, start: "top 75%", once: true },
      });
      gsap.from("[data-dish-text]", {
        y: 18,
        opacity: 0,
        duration: 0.7,
        stagger: 0.09,
        delay: 0.2,
        ease: "power3.out",
        scrollTrigger: { trigger: section, start: "top 75%", once: true },
      });
    }, section);
    return () => ctx.revert();
  }, []);

  if (dishes.length === 0) return null;

  return (
    <section ref={sectionRef} id="off-the-grill" className="stage section-pad overflow-hidden border-t border-white/6">
      <div className="site-shell">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="eyebrow eyebrow-ember">Off the grill</p>
            <h2 className="section-title mt-4 text-cream">Every plate on the menu.</h2>
          </div>
          <Link href="/menu/" className="button button-ghost self-start sm:self-auto">
            Full menu
            <ArrowRight size={18} aria-hidden="true" />
          </Link>
        </div>
      </div>

      <ul
        className="mt-10 flex snap-x snap-mandatory gap-5 overflow-x-auto scroll-px-[max(1rem,calc((100vw_-_74rem)/2))] px-[max(1rem,calc((100vw_-_74rem)/2))] pb-6 [scrollbar-width:thin]"
        aria-label="Dishes on the current menu"
      >
        {dishes.map((dish) => (
          <li key={dish.id} className="w-[16.5rem] shrink-0 snap-start sm:w-[18rem]">
            <Link
              href={`/menu/?item=${encodeURIComponent(dish.id)}`}
              className="group block rounded-[1.25rem] p-2 outline-offset-4 focus-visible:outline-3"
            >
              <div className="relative grid aspect-square place-items-center">
                <div className="plate-halo opacity-60 transition-opacity duration-300 group-hover:opacity-100" aria-hidden="true" />
                <div className="w-[92%] transition-transform duration-500 ease-out group-hover:rotate-6 group-hover:scale-[1.03]">
                  <div data-plate-turn>
                    {dish.cutout ? (
                      <Image src={dish.cutout} alt={dish.name} width={600} height={600} sizes="288px" className="plate h-auto w-full" />
                    ) : (
                      <Image
                        src={dish.photo}
                        alt={dish.name}
                        width={600}
                        height={600}
                        sizes="288px"
                        className="plate aspect-square h-auto w-full rounded-[1.5rem] object-cover"
                      />
                    )}
                  </div>
                </div>
              </div>
              <div data-dish-text className="mt-3 px-1">
                <p className="text-[0.68rem] font-black uppercase tracking-[0.16em] text-orange">{dish.category}</p>
                <p className="mt-1 line-clamp-2 min-h-[2.6rem] text-[0.95rem] font-bold leading-5 text-cream">{dish.name}</p>
                <div className="mt-2 flex items-center justify-between">
                  <span className="price-tag text-2xl text-cream">R{dish.price.toFixed(0)}</span>
                  <span className="inline-flex items-center gap-1 text-sm font-extrabold text-orange group-hover:text-cream">
                    {dish.available ? "Order" : "Unavailable"}
                    {dish.available && <ArrowRight size={16} aria-hidden="true" />}
                  </span>
                </div>
              </div>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}
