"use client";

import { ArrowRight, Download, ExternalLink, Smartphone, Store } from "lucide-react";
import Image from "next/image";
import { useEffect, useState, useSyncExternalStore } from "react";
import { siteConfig } from "@/lib/site";

// "checking" is the only value the static export can render, because the
// server has no User-Agent to look at.
type Device = "checking" | "android" | "other";

// How long to wait before assuming the market:// navigation was swallowed.
// Custom schemes are silently dropped by some in-app browsers (Instagram,
// WhatsApp, Facebook), so we show a tappable fallback instead of hanging.
const REDIRECT_TIMEOUT_MS = 2000;

const noSubscriptions = () => () => {};
const detectDevice = (): Device =>
  /android/i.test(navigator.userAgent) ? "android" : "other";
const serverDevice = (): Device => "checking";

export function GetAppPanel() {
  // React uses the server snapshot during hydration, so the pre-rendered HTML
  // matches, then re-renders once with the real device.
  const device = useSyncExternalStore(noSubscriptions, detectDevice, serverDevice);
  const [needsTap, setNeedsTap] = useState(false);

  useEffect(() => {
    if (device !== "android") return;

    const timer = window.setTimeout(() => {
      // Still visible means the Play Store never took over.
      if (!document.hidden) setNeedsTap(true);
    }, REDIRECT_TIMEOUT_MS);

    window.location.replace(siteConfig.app.marketUrl);

    return () => window.clearTimeout(timer);
  }, [device]);

  const state: Device | "needs-tap" =
    device === "android" && needsTap ? "needs-tap" : device;

  return (
    <aside className="lg:pt-12">
      <div className="rounded-[2rem] bg-muted p-6 sm:p-8">
        <div className="grid place-items-center" aria-live="polite">
          {state === "checking" && (
            <div className="grid w-full place-items-center py-16 text-center">
              <span
                className="size-9 animate-spin rounded-full border-[3px] border-black/10 border-t-peri-red"
                aria-hidden="true"
              />
              <p className="mt-5 text-sm font-bold text-ash">Checking your device…</p>
            </div>
          )}

          {state === "android" && (
            <div className="grid w-full place-items-center py-16 text-center">
              <span
                className="size-9 animate-spin rounded-full border-[3px] border-black/10 border-t-peri-red"
                aria-hidden="true"
              />
              <p className="mt-5 font-display text-2xl font-black uppercase tracking-[-0.03em]">
                Opening Play Store…
              </p>
              <p className="mt-3 max-w-xs text-sm leading-7 text-ash">
                If the Play Store does not open, a button appears here to tap
                instead.
              </p>
            </div>
          )}

          {(state === "needs-tap" || state === "other") && (
            <div className="w-full text-center">
              <Image
                src="/qr/rastasperiq-get-app-qr-square.png"
                alt="QR code that opens the RastasperiQ app page"
                width={1200}
                height={1200}
                className="mx-auto w-full max-w-[19rem] rounded-2xl"
              />
              <p className="mt-5 font-display text-2xl font-black uppercase leading-none tracking-[-0.04em]">
                {state === "needs-tap" ? "Tap to continue" : "Scan to install"}
              </p>
              <p className="mt-3 text-sm leading-7 text-ash">
                {state === "needs-tap"
                  ? "Your browser blocked the automatic redirect. One tap opens the RastasperiQ listing in the Play Store app."
                  : "Point your phone's camera at this code. On Android it opens the Play Store app and installs RastasperiQ."}
              </p>
            </div>
          )}
        </div>

        {state === "needs-tap" && (
          <div className="mt-6 grid gap-3">
            <a href={siteConfig.app.marketUrl} className="button button-primary w-full">
              <Store size={18} aria-hidden="true" />
              Open in Play Store
            </a>
            <a
              href={siteConfig.app.playStoreUrl}
              target="_blank"
              rel="noreferrer"
              className="button button-dark w-full"
            >
              <ExternalLink size={18} aria-hidden="true" />
              Open Play Store website
            </a>
          </div>
        )}

        {state === "other" && (
          <div className="mt-6 grid gap-3">
            <a
              href={siteConfig.app.playStoreUrl}
              target="_blank"
              rel="noreferrer"
              className="button button-primary w-full"
            >
              <Smartphone size={18} aria-hidden="true" />
              View on Google Play
            </a>
            <a
              href="/qr/get-app-qr.svg"
              download="rastasperiq-get-app-qr.svg"
              className="button button-dark w-full"
            >
              <Download size={18} aria-hidden="true" />
              Download QR to print
            </a>
          </div>
        )}

        {state === "other" && (
          <p className="mt-5 text-center text-xs leading-6 text-ash">
            RastasperiQ is on Android. On an iPhone, this page stays open so you can
            scan the code with an Android phone.
          </p>
        )}
      </div>

      {state === "other" && (
        <p className="mt-5 text-center text-sm text-ash">
          Already have the app?{" "}
          <a
            href={`${siteConfig.url}/#how-it-works`}
            className="font-extrabold text-peri-red underline"
          >
            See how ordering works
          </a>{" "}
          <ArrowRight className="inline" size={15} aria-hidden="true" />
        </p>
      )}
    </aside>
  );
}
