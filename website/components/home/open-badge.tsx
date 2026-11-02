"use client";

import { useEffect, useState } from "react";
import { isStoreOpenNow, type AppSettings } from "@/lib/menu";

/** Live open/closed badge. Computed in the browser so a cached page never shows stale hours. */
export function OpenBadge({ settings }: { settings: AppSettings | null }) {
  const [open, setOpen] = useState<boolean | null>(null);

  useEffect(() => {
    if (!settings) return;
    const update = () => setOpen(isStoreOpenNow(settings));
    update();
    const timer = setInterval(update, 60_000);
    return () => clearInterval(timer);
  }, [settings]);

  if (!settings || open === null) return null;

  return (
    <span
      className={`inline-flex min-h-9 items-center gap-2 rounded-full px-3.5 text-xs font-extrabold ${
        open ? "bg-leaf/90 text-white" : "border border-white/15 bg-white/6 text-smoke"
      }`}
    >
      <span className={`size-2 rounded-full ${open ? "bg-[#7ee2a1]" : "bg-smoke"}`} aria-hidden="true" />
      {open ? `Open now · until ${settings.closingTime}` : `Closed · opens ${settings.openingTime}`}
    </span>
  );
}
