import type { Metadata } from "next";
import AccountClient from "./account-client";

export const metadata: Metadata = { title: "My account", robots: { index: false, follow: false } };
export default function AccountPage() { return <AccountClient />; }
