// Server-only rate limiting backed by the shared Supabase database, so limits
// hold across serverless instances. Never import into client components.

import crypto from "crypto";
import type { SupabaseClient } from "@supabase/supabase-js";

export type RateLimit = { bucket: string; limit: number; windowSeconds: number };

// Card checkout: a customer normally starts one checkout and may retry a few
// times. The IP limit is generous because mobile networks share addresses.
export const CHECKOUT_LIMITS = {
  perIp: { limit: 60, windowSeconds: 600 },
  perUser: { limit: 10, windowSeconds: 600 },
} as const;

/** The caller's IP from Vercel's proxy headers, or null when unknown. */
export function clientIp(req: Request): string | null {
  const forwarded = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  return req.headers.get("x-real-ip")?.trim() || forwarded || null;
}

/**
 * A bucket name for an IP that cannot be reversed into the address. The key
 * is a server secret, so a plain hash of every IPv4 address cannot undo it.
 */
export function ipBucket(prefix: string, ip: string, secret: string): string {
  const digest = crypto.createHmac("sha256", secret).update(ip).digest("hex").slice(0, 32);
  return `${prefix}:ip:${digest}`;
}

/**
 * Counts one request against the limit. Returns false only when the limit is
 * exceeded. If the limiter itself fails, the request is allowed: payments must
 * not stop because a defence-in-depth check is unavailable.
 */
export async function allowRequest(svc: SupabaseClient, { bucket, limit, windowSeconds }: RateLimit): Promise<boolean> {
  try {
    const { data, error } = await svc.rpc("consume_rate_limit", {
      p_bucket: bucket, p_limit: limit, p_window_seconds: windowSeconds,
    });
    if (error) throw error;
    return data !== false;
  } catch {
    console.error("Rate limiter unavailable", { bucket: bucket.split(":").slice(0, 2).join(":") });
    return true;
  }
}
