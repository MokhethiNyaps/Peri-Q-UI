"use client";
import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { completeAuthCallback } from "@/lib/customer-account";

export default function CallbackClient() {
  const [error, setError] = useState<string | null>(null);
  const request = useRef<Promise<boolean> | null>(null);
  useEffect(() => {
    let active = true;
    if (!request.current) {
      const url = window.location.href;
      window.history.replaceState(null, "", "/auth/callback/");
      request.current = completeAuthCallback(url);
    }
    void request.current.then((recovery) => {
      if (active) window.location.replace(recovery ? "/account/?mode=password" : "/account/");
    }).catch(() => { if (active) setError("This link is invalid or has expired. Return to sign in and request a new link."); });
    return () => { active = false; };
  }, []);
  return <main id="main-content" className="site-shell py-16">
    <h1 className="font-display text-3xl font-bold uppercase">{error ? "Could not confirm your account" : "Confirming your account"}</h1>
    <p role={error ? "alert" : "status"} className="mt-4 max-w-lg">{error ?? "Please wait while we check your sign-in link…"}</p>
    {error && <Link href="/account/" className="button button-primary mt-6">Back to sign in</Link>}
  </main>;
}
