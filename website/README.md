# RastasperiQ website

A static Next.js website for `rastasperiq.co.za`, designed for deployment on Vercel.

## Pages

- `/` — landing page
- `/privacy-policy/` — public privacy policy for the Android app
- `/terms-and-conditions/` — customer ordering terms
- `/delete-account/` — public account-deletion instructions for users and Google Play

## Run locally

Install [Node.js](https://nodejs.org/) and pnpm, then run:

```bash
pnpm install
pnpm dev
```

Open `http://localhost:3000`.

## Add social accounts

The verified WhatsApp contact is already enabled. To show Instagram, Facebook, or TikTok:

1. Copy `.env.example` to `.env.local` for local development.
2. Add the complete public profile URL after the matching variable.
3. In Vercel, open **Project Settings → Environment Variables** and add the same values.
4. Redeploy the project.

Only social links with a configured URL are displayed, so the site never sends visitors to a guessed or placeholder account.

## Connect Today's Special

Add `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` in Vercel using the same production Supabase project as the Android app. Enter only the value in each Vercel value field: the URL must look like `https://your-project-ref.supabase.co`, without `NEXT_PUBLIC_SUPABASE_URL=` or quotation marks. The public landing page then reads the `app_settings` row and subscribes to realtime updates. Use only a Supabase publishable key; never place a secret or service-role key in a `NEXT_PUBLIC` variable. Redeploy after changing either value because Next.js includes public variables in the browser bundle during the build.

## Deploy to Vercel

1. Push the repository to GitHub, GitLab, or Bitbucket.
2. In Vercel, choose **Add New → Project** and import the repository.
3. Set the **Root Directory** to `website`.
4. Keep the detected framework as **Next.js** and deploy.
5. In the Vercel project, open **Settings → Domains** and add `rastasperiq.co.za`.
6. Add the DNS records Vercel displays at the company where the domain is registered.
7. Add `www.rastasperiq.co.za` too and redirect it to the primary domain if desired.

The project uses Next.js static export. `pnpm build` generates the deployment files in `out/`.

## Before publishing

- Add the confirmed Instagram, Facebook, and TikTok profile URLs.
- Confirm the contact numbers, email address, and street address.
- Have the business owner or legal adviser verify that the privacy-policy wording matches current app behaviour and legal obligations.
- Use `https://rastasperiq.co.za/privacy-policy/` for the Play Console privacy-policy URL.
- Use `https://rastasperiq.co.za/delete-account/` for the Play Console account-deletion URL.
