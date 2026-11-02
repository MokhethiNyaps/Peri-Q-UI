"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useRef } from "react";
import { ArrowRight, Flame, MessageCircle } from "lucide-react";
import type { AppSettings } from "@/lib/menu";
import { canHover, getGsap, prefersReducedMotion } from "@/lib/motion";
import { siteConfig } from "@/lib/site";
import { Embers } from "./embers";
import { OpenBadge } from "./open-badge";

export type HeroPlate = {
  id: string | null;
  name: string;
  /** Plate cut-out made from this dish's own photo, or null to use the photo itself. */
  cutout: string | null;
  photo: string;
  price: number | null;
};

type HeroGrillProps = {
  settings: AppSettings | null;
  special: (HeroPlate & { label: string; title: string; subtitle: string }) | null;
  sidePlates: HeroPlate[];
};

export function HeroGrill({ settings, special, sidePlates }: HeroGrillProps) {
  const stageRef = useRef<HTMLDivElement>(null);
  const mainRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const stage = stageRef.current;
    const main = mainRef.current;
    if (!stage || !main || prefersReducedMotion()) return;
    const { gsap } = getGsap();

    const ctx = gsap.context(() => {
      // The plate is set down on the stage with a quarter turn.
      gsap.from(main, { rotate: -38, scale: 0.86, opacity: 0, duration: 1.3, ease: "power3.out" });
      gsap.from("[data-side-plate]", {
        rotate: 30,
        y: 40,
        opacity: 0,
        duration: 1.2,
        delay: 0.25,
        stagger: 0.15,
        ease: "power3.out",
      });
      gsap.from("[data-hero-line]", { y: 28, opacity: 0, duration: 0.8, stagger: 0.08, ease: "power3.out" });
      // A very slow turn afterwards, so the dish feels alive without distracting.
      gsap.to(main.querySelector("[data-turn]"), {
        rotate: 6,
        duration: 9,
        ease: "sine.inOut",
        yoyo: true,
        repeat: -1,
        delay: 1.3,
      });
    }, stage);

    // Desktop only: the plate leans gently toward the pointer.
    let onMove: ((event: PointerEvent) => void) | undefined;
    if (canHover()) {
      const tiltX = gsap.quickTo(main, "rotationX", { duration: 0.6, ease: "power3.out" });
      const tiltY = gsap.quickTo(main, "rotationY", { duration: 0.6, ease: "power3.out" });
      onMove = (event: PointerEvent) => {
        const box = stage.getBoundingClientRect();
        const x = (event.clientX - box.left) / box.width - 0.5;
        const y = (event.clientY - box.top) / box.height - 0.5;
        tiltY(x * 14);
        tiltX(-y * 10);
      };
      stage.addEventListener("pointermove", onMove);
    }

    return () => {
      ctx.revert();
      if (onMove) stage.removeEventListener("pointermove", onMove);
    };
  }, []);

  const orderHref = special?.id ? `/menu/?item=${encodeURIComponent(special.id)}` : "/menu/";

  return (
    <section ref={stageRef} className="stage stage-glow grill-lines overflow-hidden">
      <Embers />
      <div className="site-shell grid items-center gap-x-10 gap-y-8 py-8 lg:min-h-[calc(100svh-4.5rem)] lg:grid-cols-[1fr_1.05fr] lg:py-16">
        <div className="relative z-10 order-2 max-w-2xl lg:order-none lg:col-start-1 lg:row-span-2 lg:row-start-1">
          <div data-hero-line className="flex flex-wrap items-center gap-3">
            <p className="eyebrow eyebrow-ember">Bloemfontein · flame-grilled chesanyama</p>
          </div>
          <h1 data-hero-line className="display-title mt-6">
            Food with
            <span className="block text-orange">proper fire.</span>
          </h1>
          <p data-hero-line className="mt-6 max-w-xl text-base leading-8 text-smoke sm:text-lg">
            Pap, wors, liver and meat off the grill, the way King Edward Road knows it.
            Order online, choose pickup or delivery, and follow your order as it cooks.
          </p>

          <div data-hero-line className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center">
            <Link href="/menu/" className="button button-primary">
              <Flame size={19} aria-hidden="true" />
              Order now
            </Link>
            <a href={siteConfig.whatsappUrl} target="_blank" rel="noreferrer" className="button button-ghost">
              <MessageCircle size={19} aria-hidden="true" />
              Chat on WhatsApp
            </a>
          </div>

          <div data-hero-line className="mt-8">
            <OpenBadge settings={settings} />
          </div>
        </div>

        <div className="relative order-1 mx-auto w-full max-w-[22rem] [perspective:1200px] sm:max-w-[30rem] lg:order-none lg:col-start-2 lg:row-start-1 lg:max-w-[36rem] lg:self-end">
          {sidePlates.slice(0, 2).map((plate, index) => (
            <div
              key={plate.photo}
              aria-hidden="true"
              className={`absolute w-[38%] ${index === 0 ? "-left-[6%] top-[4%] -rotate-12" : "-right-[4%] bottom-[10%] rotate-12"} opacity-80`}
            >
              <div data-side-plate>
                {plate.cutout ? (
                  <Image src={plate.cutout} alt="" width={420} height={420} sizes="(min-width: 1024px) 220px, 34vw" className="plate h-auto w-full" />
                ) : null}
              </div>
            </div>
          ))}

          <div ref={mainRef} className="relative mx-auto w-[82%] [transform-style:preserve-3d]">
            <div className="plate-halo" aria-hidden="true" />
            <div data-turn>
              {special?.cutout ? (
                <Image
                  src={special.cutout}
                  alt={special.title}
                  width={900}
                  height={900}
                  priority
                  sizes="(min-width: 1024px) 480px, 80vw"
                  className="plate h-auto w-full"
                />
              ) : special ? (
                <Image
                  src={special.photo}
                  alt={special.title}
                  width={900}
                  height={900}
                  priority
                  sizes="(min-width: 1024px) 480px, 80vw"
                  className="plate aspect-square h-auto w-full rounded-full object-cover"
                />
              ) : (
                <Image src="/brand/flame-mark.png" alt="RastasperiQ flame" width={512} height={512} priority className="plate mx-auto h-auto w-3/4" />
              )}
            </div>
          </div>
        </div>

        {special && (
          <div data-hero-line className="relative z-10 order-3 mx-auto w-full max-w-md lg:order-none lg:col-start-2 lg:row-start-2 lg:-mt-10 lg:self-start rounded-2xl border border-white/10 bg-charcoal/85 p-5 shadow-2xl backdrop-blur-xl">
            <p className="flex items-center gap-2 text-[0.7rem] font-black uppercase tracking-[0.18em] text-orange">
              <Flame size={14} aria-hidden="true" />
              {special.label}
            </p>
            <p className="mt-2 font-display text-2xl font-extrabold uppercase leading-[1.02] text-cream">{special.title}</p>
            {special.subtitle && <p className="mt-2 text-sm leading-6 text-smoke">{special.subtitle}</p>}
            <Link href={orderHref} className="mt-4 inline-flex min-h-11 items-center gap-2 text-sm font-extrabold text-orange hover:text-cream">
              {special.id ? "Order this plate" : "See the menu"}
              <ArrowRight size={16} aria-hidden="true" />
            </Link>
          </div>
        )}
      </div>
    </section>
  );
}
