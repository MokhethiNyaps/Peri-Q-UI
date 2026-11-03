import Link from "next/link";

/** The short notice shown wherever we collect personal information (POPIA section 18). */
export function PrivacyNotice({ purpose }: { purpose: string }) {
  return (
    <p className="text-xs leading-5 text-ash">
      {purpose} We share it only with the services that run our ordering and payments, and we never see
      your card details. See our <Link href="/privacy-policy/" className="font-bold underline">privacy policy</Link> for
      your rights.
    </p>
  );
}

/** Required tick box: accepting the terms and confirming the privacy policy was read. */
export function PolicyConsent({ checked, onChange, error }: { checked: boolean; onChange: (value: boolean) => void; error?: string }) {
  return (
    <div>
      <label className="flex items-start gap-3 text-sm leading-6 text-charcoal">
        <input
          type="checkbox"
          required
          checked={checked}
          onChange={(event) => onChange(event.target.checked)}
          aria-invalid={!!error}
          className="mt-1 size-4 shrink-0 accent-peri-red"
        />
        <span>
          I accept the <Link href="/terms-and-conditions/" target="_blank" className="font-bold underline">terms and conditions</Link> and
          have read the <Link href="/privacy-policy/" target="_blank" className="font-bold underline">privacy policy</Link>.
        </span>
      </label>
      {error && <p role="alert" className="mt-2 text-sm font-bold text-peri-red">{error}</p>}
    </div>
  );
}
