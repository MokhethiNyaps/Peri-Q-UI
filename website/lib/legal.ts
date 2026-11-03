// One source for the business facts used by every legal page. Values marked
// `null` are not yet confirmed by the business owner and render as visible
// placeholders, so a missing fact is never guessed or silently left out.

/** True until the owner and an attorney approve the legal documents. */
export const LEGAL_REVIEW_PENDING = true;

/** Version label shown on every legal page. */
export const LEGAL_VERSION = "Draft for review, 3 November 2026";

export const business = {
  legalName: "PERI Q CHISANYAMA (PTY) LTD",
  tradingName: "RastasperiQ",
  registrationNumber: "2025/302145/07",
  entityType: "Private company",
  registeredOffice: "28 King Edward Willows, Bloemfontein, Free State, 9301",
  /** The website shows "28 King Edward Rd"; the owner must confirm the trading address. */
  tradingAddress: null as string | null,
  directors: null as string | null,
  informationOfficer: null as string | null,
  vatNumber: null as string | null,
  certificateOfAcceptability: null as string | null,
  /** Supabase project region, confirmed from the live project. */
  dataRegion: "Ireland (EU), Supabase region eu-west-1",
} as const;

export type LegalDocument = { href: string; title: string; summary: string };

export const legalDocuments: LegalDocument[] = [
  { href: "/privacy-policy/", title: "Privacy policy", summary: "What personal information we collect, why, who receives it, and your rights under POPIA." },
  { href: "/terms-and-conditions/", title: "Terms and conditions", summary: "The agreement that applies when you use the website or app and place an order." },
  { href: "/payment-policy/", title: "Payment policy", summary: "How card payments work, when you are charged, and what happens if a payment fails." },
  { href: "/cancellation-policy/", title: "Cancellation policy", summary: "When and how an order can be cancelled by you or by the restaurant." },
  { href: "/refund-policy/", title: "Refund policy", summary: "When refunds are given, how they are paid, and how long they take." },
  { href: "/complaints/", title: "Complaints procedure", summary: "How to raise a complaint, how we respond, and where to escalate it." },
  { href: "/cookie-policy/", title: "Cookie and storage notice", summary: "What the website stores on your device and why." },
  { href: "/paia-manual/", title: "PAIA manual", summary: "How to request access to records held by the company under PAIA." },
];
