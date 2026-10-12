"use client";
// Website anonymous auth helper — mirrors mobile AppController anonymous guest flow.
// Does NOT require email; anonymous auth keeps ordering simple and shares Supabase identity.

import { createBrowserClient } from "./supabase";

export async function ensureAnonSession(): Promise<{ userId: string; accessToken: string | null } | null> {
  try {
    const supa = createBrowserClient();
    const { data: sess } = await supa.auth.getSession();
    if (sess.session?.user) {
      return { userId: sess.session.user.id, accessToken: sess.session.access_token ?? null };
    }
    // No session — try anonymous sign-in (requires Supabase Auth: Anonymous enabled)
    const { data, error } = await supa.auth.signInAnonymously();
    if (error || !data.user) {
      // Fallback: try to get anon from supabase without signing in? Some projects disable anon.
      // Return null; order creation will error and UI can show friendly message.
      return null;
    }
    // Ensure session
    const { data: newSess } = await supa.auth.getSession();
    return { userId: data.user.id, accessToken: newSess.session?.access_token ?? null };
  } catch {
    return null;
  }
}
