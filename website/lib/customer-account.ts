import { createBrowserClient } from "./supabase";

export type CustomerProfile = { id: string; full_name: string | null; phone: string | null };

export async function fetchCustomerProfile(userId: string): Promise<CustomerProfile | null> {
  const { data, error } = await createBrowserClient().from("profiles")
    .select("id,full_name,phone").eq("id", userId).maybeSingle();
  if (error) throw error;
  return data as CustomerProfile | null;
}

export function validateProfile(name: string, phone: string) {
  const fullName = name.trim();
  const cleanedPhone = phone.trim().replace(/[\s()-]/g, "");
  if (fullName.length < 2 || fullName.length > 100) throw new Error("Enter a name between 2 and 100 characters.");
  if (!/^\+?\d{7,15}$/.test(cleanedPhone)) throw new Error("Enter a valid phone number.");
  return { full_name: fullName, phone: /^0\d{9}$/.test(cleanedPhone) ? `+27${cleanedPhone.slice(1)}` : cleanedPhone };
}

export async function saveCustomerProfile(name: string, phone: string) {
  const fields = validateProfile(name, phone);
  const supa = createBrowserClient();
  const { data: { user }, error: authError } = await supa.auth.getUser();
  if (authError || !user || user.is_anonymous) throw new Error("Sign in to save your profile.");
  const { error } = await supa.from("profiles").upsert({ id: user.id, email: user.email, ...fields });
  if (error) throw error;
}

export async function registerCustomer(email: string, password: string, name: string, phone: string) {
  const fields = validateProfile(name, phone);
  if (password.length < 8) throw new Error("Use a password with at least 8 characters.");
  const { data, error } = await createBrowserClient().auth.signUp({
    email: email.trim(), password,
    options: { data: fields, emailRedirectTo: `${window.location.origin}/auth/callback/` },
  });
  if (error) throw error;
  return data;
}

export async function signInCustomer(email: string, password: string) {
  const { error } = await createBrowserClient().auth.signInWithPassword({ email: email.trim(), password });
  if (error) throw error;
}

export async function signOutCustomer() {
  const { error } = await createBrowserClient().auth.signOut({ scope: "local" });
  if (error) throw error;
  localStorage.removeItem("peri_q_customer_v1");
}

export async function requestPasswordReset(email: string) {
  const { error } = await createBrowserClient().auth.resetPasswordForEmail(email.trim(), {
    redirectTo: `${window.location.origin}/auth/callback/?recovery=1`,
  });
  if (error) throw error;
}

export async function setCustomerPassword(password: string) {
  if (password.length < 8) throw new Error("Use a password with at least 8 characters.");
  const { error } = await createBrowserClient().auth.updateUser({ password });
  if (error) throw error;
}

export async function completeAuthCallback(url: string): Promise<boolean> {
  const parsed = new URL(url);
  const hash = new URLSearchParams(parsed.hash.slice(1));
  if (parsed.searchParams.has("error") || hash.has("error")) throw new Error("This link is invalid or has expired. Request a new one.");
  const supa = createBrowserClient();
  const code = parsed.searchParams.get("code");
  if (code) {
    const { error } = await supa.auth.exchangeCodeForSession(code);
    if (error) throw error;
  } else {
    const access = hash.get("access_token");
    const refresh = hash.get("refresh_token");
    if (!access || !refresh) throw new Error("This link is incomplete. Request a new one.");
    const { error } = await supa.auth.setSession({ access_token: access, refresh_token: refresh });
    if (error) throw error;
  }
  return parsed.searchParams.get("recovery") === "1" || hash.get("type") === "recovery";
}
