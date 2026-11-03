import { describe, it, expect } from "vitest";
import { existsSync } from "node:fs";
import path from "node:path";
import { render, screen } from "@testing-library/react";
import { business, legalDocuments } from "../lib/legal";
import PrivacyPolicyPage from "../app/privacy-policy/page";
import TermsPage from "../app/terms-and-conditions/page";
import PaiaManualPage from "../app/paia-manual/page";

describe("Legal documents", () => {
  it("has a page for every listed document", () => {
    for (const doc of legalDocuments) {
      const page = path.join(__dirname, "..", "app", doc.href.replaceAll("/", ""), "page.tsx");
      expect(existsSync(page), doc.href).toBe(true);
    }
  });

  it("shows unconfirmed business facts as placeholders instead of guessing them", () => {
    render(<TermsPage />);
    expect(screen.getAllByText(business.registrationNumber, { exact: false }).length).toBeGreaterThan(0);
    expect(business.directors).toBeNull();
    expect(screen.getByText(/names of the directors/)).toHaveTextContent("[To be confirmed:");
  });

  it("names every service provider that receives customer information", () => {
    const { container } = render(<PrivacyPolicyPage />);
    const text = container.textContent ?? "";
    for (const provider of ["Supabase", "Vercel", "Yoco", "Google Firebase Cloud Messaging", "Google Play"]) {
      expect(text).toContain(provider);
    }
    expect(text).not.toMatch(/does not\s.*use Firebase/i);
    expect(text).toContain("never receive or store your card number");
  });

  it("marks drafts as under review", () => {
    render(<PaiaManualPage />);
    expect(screen.getByRole("note")).toHaveTextContent("Draft under review");
  });
});
