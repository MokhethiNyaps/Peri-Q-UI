# Android Size Report

## Measurements

| Measurement | Result |
|---|---:|
| Baseline AAB (debug-key release configuration) | 55,415,697 bytes |
| Final unsigned obfuscated AAB | 51,667,589 bytes |
| Final reduction | 3,748,108 bytes (6.76%) |
| Final arm64 universal-style release APK analysis | 19.5 MB compressed |

The Play download is not the full AAB: Google Play creates device-specific APK splits, so an individual user's download should be materially smaller than the multi-ABI bundle.

## Major contributors

The arm64 analysis reports approximately 18 MB compressed native libraries. Dart AOT symbols account for about 7 MB decompressed, led by Flutter (~3 MB). App Dart code is ~315 KB. Flutter tree-shook Material Icons from 1,645,184 to 8,112 bytes. The sole brand image is 438,135 bytes.

## Optimisations applied

- Removed runtime `google_fonts` and `flutter_dotenv` plus their transitive native/tooling dependencies.
- Removed the unused Cupertino icons dependency.
- Removed `.env` from bundled assets.
- Enabled R8 minification, Android resource shrinking, icon tree-shaking and Dart obfuscation.
- Generated R8 mapping, native debug symbols and per-ABI Dart symbols.
- Bounded queries, decode-sized images and cached menu JSON to reduce runtime data/memory costs.
- Upgraded Supabase and compatible transitive packages.

## Deliberate non-optimisations

- File picker remains because admin menu images and customer EFT proofs require a scoped Android system picker. Removing it would break real features. Version 10.3.10 is retained for current AGP/Kotlin compatibility.
- The official 1000×1000 brand PNG remains unchanged to avoid degrading or altering supplied branding for a modest saving.
- All App Bundle ABIs remain. Play splits them per device; manually removing ABIs from an AAB would reduce compatibility without improving normal Play delivery.

## Analysis files

- `release/android/size-analysis/apk-code-size-analysis-arm64.json`
- `release/android/size-analysis/snapshot.arm64-v8a.json`
- `release/android/size-analysis/trace.arm64-v8a.json`

Final SHA-256 and build metadata are recorded in `FINAL_RELEASE_REPORT.md`.
