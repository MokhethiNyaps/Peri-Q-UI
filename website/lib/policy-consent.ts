import { createBrowserClient } from "./supabase";

/**
 * Version of the terms and privacy policy a customer accepts. Change it when
 * either document changes, so every acceptance record shows which text the
 * customer agreed to. The Android app sends the same value.
 */
export const POLICY_VERSION = "2026-11-03-draft";

/** Metadata stored on a new account; the database turns it into a signup acceptance record. */
export const signupAcceptanceMetadata = { policy_version: POLICY_VERSION, policy_client: "website" } as const;

/** Records that the customer accepted the policies for this checkout. */
export async function recordCheckoutAcceptance(checkoutId: string) {
  const { error } = await createBrowserClient().rpc("record_policy_acceptance", {
    p_version: POLICY_VERSION, p_context: "checkout", p_client: "website", p_checkout_id: checkoutId,
  });
  if (error) throw new Error("Could not record your acceptance of our terms. Please try again; your cart is saved.");
}
