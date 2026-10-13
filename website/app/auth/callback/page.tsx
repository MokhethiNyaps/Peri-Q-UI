import type { Metadata } from "next";
import CallbackClient from "./callback-client";
export const metadata: Metadata = { title: "Confirm your account", robots: { index: false, follow: false } };
export default function CallbackPage() { return <CallbackClient />; }
