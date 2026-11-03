import { createBrowserClient } from "./supabase";
import { signupAcceptanceMetadata } from "./policy-consent";

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
    options: { data: { ...fields, ...signupAcceptanceMetadata }, emailRedirectTo: `${window.location.origin}/auth/callback/` },
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

export type PrivacyRequestType = "access" | "correction" | "deletion" | "objection" | "other";
export type PrivacyRequest = { id: string; request_type: PrivacyRequestType; details: string; status: string; created_at: string; resolved_at: string | null };

export async function fetchPrivacyRequests(): Promise<PrivacyRequest[]> {
  const { data, error } = await createBrowserClient().from("privacy_requests")
    .select("id,request_type,details,status,created_at,resolved_at").order("created_at", { ascending: false }).limit(20);
  if (error) throw error;
  return (data ?? []) as PrivacyRequest[];
}

export async function submitPrivacyRequest(type: PrivacyRequestType, details: string) {
  const text = details.trim();
  if (!text) throw new Error("Tell us what you need help with.");
  if (text.length > 2000) throw new Error("Keep your request under 2,000 characters.");
  const { error } = await createBrowserClient().rpc("submit_privacy_request", { p_request_type: type, p_details: text });
  if (error) throw new Error(error.message.includes("three open") ? "You already have three open privacy requests. We will reply to those first." : "Could not send your request. Please try again.");
}

/** Everything the database holds for the signed-in customer, as a downloadable copy (POPIA section 23). */
export async function exportMyData(userId: string) {
  const supa = createBrowserClient();
  // Every read is filtered to this customer: an admin's own export must not
  // include other customers' rows, which admins are allowed to see.
  const read = async (table: string, columns: string, column: string, values: string[]) => {
    if (!values.length) return [];
    const { data, error } = await supa.from(table).select(columns).in(column, values);
    if (error) throw new Error("Could not prepare your data. Please try again.");
    return (data ?? []) as unknown as Record<string, unknown>[];
  };
  const [profile, orders, acceptances, requests] = await Promise.all([
    read("profiles", "id,email,full_name,phone,created_at,updated_at", "id", [userId]),
    read("orders", "id,order_number,created_at,status,order_type,customer_name,customer_phone,delivery_address,total_price,payment_status,paid_at,order_items(item_name,quantity,unit_price,spice_level,notes,selected_add_ons)", "user_id", [userId]),
    read("policy_acceptances", "documents,version,context,client,accepted_at", "user_id", [userId]),
    read("privacy_requests", "request_type,details,status,created_at,resolved_at", "user_id", [userId]),
  ]);
  const orderIds = orders.map((order) => String(order.id));
  const [payments, refunds] = await Promise.all([
    read("payments", "order_id,amount_cents,currency,status,refunded_amount_cents,created_at", "order_id", orderIds),
    read("payment_refunds", "order_id,amount_cents,currency,created_at", "order_id", orderIds),
  ]);
  return { exported_at: new Date().toISOString(), profile: profile[0] ?? null, orders, payments, refunds, policy_acceptances: acceptances, privacy_requests: requests };
}

/**
 * Deletes the signed-in customer's account. Past orders are kept by the
 * database as anonymised financial records; everything else is removed.
 */
export async function deleteMyAccount() {
  const supa = createBrowserClient();
  const { error } = await supa.rpc("delete_own_account");
  if (error) throw new Error("Could not delete your account. Please try again or contact us.");
  // The session belongs to an account that no longer exists.
  await supa.auth.signOut({ scope: "local" }).catch(() => undefined);
  localStorage.removeItem("peri_q_customer_v1");
}
