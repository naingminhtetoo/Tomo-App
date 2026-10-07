# Phase 1 verification

Verified with Flutter 3.47.6 / Dart 3.13.5 on macOS arm64.
Commands ran at the repository root, using the temporary SDK at
`/tmp/tomo-flutter-sdk/bin`. Flutter commands used `--no-version-check` to avoid
an unnecessary SDK Git-history fetch; the project checks themselves were not
skipped.

| Check | Result |
| --- | --- |
| `flutter pub get` | Passed; application lockfile committed |
| `dart format .` | Passed; all Dart source and tests formatted |
| `flutter analyze` | Passed; no issues found |
| `flutter test` | Passed; 21 tests after root-project restructuring |
| `flutter build apk --debug` | Passed; debug APK produced |
| iOS build/device run | Not executed |
| `plutil -lint` on iOS plist/Xcode project | Passed; metadata syntax only |
| `git diff --check` | Passed |
| Branch layout | Root-level standalone Flutter project; no Ionic files |
| `main` | Ionic app remains at `c3f57ace3f11a37a784eeb308e8302cac76b274d`; no merge |

## Test coverage

- All 1,812 bundled N2 cards and six categories map correctly; Japanese text,
  empty sections and blank chapter names are preserved.
- N2 content was migrated unchanged from the preserved Ionic source commit.
- IDs are unique/deterministic for the snapshot; duplicate explicit IDs,
  mismatched levels and malformed JSON shapes are rejected.
- Optional richer card fields and multiple meanings map correctly; content
  collections are immutable.
- First offline launch uses bundled content without a network call. Newer
  valid cache wins; stale/corrupted cache does not mask usable bundled content.
  A bundle read failure does not invalidate a good cache.
- Equal/older remote versions do not download; newer versions validate before
  caching. Invalid downloads do not replace cache; failed writes do not discard
  validated downloads.
- HTTP errors propagate and UTF-8 Japanese decoding is preserved.
- Preferences reload through a new controller. Responsive dashboard/menu
  checks run at 320px and 1100px widths; invalid route parameters redirect;
  theme changes do not reset navigation.

Widget tests inject a repository using the real N2 fixture, avoiding native
storage plugins in the test binding. Repository/network tests use controlled
sources; this is not a live remote-host, emulator or iOS device test.

## Android build result

Passed with exit code 0 from the repository root. Output:
`build/app/outputs/flutter-apk/app-debug.apk` (debug build). The relocated
working tree built in 80.2 seconds. A second build from a clean, tracked-files-
only export also passed in 39.3 seconds, proving a fresh checkout does not rely
on ignored files left by the Ionic or nested Flutter projects. Generated files
are ignored and were not committed. The APK was built, not installed or tested
on a device. Android uses compile SDK 36 and minimum API 24. iOS metadata passed
syntax validation, but iOS compilation/signing/device behavior remain
unverified.

## Implementation commits

All commits are on `flutter-v2`; no merge into `main` was performed.

| Commit | Change |
| --- | --- |
| `61d61210` | Audit Ionic product behavior |
| `f519cf2f` | Domain models and legacy JSON adapter |
| `6705ba5d` | Flutter Android/iOS initialization |
| `b3520570` | Centralized Material 3 themes |
| `e34c7f3f` | Local/remote content architecture |
| `86b88a97` | Riverpod controllers and declarative app shell |
| `8127bc76` | Migration, offline and routing tests |
| `b77f1f11` | Dashboard widget decomposition |

The final documentation commit records this report and the migration roadmap.
