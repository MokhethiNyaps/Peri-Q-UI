export const siteConfig = {
  name: "RastasperiQ",
  shortName: "RastasperiQ",
  description:
    "Flame-grilled food, easy ordering, and pickup or delivery from RastasperiQ in Bloemfontein.",
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
  app: {
    packageId: "za.co.rastasperiq.ordering",
    // Handled by the Play Store app itself, never by a browser.
    marketUrl: "market://details?id=za.co.rastasperiq.ordering",
    // Used as the fallback on iPhone, desktop, and inside in-app browsers.
    playStoreUrl:
      "https://play.google.com/store/apps/details?id=za.co.rastasperiq.ordering",
  },
} as const;

export const mailtoUrl = `mailto:${siteConfig.email}`;

// Short, printable link used on posters and table tents. Pointing the printed
// QR here instead of straight at market:// means one code works on every phone
// and can be repointed later without reprinting anything.
export const getAppPath = "/get-app/";
export const getAppUrl = `${siteConfig.url}${getAppPath}`;
