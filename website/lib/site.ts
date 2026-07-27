export const siteConfig = {
  name: "Rasta's Peri Q Chesanyama",
  shortName: "Rasta Peri Q",
  description:
    "Flame-grilled food, easy ordering, and pickup or delivery from Rasta's Peri Q Chesanyama in Bloemfontein.",
  url: "https://rastasperiq.co.za",
  email: "contact@rastasperiq.co.za",
  phones: ["+27 73 642 3549", "+27 67 227 1229"],
  whatsappUrl: "https://wa.me/27736423549",
  address: "28 King Edward Rd, Bloemfontein, Free State 9301, South Africa",
  mapsUrl:
    "https://www.google.com/maps/search/?api=1&query=28%20King%20Edward%20Rd%2C%20Bloemfontein%2C%20Free%20State%209301%2C%20South%20Africa",
  socials: {
    instagram: process.env.NEXT_PUBLIC_INSTAGRAM_URL || "",
    facebook: process.env.NEXT_PUBLIC_FACEBOOK_URL || "",
    tiktok: process.env.NEXT_PUBLIC_TIKTOK_URL || "",
  },
} as const;

export const mailtoUrl = `mailto:${siteConfig.email}`;
