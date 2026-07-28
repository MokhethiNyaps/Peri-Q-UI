# Android Signing Guide

## Key concepts

With Google Play App Signing, Google holds the **app-signing key** used for distributed APKs. The owner holds an **upload key** used to authenticate AAB uploads. Enrol in Play App Signing; do not share either private key or passwords.

## Existing upload key

This project already has a candidate keystore outside the repository:

```powershell
C:\Users\hp\Desktop\Mokhethi\Keys\peri-q-keys.jks
```

Do not generate a replacement identity. Confirm its alias and passwords from the
owner's password manager, then back up the original `.jks` encrypted in at least
two controlled locations.

Create `android/key.properties` locally (it is Git-ignored):

```properties
storePassword=OWNER_SECRET
keyPassword=OWNER_SECRET
keyAlias=upload
storeFile=C:\\Users\\hp\\Desktop\\Mokhethi\\Keys\\peri-q-keys.jks
```

Never commit `key.properties`, `.jks`, `.keystore`, passwords, service-role keys or CI secret values. CI should recreate `key.properties` from protected secret variables at build time.

Alternatively, leave `key.properties` absent and set these four environment
variables in the private build shell. The Gradle configuration reads them
without writing credentials into the repository:

```text
PERIQ_STORE_FILE
PERIQ_STORE_PASSWORD
PERIQ_KEY_ALIAS
PERIQ_KEY_PASSWORD
```

## Build a signed release

Copy `release-config.example.json` to the Git-ignored
`release-config.json`, fill in the production project URL and publishable key,
then build without placing the values in terminal history:

```powershell
flutter build appbundle --release --obfuscate --split-debug-info=release/android/symbols `
  --dart-define-from-file=release-config.json

flutter build apk --release --obfuscate --split-debug-info=release/android/symbols `
  --dart-define-from-file=release-config.json
```

Copy/rename the output to `release/android/rastas_peri_q_chesanyama-v1.0.1-build2-release.aab` only after verification.

## Verify

```powershell
jarsigner -verify -verbose -certs release\android\rastas_peri_q_chesanyama-v1.0.1-build2-release.aab
keytool -printcert -jarfile release\android\rastas_peri_q_chesanyama-v1.0.1-build2-release.aab
```

Expected: `jar verified` and the upload certificate owned by the business. Also run bundletool `validate`, upload first to Internal testing, and retain `r8-mapping.txt`, `native-debug-symbols.zip` and the matching Dart symbols for that exact build.

## Current status

Do not treat any artifact as upload-ready until the release build used the
existing keystore and the verification commands above succeeded. A build made
without all four signing values is unsigned even if its filename contains
`release`.

## Loss and recovery

- If the upload key is lost and Play App Signing is enabled, an account owner/admin can request an upload-key reset in Play Console; follow the instructions shown in that account.
- If the app-signing key is self-managed and lost, updates may become impossible. This is a major reason to use Play App Signing.
- Keep an ownership record, certificate fingerprints, backup locations, recovery contacts and periodic restore test. Never email private keys or passwords together.
