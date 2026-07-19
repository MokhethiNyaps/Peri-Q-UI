# Dependency and SDK Audit

Audit command: `flutter pub outdated` on 18 July 2026. Direct dependencies are current except the intentional file-picker compatibility pin.

| Direct package | Purpose / used | Android and size notes | Data / policy notes | Decision |
|---|---|---|---|---|
| `flutter` SDK | UI/runtime | Dominant native/AOT size; API 36 build passed | No advertising/tracking | Keep |
| `file_picker 10.3.10` | System picker for admin images and EFT proofs | Brings AndroidX/Tika resources; 11.x conflicts with current AGP 9 built-in-Kotlin/app_links combination | Narrow picker; app requests no broad media/storage permission | Keep pinned; retest 11.x after plugin migration |
| `shared_preferences 2.5.3` | Session preferences, saved addresses, cached menu | Small platform plugin | App-private local customer data; Android backup disabled | Keep |
| `supabase_flutter 2.16.0` | Auth, PostgREST, Realtime, Storage | Main networking/auth dependency; compatible with API 36 | Transmits account/order/proof data to owner's Supabase project | Keep/upgraded |
| `url_launcher 6.3.2` | Phone/WhatsApp support | Small platform plugin | Opens external apps; does not add analytics | Keep |
| `flutter_lints 6.0.0` (dev) | Static quality rules | Not in release binary | None | Keep |
| `flutter_test` (dev) | Unit/widget tests | Not in release binary | Test data only | Keep |

Removed: `google_fonts` (runtime font/network complexity), `flutter_dotenv` (`.env` asset risk/unneeded), `cupertino_icons` (unused). Their unused transitive packages were removed by `pub get`.

## Native/SDK inventory

- Android Gradle Plugin 9.0.1; Gradle 9.1.0; Kotlin plugin declaration 2.3.20; Java/JVM target 17; build JDK 21.
- Flutter engine native libraries for `armeabi-v7a`, `arm64-v8a`, and `x86_64`; Play delivers ABI-specific splits.
- Supabase transitive clients: GoTrue/Auth, PostgREST, Realtime WebSocket, Storage, HTTP and app-links support.
- AndroidX dependencies from Flutter plugins, including lifecycle, datastore/preferences, browser and file-provider utilities.
- Apache Tika resources originate from file-picker MIME handling.

## Not present

No Firebase, FCM, analytics, crash-reporting, advertising, attribution, payment-card, location, maps, contacts, SMS, call-log, camera, broad storage or social-tracking SDK is configured. No `google-services.json` is present. Notifications therefore remain optional/unimplemented; in-app realtime status is authoritative.

## Compatibility/policy concerns

- Flutter warns that file-picker 10.x applies the Kotlin Gradle Plugin and future Flutter versions will require built-in Kotlin. Current debug/release API 36 builds pass. Upgrade only after both file-picker and Supabase `app_links` work together in built-in-Kotlin mode.
- The app declares only `INTERNET`. File selection uses the system picker and does not require broad storage/photo permission.
- Publishable Supabase values are expected in the compiled client; they are not secrets. RLS/RPC must remain correctly deployed. Service-role keys are prohibited.
