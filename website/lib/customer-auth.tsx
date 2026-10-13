"use client";

import { createContext, useContext, useEffect, useRef, useState } from "react";
import type { User } from "@supabase/supabase-js";
import { createBrowserClient, isSupabaseConfigured } from "./supabase";
import { fetchCustomerProfile, type CustomerProfile } from "./customer-account";

type AccountContext = {
  user: User | null; profile: CustomerProfile | null; loading: boolean;
  profileError: string | null; refreshProfile: () => Promise<void>;
};
const CustomerAuth = createContext<AccountContext | null>(null);

export function CustomerAuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<CustomerProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [profileError, setProfileError] = useState<string | null>(null);
  const revision = useRef(0);
  const identity = useRef<string | null>(null);

  useEffect(() => {
    if (!isSupabaseConfigured()) { setLoading(false); return; }
    const supa = createBrowserClient();
    let active = true;
    const load = async (nextUser: User | null) => {
      const current = ++revision.current;
      setUser(nextUser);
      const nextId = nextUser?.id ?? null;
      if (identity.current !== nextId) setProfile(null);
      identity.current = nextId;
      setProfileError(null);
      try {
        const nextProfile = nextUser && !nextUser.is_anonymous ? await fetchCustomerProfile(nextUser.id) : null;
        if (active && current === revision.current) setProfile(nextProfile);
      } catch {
        if (active && current === revision.current) setProfileError("Could not load your details. Try refreshing your profile.");
      } finally {
        if (active && current === revision.current) setLoading(false);
      }
    };
    const { data: { subscription } } = supa.auth.onAuthStateChange((_event, session) => {
      // Auth callbacks must return before another Supabase request starts.
      queueMicrotask(() => { if (active) void load(session?.user ?? null); });
    });
    const initial = revision.current;
    void supa.auth.getSession().then(({ data }) => {
      if (active && revision.current === initial) void load(data.session?.user ?? null);
    }).catch(() => { if (active) setLoading(false); });
    return () => { active = false; subscription.unsubscribe(); };
  }, []);

  const refreshProfile = async () => {
    if (!user || user.is_anonymous) return;
    const current = ++revision.current;
    const nextProfile = await fetchCustomerProfile(user.id);
    if (current === revision.current) { setProfile(nextProfile); setProfileError(null); }
  };
  return <CustomerAuth.Provider value={{ user, profile, loading, profileError, refreshProfile }}>{children}</CustomerAuth.Provider>;
}

export function useCustomerAuth() {
  const value = useContext(CustomerAuth);
  if (!value) throw new Error("CustomerAuthProvider is missing.");
  return value;
}
