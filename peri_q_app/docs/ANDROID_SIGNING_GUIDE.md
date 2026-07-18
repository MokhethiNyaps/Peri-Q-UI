# Android Signing Guide

## Key concepts

With Google Play App Signing, Google holds the **app-signing key** used for distributed APKs. The owner holds an **upload key** used to authenticate AAB uploads. Enrol in Play App Signing; do not share either private key or passwords.

## Generate the upload key (manual owner action)

Run this in a private, backed-up location—not inside the repository:

```powershell
keytool -genkeypair -v -keystore C:\secure\peri-q-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Choose strong unique passwords and store them in the owner's password manager. Back up the `.jks` encrypted in at least two controlled locations.

Create `android/key.properties` locally (it is Git-ignored):

```properties
storePassword=OWNER_SECRET
keyPassword=OWNER_SECRET
keyAlias=upload
storeFile=C:\\secure\\peri-q-upload.jks
```

Never commit `key.properties`, `.jks`, `.keystore`, passwords, service-role keys or CI secret values. CI should recreate `key.properties` from protected secret variables at build time.

## Build a signed release

Supply the publishable Supabase values at compile time:

```powershell
flutter build appbundle --release --obfuscate --split-debug-info=release/android/symbols `
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Copy/rename the output to `release/android/rastas_peri_q_chesanyama-v1.0.0-build1-release.aab` only after verification.

## Verify

```powershell
jarsigner -verify -verbose -certs release\android\rastas_peri_q_chesanyama-v1.0.0-build1-release.aab
keytool -printcert -jarfile release\android\rastas_peri_q_chesanyama-v1.0.0-build1-release.aab
```

Expected: `jar verified` and the upload certificate owned by the business. Also run bundletool `validate`, upload first to Internal testing, and retain `r8-mapping.txt`, `native-debug-symbols.zip` and the matching Dart symbols for that exact build.

## Current artifact

The generated `*-unsigned.aab` is valid but deliberately unsigned because no production upload credentials were available. It is **not upload-ready**. The prior debug-key release configuration was removed.

## Loss and recovery

- If the upload key is lost and Play App Signing is enabled, an account owner/admin can request an upload-key reset in Play Console; follow the instructions shown in that account.
- If the app-signing key is self-managed and lost, updates may become impossible. This is a major reason to use Play App Signing.
- Keep an ownership record, certificate fingerprints, backup locations, recovery contacts and periodic restore test. Never email private keys or passwords together.
