import { createClient as createSupabaseClient, type SupabaseClient } from "@supabase/supabase-js";

// Public client — safe for browser. Uses publishable key only.
export function readPublicSupabaseConfig(): { url: string; publishableKey: string } | null {
  const url = (process.env.NEXT_PUBLIC_SUPABASE_URL ?? "").trim();
  const publishableKey = (process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? "").trim();
  if (!url || !publishableKey) return null;
  try {
    const u = new URL(url);
    if (u.protocol !== "https:" || u.username || u.password) return null;
  } catch {
    return null;
  }
  return { url, publishableKey };
}

export function isSupabaseConfigured() {
  return readPublicSupabaseConfig() !== null;
}

let browserClient: SupabaseClient | undefined;

// Share one auth session and refresh loop across menu, checkout, and order screens.
export function createBrowserClient() {
  if (browserClient) return browserClient;
  const config = readPublicSupabaseConfig();
  if (!config) throw new Error("Supabase is not configured. Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY.");
  browserClient = createSupabaseClient(config.url, config.publishableKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: false,
    },
  });
  return browserClient;
}

// Server-side: webhooks & checkout verification using service_role (never expose to browser)
export function readServerSupabaseConfig(): { url: string; serviceRoleKey: string } | null {
  // Prefer SUPABASE_URL / SERVICE_ROLE (server) fallback to NEXT_PUBLIC_* for preview
  const url = (process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL ?? "").trim();
  const serviceRoleKey = (process.env.SUPABASE_SERVICE_ROLE_KEY ?? "").trim();
  if (!url || !serviceRoleKey) return null;
  try {
    const u = new URL(url);
    if (u.protocol !== "https:" || u.username || u.password) return null;
  } catch {
    return null;
  }
  return { url, serviceRoleKey };
}

export function createServiceClient() {
  const cfg = readServerSupabaseConfig();
  if (!cfg) throw new Error("Missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY server env.");
  return createSupabaseClient(cfg.url, cfg.serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
