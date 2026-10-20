// Shared Yoco helpers — used only on server (app/api/*). Never import into client components.

import crypto from "crypto";

export type YocoEnv = {
  secretKey: string; // sk_test_... or sk_live_...
  webhookSecret: string; // whsec_...
};

export function readYocoEnv(): YocoEnv | null {
  const secretKey = (process.env.YOCO_SECRET_KEY ?? "").trim();
  const webhookSecret = (process.env.YOCO_WEBHOOK_SECRET ?? "").trim();
  if (!secretKey || !webhookSecret) return null;
  if (!secretKey.startsWith("sk_test_") && !secretKey.startsWith("sk_live_")) return null;
  if (!webhookSecret.startsWith("whsec_")) return null;
  return { secretKey, webhookSecret };
}

export function getSiteUrl(): string {
  const url =
    (process.env.NEXT_PUBLIC_SITE_URL ?? process.env.SITE_URL ?? "https://rastasperiq.co.za").trim();
  try {
    const u = new URL(url);
    if (u.protocol !== "https:" && u.protocol !== "http:") throw new Error();
    return u.origin;
  } catch {
    return "https://rastasperiq.co.za";
  }
}

/**
 * Verify Yoco Standard Webhooks signature.
 * Signed content = `${webhook-id}.${webhook-timestamp}.${rawBody}`
 * Secret = base64Decode(whsec_... without prefix)
 * Signature = base64( HMAC_SHA256(secret, signedContent) )
 * Header `webhook-signature` may contain multiple `v1,<sig>` space-separated; at least one must match.
 * Timestamp must be within 5 minutes to prevent replay.
 */
export function verifyYocoWebhook({
  rawBody,
  headers,
  secret,
}: {
  rawBody: string;
  headers: { webhookId: string | null; webhookTimestamp: string | null; webhookSignature: string | null };
  secret: string; // whsec_...
}): { ok: boolean; reason?: string } {
  const { webhookId, webhookTimestamp, webhookSignature } = headers;
  if (!webhookId || !webhookTimestamp || !webhookSignature) {
    return { ok: false, reason: "Missing webhook headers" };
  }
  const ts = Number(webhookTimestamp);
  if (!Number.isFinite(ts)) return { ok: false, reason: "Invalid webhook-timestamp" };
  const now = Math.floor(Date.now() / 1000);
  // 5 min window (Yoco docs recommend 3; allow 5 for retries)
  if (Math.abs(now - ts) > 300) return { ok: false, reason: "Timestamp outside tolerance (replay?)" };

  let key: Buffer;
  try {
    const b64 = secret.replace(/^whsec_/, "");
    key = Buffer.from(b64, "base64");
    if (key.length === 0) throw new Error();
  } catch {
    return { ok: false, reason: "Invalid webhook secret format" };
  }

  const signedContent = `${webhookId}.${webhookTimestamp}.${rawBody}`;
  const expected = crypto.createHmac("sha256", key).update(signedContent, "utf8").digest("base64");

  // header format: "v1,abc123 v1,def456 v2,..." — we only verify v1
  const candidates = webhookSignature
    .split(/\s+/)
    .map((s) => s.trim())
    .filter(Boolean)
    .filter((s) => s.startsWith("v1,"))
    .map((s) => s.slice(3))
    .filter(Boolean);

  let matched = false;
  for (const sig of candidates) {
    // constant-time compare
    const a = Buffer.from(expected);
    const b = Buffer.from(sig);
    if (a.length !== b.length) continue;
    try {
      if (crypto.timingSafeEqual(a, b)) {
        matched = true;
        break;
      }
    } catch {
      // timingSafeEqual throws if lengths differ (handled)
    }
  }
  if (!matched) return { ok: false, reason: "Signature mismatch" };
  return { ok: true };
}

