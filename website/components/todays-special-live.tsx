"use client";

import { createClient } from "@supabase/supabase-js";
import { ArrowRight, Flame, RefreshCw } from "lucide-react";
import { useEffect, useState } from "react";
import { siteConfig } from "@/lib/site";

type Special = {
  enabled: boolean;
  label: string;
  title: string;
  subtitle: string;
  imageUrl: string;
};

type PublicSupabaseConfig = {
  url: string;
  publishableKey: string;
};

function readPublicSupabaseConfig(): PublicSupabaseConfig | null {
  const url = (process.env.NEXT_PUBLIC_SUPABASE_URL ?? "").trim();
  const publishableKey = (
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? ""
  ).trim();

  if (!url || !publishableKey) return null;

  try {
    const parsedUrl = new URL(url);
    if (
      parsedUrl.protocol !== "https:" ||
      parsedUrl.username ||
      parsedUrl.password
    ) {
      return null;
    }
  } catch {
    return null;
  }

  return { url, publishableKey };
}

const supabaseConfig = readPublicSupabaseConfig();
const isConfigured = supabaseConfig !== null;

function imageUrlFor(path: unknown) {
  const value = typeof path === "string" ? path.trim() : "";
  if (!value || value.startsWith("assets/images/")) return "/white-app-icon.png";
  return value.startsWith("https://") ? value : "/white-app-icon.png";
}

export function TodaysSpecialLive() {
  const [special, setSpecial] = useState<Special | null>(null);
  const [loading, setLoading] = useState(isConfigured);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    if (!supabaseConfig) return;

    let active = true;
    let removeRealtimeChannel: (() => void) | undefined;

    try {
      const supabase = createClient(
        supabaseConfig.url,
        supabaseConfig.publishableKey,
        {
          auth: {
            persistSession: false,
            autoRefreshToken: false,
            detectSessionInUrl: false,
          },
        },
      );

      const loadSpecial = async () => {
        try {
          const { data, error } = await supabase
            .from("app_settings")
            .select(
              "todays_special_enabled,todays_special_label,todays_special_title,todays_special_subtitle,todays_special_image_path",
            )
            .eq("id", "default")
            .maybeSingle();

          if (!active) return;
          if (error || !data) {
            setFailed(true);
            setLoading(false);
            return;
          }

          setSpecial({
            enabled: data.todays_special_enabled ?? true,
            label: data.todays_special_label || "TODAY'S SPECIAL",
            title: data.todays_special_title || "Fresh from the flame",
            subtitle:
              data.todays_special_subtitle || "Ask the team about today's plate.",
            imageUrl: imageUrlFor(data.todays_special_image_path),
          });
          setFailed(false);
          setLoading(false);
        } catch {
          if (!active) return;
          setFailed(true);
          setLoading(false);
        }
      };

      void loadSpecial();
      const channel = supabase
        .channel("website-todays-special")
        .on(
          "postgres_changes",
          {
            event: "UPDATE",
            schema: "public",
            table: "app_settings",
            filter: "id=eq.default",
          },
          () => void loadSpecial(),
        )
        .subscribe();

      removeRealtimeChannel = () => {
        void supabase.removeChannel(channel);
      };
    } catch {
      queueMicrotask(() => {
        if (!active) return;
        setFailed(true);
        setLoading(false);
      });
    }

    return () => {
      active = false;
      removeRealtimeChannel?.();
    };
  }, []);

  if (!isConfigured || (!loading && (!special?.enabled || failed))) return null;

  if (loading) {
    return (
      <section aria-label="Loading today's special" className="bg-cream py-8">
        <div className="site-shell h-72 animate-pulse rounded-[2.5rem] bg-muted" />
      </section>
    );
  }

  if (!special) return null;

  return (
    <section id="todays-special" className="section-pad bg-cream">
      <div className="site-shell overflow-hidden rounded-[2.5rem] bg-charcoal shadow-2xl">
        <div className="grid lg:grid-cols-[0.9fr_1.1fr]">
          <div className="relative min-h-72 overflow-hidden lg:min-h-[30rem]">
            {/* The image host is configured by the restaurant in Supabase. */}
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={special.imageUrl}
              alt={special.title}
              className="absolute inset-0 h-full w-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-charcoal/75 via-transparent to-transparent lg:bg-gradient-to-r" />
          </div>

          <div className="relative flex items-center overflow-hidden p-7 text-white sm:p-12 lg:p-16">
            <div className="absolute -right-24 -top-24 size-80 rounded-full bg-peri-red/25 blur-3xl" />
            <div className="relative max-w-xl">
              <p className="inline-flex items-center gap-2 rounded-full border border-orange/30 bg-orange/10 px-4 py-2 text-[0.7rem] font-black uppercase tracking-[0.18em] text-orange">
                <Flame size={15} aria-hidden="true" />
                {special.label}
              </p>
              <h2 className="mt-6 font-display text-5xl font-black uppercase leading-[0.88] tracking-[-0.05em] sm:text-7xl">
                {special.title}
              </h2>
              <p className="mt-6 max-w-lg text-base leading-8 text-white/65 sm:text-lg">
                {special.subtitle}
              </p>
              <a
                href={siteConfig.whatsappUrl}
                target="_blank"
                rel="noreferrer"
                className="button button-primary mt-8"
              >
                Ask about today&apos;s special
                <ArrowRight size={18} aria-hidden="true" />
              </a>
              <p className="mt-5 flex items-center gap-2 text-xs text-white/40">
                <RefreshCw size={14} aria-hidden="true" />
                Updates automatically from the restaurant app
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
