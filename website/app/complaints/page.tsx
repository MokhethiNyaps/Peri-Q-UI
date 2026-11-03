import type { Metadata } from "next";
import Link from "next/link";
import { MessageSquareWarning } from "lucide-react";
import { LegalPage, Pending } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Complaints Procedure",
  description: "How to raise a complaint with RastasperiQ and where to escalate it.",
  alternates: { canonical: "/complaints/" },
};

export default function ComplaintsPage() {
  return (
    <LegalPage
      title="Complaints"
      href="/complaints/"
      icon={MessageSquareWarning}
      intro="How to tell us when something went wrong, how we respond, and where you can go if we cannot resolve it."
    >
      <h2>1. Tell us</h2>
      <p>Contact us by phone, WhatsApp or email (details below) with:</p>
      <ul>
        <li>your order number and the name on the order;</li>
        <li>what went wrong; and</li>
        <li>a photo, if the complaint is about the food or packaging.</li>
      </ul>
      <p>For food problems, please contact us on the day of the order so we can look into it while the details are fresh.</p>

      <h2>2. How we respond</h2>
      <ul>
        <li>We acknowledge your complaint within <Pending>number of business days</Pending>.</li>
        <li>We aim to resolve it within <Pending>number of business days</Pending>, and tell you if it will take longer.</li>
        <li>
          Depending on the problem, we may offer a replacement, a refund under our{" "}
          <Link href="/refund-policy/">refund policy</Link>, or another fair solution.
        </li>
        <li>Complaints are handled by <Pending>role or name of the person who handles complaints</Pending>.</li>
      </ul>

      <h2>3. If you are not satisfied</h2>
      <p>You can escalate an unresolved complaint to:</p>
      <ul>
        <li>
          <strong>Consumer Goods and Services Ombud (CGSO)</strong> for complaints about goods and
          services:{" "}
          <a href="https://www.cgso.org.za" target="_blank" rel="noreferrer">cgso.org.za</a>
        </li>
        <li>
          <strong>National Consumer Commission</strong>:{" "}
          <a href="https://thencc.org.za" target="_blank" rel="noreferrer">thencc.org.za</a>
        </li>
        <li>
          <strong>Information Regulator</strong> for complaints about your personal information:{" "}
          <a href="https://inforegulator.org.za" target="_blank" rel="noreferrer">inforegulator.org.za</a>
        </li>
      </ul>
      <p>
        <Pending>attorney to confirm the correct escalation bodies and order for a restaurant</Pending>
      </p>
    </LegalPage>
  );
}
