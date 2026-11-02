"use client";
import Link from "next/link";
import { useCustomerAuth } from "@/lib/customer-auth";

export function AccountLink({ mobile = false }: { mobile?: boolean }) {
  const { user } = useCustomerAuth();
  return <Link href="/account/" className={mobile ? "mobile-nav-link mobile-nav-link-dark" : "nav-link nav-link-dark"}>
    {user && !user.is_anonymous ? "My account" : "Sign in"}
  </Link>;
}
