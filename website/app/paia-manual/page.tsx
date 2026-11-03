import type { Metadata } from "next";
import Link from "next/link";
import { FileText } from "lucide-react";
import { BusinessDetails, Fact, LegalPage, Pending } from "@/components/legal-page";
import { business } from "@/lib/legal";

export const metadata: Metadata = {
  title: "PAIA Manual",
  description:
    "The Promotion of Access to Information Act manual of PERI Q CHISANYAMA (PTY) LTD, trading as RastasperiQ.",
  alternates: { canonical: "/paia-manual/" },
};

export default function PaiaManualPage() {
  return (
    <LegalPage
      title="PAIA manual"
      href="/paia-manual/"
      icon={FileText}
      intro={`The manual of ${business.legalName} under section 51 of the Promotion of Access to Information Act (PAIA): what records we keep and how to ask for them.`}
    >
      <p>
        <Pending>attorney to confirm whether the company must publish this manual now, or qualifies for
        an exemption for small private bodies</Pending>
      </p>

      <h2>1. Company details</h2>
      <BusinessDetails />

      <h2>2. Information Officer</h2>
      <p>
        Requests for records go to our Information Officer:{" "}
        <Fact value={business.informationOfficer} missing="name, email and phone of the Information Officer (and any Deputy Information Officers)" />
      </p>

      <h2>3. The Information Regulator&rsquo;s guide</h2>
      <p>
        The Information Regulator publishes a guide on how to use PAIA and POPIA, in the official languages.
        It is available from the Regulator at{" "}
        <a href="https://inforegulator.org.za" target="_blank" rel="noreferrer">inforegulator.org.za</a>.
      </p>

      <h2>4. Records available without a request</h2>
      <p>
        Our menu, prices, terms, privacy policy and other policies are published on this website and can be
        read without a formal request.
      </p>

      <h2>5. Records kept under other laws</h2>
      <p>
        We keep records as required by laws that apply to us, which may include the Companies Act, the Tax
        Administration Act, the Income Tax Act, the Consumer Protection Act, the Electronic Communications
        and Transactions Act, POPIA, and employment laws.{" "}
        <Pending>attorney to confirm the complete list</Pending>
      </p>

      <h2>6. Categories of records we hold</h2>
      <ul>
        <li><strong>Company records:</strong> registration documents, statutory registers and minutes.</li>
        <li><strong>Financial records:</strong> accounting records, invoices, payment and refund records, and tax records.</li>
        <li><strong>Customer records:</strong> accounts, orders, delivery details, payment references, and correspondence.</li>
        <li><strong>Supplier and service-provider records:</strong> agreements and correspondence.</li>
        <li><strong>Employee records:</strong> <Pending>whether the company has employees, and the records kept</Pending></li>
      </ul>

      <h2>7. How we process personal information</h2>
      <ul>
        <li><strong>Purpose:</strong> to take, prepare, deliver and support food orders, take payments and handle refunds, run customer accounts, and meet legal obligations.</li>
        <li><strong>People whose information we process:</strong> customers, people who contact us, suppliers, and staff.</li>
        <li><strong>Information:</strong> as described in our <Link href="/privacy-policy/">privacy policy</Link>.</li>
        <li><strong>Recipients:</strong> our staff, delivery personnel, and the service providers listed in our privacy policy.</li>
        <li><strong>Cross-border transfers:</strong> our database is hosted in Ireland, and some providers process information in other countries.</li>
        <li><strong>Security measures:</strong> encrypted connections, access controls on our database, and verification of payment notifications, as described in our privacy policy.</li>
      </ul>

      <h2>8. How to request a record</h2>
      <ol className="mt-4 grid list-decimal gap-2 pl-5">
        <li>Complete the prescribed request form (Form 2 of the PAIA Regulations), available from the Information Regulator.</li>
        <li>Send it to our Information Officer, with proof of your identity.</li>
        <li>Pay any prescribed request fee when we ask for it. <Pending>applicable fees under the current PAIA Regulations</Pending></li>
        <li>We will decide within 30 days and tell you in writing. We may extend this once, by up to 30 days, if PAIA allows it.</li>
      </ol>
      <p>
        You do not need to use PAIA to get your own personal information. Our{" "}
        <Link href="/privacy-policy/">privacy policy</Link> explains how to ask for it directly.
      </p>

      <h2>9. Refusal and remedies</h2>
      <p>
        We may refuse a request only on the grounds PAIA sets out, for example to protect other people&rsquo;s
        privacy or confidential commercial information. If you disagree with our decision, you may complain to
        the Information Regulator or apply to court.
      </p>

      <h2>10. Availability of this manual</h2>
      <p>
        This manual is published on our website, and a copy is available at our registered office on request.
      </p>
    </LegalPage>
  );
}
