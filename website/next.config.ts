import type { NextConfig } from "next";

// Only the restaurant's own Supabase photo bucket may be resized by the image
// optimiser. Any other host would turn the optimiser into an open proxy.
function menuImageHost(): string {
  const fallback = "nxzelriapklqaxcxmoys.supabase.co";
  try {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    return url ? new URL(url).hostname : fallback;
  } catch {
    return fallback;
  }
}

const nextConfig: NextConfig = {
  trailingSlash: true,
  images: {
    formats: ["image/avif", "image/webp"],
    deviceSizes: [390, 640, 828, 1080, 1440, 1920],
    imageSizes: [96, 160, 256, 384],
    minimumCacheTTL: 60 * 60 * 24 * 7,
    remotePatterns: [
      {
        protocol: "https",
        hostname: menuImageHost(),
        pathname: "/storage/v1/object/public/menu-images/**",
      },
    ],
  },
};

export default nextConfig;
