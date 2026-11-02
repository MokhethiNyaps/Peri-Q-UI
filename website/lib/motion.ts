"use client";

import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

let registered = false;

/** GSAP with ScrollTrigger, registered once, browser only. */
export function getGsap() {
  if (!registered && typeof window !== "undefined") {
    gsap.registerPlugin(ScrollTrigger);
    registered = true;
  }
  return { gsap, ScrollTrigger };
}

export function prefersReducedMotion(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return true;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

export function canHover(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  return window.matchMedia("(hover: hover) and (pointer: fine)").matches;
}

/**
 * Send a small ember from the button that was pressed to the visible cart
 * button. Decorative only: the cart has already been updated, and the result
 * is announced to screen readers separately.
 */
export function flyToCart(from: Element | null) {
  if (!from || prefersReducedMotion()) return;
  const targets = Array.from(document.querySelectorAll<HTMLElement>("[data-cart-target]"));
  const target = targets.find((el) => el.offsetParent !== null);
  if (!target) return;

  const start = from.getBoundingClientRect();
  const end = target.getBoundingClientRect();
  const spark = document.createElement("div");
  spark.className = "cart-spark";
  spark.setAttribute("aria-hidden", "true");
  document.body.appendChild(spark);

  const x0 = start.left + start.width / 2 - 7;
  const y0 = start.top + start.height / 2 - 7;
  const dx = end.left + end.width / 2 - 7 - x0;
  const dy = end.top + end.height / 2 - 7 - y0;
  const { gsap: g } = getGsap();

  g.set(spark, { x: x0, y: y0, scale: 1 });
  const progress = { t: 0 };
  g.to(progress, {
    t: 1,
    duration: 0.7,
    ease: "power2.in",
    onUpdate: () => {
      const t = progress.t;
      // A simple arc: straight across, lifted in the middle.
      const lift = Math.sin(Math.PI * t) * -120;
      g.set(spark, { x: x0 + dx * t, y: y0 + dy * t + lift, scale: 1 - t * 0.5 });
    },
    onComplete: () => spark.remove(),
  });
}
