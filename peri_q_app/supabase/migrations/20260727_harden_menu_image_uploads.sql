-- Safe to run after the original schema.sql has already been applied.
-- Adds server-side validation for menu and Today's Special image uploads.

update storage.buckets
set
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id = 'menu-images';
