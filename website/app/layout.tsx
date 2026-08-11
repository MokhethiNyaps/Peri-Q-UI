import type { Metadata, Viewport } from "next";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { siteConfig } from "@/lib/site";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(siteConfig.url),
  title: {
    default: "RastasperiQ | Flame. Flavour. Vibes.",
    template: "%s | RastasperiQ",
  },
  description: siteConfig.description,
  applicationName: siteConfig.name,
  alternates: { canonical: "/" },
  manifest: "/site.webmanifest",
  icons: {
    icon: "/white-app-icon.png",
    apple: "/white-app-icon.png",
  },
  openGraph: {
    type: "website",
    locale: "en_ZA",
    url: siteConfig.url,
    siteName: siteConfig.name,
    title: "RastasperiQ",
    description: siteConfig.description,
    images: [
      {
        url: "/Logo.png",
        width: 1536,
        height: 1024,
        alt: "RastasperiQ logo",
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
