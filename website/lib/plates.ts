import manifest from "../public/plates/manifest.json";

/**
 * Plate cut-outs made from the restaurant's own photos (see
 * tools/plate-cutouts). A cut-out is only used while the menu item still points
 * at the exact stored photo it was made from, so a photo replaced in the admin
 * app always shows as the new photo, never as an old cut-out.
 */
const cutouts = manifest as Record<string, { file: string; source: string }>;

export function plateCutoutFor(imageUrl: string | null | undefined): string | null {
  if (!imageUrl) return null;
  const marker = "/storage/v1/object/public/menu-images/menu/";
  const at = imageUrl.indexOf(marker);
  if (at === -1) return null;
  const stored = imageUrl.slice(at + marker.length).split("?")[0];
  const entry = cutouts[stored];
  return entry ? `/plates/${entry.file}` : null;
}
