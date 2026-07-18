# Rasta's Peri Q Chesanyama

Production-oriented Flutter/Supabase ordering app for a single local store.

## Run locally

1. Install Flutter 3.44+, Java 21 and Android SDK/API 36.
2. Supply Supabase values as compile-time defines (do not bundle `.env`):

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=KEY
```

## Quality gates

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Release

Read `docs/ANDROID_SIGNING_GUIDE.md`, `docs/FINAL_RELEASE_REPORT.md` and `docs/GOOGLE_PLAY_RELEASE_CHECKLIST.md`. Apply `supabase/schema.sql` to staging/production before testing order placement. Never use a service-role key in the app.

The checked-in release configuration targets API 36, shrinks resources/code, and uses a permanent candidate application ID. Without ignored `android/key.properties`, release output is intentionally unsigned.
