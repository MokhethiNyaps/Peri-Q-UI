"use client";

import { useEffect, useState, type FormEvent } from "react";
import Link from "next/link";
import { Download } from "lucide-react";
import { exportMyData, fetchPrivacyRequests, submitPrivacyRequest, type PrivacyRequest, type PrivacyRequestType } from "@/lib/customer-account";

const requestTypes: { value: PrivacyRequestType; label: string }[] = [
  { value: "access", label: "Tell me what information you hold about me" },
  { value: "correction", label: "Correct my information" },
  { value: "deletion", label: "Delete my information" },
  { value: "objection", label: "Object to how my information is used" },
  { value: "other", label: "Something else" },
];
const statusLabel: Record<string, string> = { received: "Received", in_progress: "In progress", completed: "Completed", declined: "Declined" };
const fieldClass = "mt-2 w-full rounded-xl border border-black/20 bg-white px-4 py-3 text-base focus:border-peri-red focus:outline-none focus:ring-2 focus:ring-peri-red/20";

/** Self-service POPIA rights for a signed-in customer: a copy of their data, and requests to us. */
export function PrivacyPanel({ userId }: { userId: string }) {
  const [requests, setRequests] = useState<PrivacyRequest[]>([]);
  const [type, setType] = useState<PrivacyRequestType>("access");
  const [details, setDetails] = useState("");
  const [busy, setBusy] = useState<"export" | "request" | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [revision, setRevision] = useState(0);

  useEffect(() => {
    let active = true;
    fetchPrivacyRequests().then((rows) => { if (active) setRequests(rows); }, () => { if (active) setRequests([]); });
    return () => { active = false; };
  }, [userId, revision]);

  const download = async () => {
    setBusy("export"); setError(null); setMessage(null);
    try {
      const data = await exportMyData(userId);
      const url = URL.createObjectURL(new Blob([JSON.stringify(data, null, 2)], { type: "application/json" }));
      const link = document.createElement("a");
      link.href = url;
      link.download = `rastasperiq-my-data-${new Date().toISOString().slice(0, 10)}.json`;
      link.click();
      URL.revokeObjectURL(url);
      setMessage("Your data has been downloaded.");
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Could not prepare your data. Please try again.");
    } finally {
      setBusy(null);
    }
  };

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setBusy("request"); setError(null); setMessage(null);
    try {
      await submitPrivacyRequest(type, details);
      setDetails("");
      setMessage("Your request has been sent. We will reply using your account email.");
      setRevision((value) => value + 1);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Could not send your request. Please try again.");
    } finally {
      setBusy(null);
    }
  };

  return (
    <section aria-labelledby="privacy-heading" className="mt-4 border border-black/10 bg-white p-6 sm:p-8">
      <h2 id="privacy-heading" className="font-display text-2xl font-bold uppercase">Your privacy</h2>
      <p className="mt-2 max-w-2xl text-sm leading-6 text-ash">
        You have the right to see, correct and delete your personal information, and to object to how it is used.
        Read our <Link href="/privacy-policy/" className="font-bold underline">privacy policy</Link>.
      </p>
      {error && <p role="alert" className="mt-4 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-900">{error}</p>}
      {message && <p role="status" className="mt-4 rounded-xl border border-leaf/20 bg-leaf/10 p-3 text-sm">{message}</p>}

      <div className="mt-6 grid gap-8 lg:grid-cols-2">
        <div>
          <h3 className="font-bold">Download your data</h3>
          <p className="mt-1 text-sm leading-6 text-ash">A copy of your profile, orders, payments, policy acceptances and privacy requests, as a file.</p>
          <button type="button" onClick={() => void download()} disabled={busy !== null} className="button button-dark mt-4 disabled:opacity-50">
            <Download size={16} aria-hidden="true" /> {busy === "export" ? "Preparing…" : "Download my data"}
          </button>
          <p className="mt-4 text-sm leading-6 text-ash">
            To delete your whole account, follow the <Link href="/delete-account/" className="font-bold underline">account deletion steps</Link>.
          </p>
        </div>

        <form onSubmit={submit} className="grid gap-4">
          <h3 className="font-bold">Make a privacy request</h3>
          <label className="text-sm font-bold">What do you need?
            <select className={fieldClass} value={type} onChange={(e) => setType(e.target.value as PrivacyRequestType)}>
              {requestTypes.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
            </select>
          </label>
          <label className="text-sm font-bold">Details
            <textarea className={fieldClass} rows={4} required maxLength={2000} value={details} onChange={(e) => setDetails(e.target.value)} placeholder="Tell us what you need, for example which details are wrong." />
          </label>
          <button disabled={busy !== null} className="button button-primary justify-center disabled:opacity-50">{busy === "request" ? "Sending…" : "Send request"}</button>
        </form>
      </div>

      {requests.length > 0 && <div className="mt-8">
        <h3 className="font-bold">Your requests</h3>
        <ul className="mt-3 divide-y divide-black/10 border-y border-black/10 text-sm">
          {requests.map((request) => <li key={request.id} className="flex flex-wrap justify-between gap-2 py-3">
            <span>{requestTypes.find((option) => option.value === request.request_type)?.label ?? request.request_type}
              <span className="block text-ash">{new Date(request.created_at).toLocaleDateString("en-ZA", { timeZone: "Africa/Johannesburg" })}</span></span>
            <span className="font-bold">{statusLabel[request.status] ?? request.status}</span>
          </li>)}
        </ul>
      </div>}
    </section>
  );
}
