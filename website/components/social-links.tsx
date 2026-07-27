import { AtSign, Mail, MessageCircle, Music2, Phone, Users } from "lucide-react";
import { mailtoUrl, siteConfig } from "@/lib/site";

type SocialLinksProps = {
  compact?: boolean;
};

export function SocialLinks({ compact = false }: SocialLinksProps) {
  const configuredSocials = [
    {
      label: "Instagram",
      href: siteConfig.socials.instagram,
      icon: AtSign,
    },
    {
      label: "Facebook",
      href: siteConfig.socials.facebook,
      icon: Users,
    },
    {
      label: "TikTok",
      href: siteConfig.socials.tiktok,
      icon: Music2,
    },
  ].filter((social) => Boolean(social.href));

  const links = [
    {
      label: "WhatsApp",
      href: siteConfig.whatsappUrl,
      icon: MessageCircle,
    },
    ...configuredSocials,
    ...(compact
      ? []
      : [
          { label: "Email", href: mailtoUrl, icon: Mail },
          {
            label: "Call",
            href: `tel:${siteConfig.phones[0].replace(/\s/g, "")}`,
            icon: Phone,
          },
        ]),
  ];

  return (
    <div className="flex flex-wrap gap-3" aria-label="Contact and social links">
      {links.map(({ label, href, icon: Icon }) => (
        <a
          key={label}
          href={href}
          target={href.startsWith("http") ? "_blank" : undefined}
          rel={href.startsWith("http") ? "noreferrer" : undefined}
          aria-label={label}
          className="social-link"
        >
          <Icon size={18} aria-hidden="true" />
          {!compact && <span>{label}</span>}
        </a>
      ))}
    </div>
  );
}
