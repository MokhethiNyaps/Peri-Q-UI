import type { Metadata, Viewport } from "next";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { siteConfig } from "@/lib/site";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(siteConfig.url),
  title: {
    default: "Rasta's Peri Q Chesanyama | Flame. Flavour. Vibes.",
    template: "%s | Rasta's Peri Q",
  },
  description: siteConfig.description,
  applicationName: siteConfig.name,
  alternates: { canonical: "/" },
  manifest: "/site.webmanifest",
  icons: {
    icon: "/brand-mark.png",
    apple: "/brand-mark.png",
  },
  openGraph: {
    type: "website",
    locale: "en_ZA",
    url: siteConfig.url,
    siteName: siteConfig.name,
    title: "Rasta's Peri Q Chesanyama",
    description: siteConfig.description,
    images: [
      {
        url: "/brand-mark.png",
        width: 1024,
        height: 1024,
        alt: "Rasta's Peri Q Chesanyama logo",
      },
    ],
  },
};

export const viewport: Viewport = {
  themeColor: "#C8240B",
  colorScheme: "light",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en-ZA">
      <body>
        <a href="#main-content" className="skip-link">
          Skip to content
        </a>
        <SiteHeader />
        {children}
        <SiteFooter />
      </body>
    </html>
  );
}
