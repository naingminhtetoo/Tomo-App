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

# Tomo v2 data-foundation verification

This section records the later data-foundation task, extending the existing
Flutter branch rather than restarting the migration. The earlier Phase 1
report above describes its own historical verification only.

Current machine: Linux x64, Flutter 3.47.6 / Dart 3.13.5, using the SDK at
`/workspace/tomo-tools/flutter/bin`. Working directory: `/workspace/Tomo-App`.
The writable package/config/analyzer caches and SQLite linker alias are
specified in the root README. No verification, TLS or package-checksum checks
were disabled. Initial SDK/network/home-directory/library setup failures were
resolved before the final analyzer/test results below.

| Executed command | Final result |
| --- | --- |
| `flutter pub get` | Passed; Drift/SQLite dependencies resolved and lockfile updated |
| `dart --suppress-analytics format .` | Passed; all 55 Dart files formatted |
| `dart --suppress-analytics fix --apply --code=curly_braces_in_flow_control_structures,unnecessary_underscores` | Applied standard lint fixes |
| `flutter analyze` | Passed: no issues found |
| `flutter test --reporter expanded` | Passed: 39 tests, zero failures/skips |
| `flutter build apk --debug` | Blocked: no Android SDK installed; no APK produced |
| `flutter build bundle --debug` | Blocked: default Android target needs Android SDK |
| `flutter build bundle --debug --target-platform linux-x64` | Passed: application kernel and asset bundle compiled |
| `git diff --check` | Passed |

The Linux-target bundle is a compilation check, not a packaged desktop app or
device test. No Android/iOS device or iOS build was run. The project remains at
the repository root; `assets/data/n2.json` is byte-for-byte unchanged. Remote
`main` remains at `c3f57ace3f11a37a784eeb308e8302cac76b274d`.

## Tests retained and added

All existing tests remain. The original occurrence counts remain 1,591 kanji
collection words, 134 kanji-master words, and 87 adverbs. Empty categories and
Unicode/blank chapter names are preserved. The 1,812 occurrences now resolve
to 1,747 shared master IDs and 13 decks.

Added/extended coverage verifies:

- Stable IDs across meaning edits, insertion, movement and source membership;
  deduplicated master content with shared deck references.
- Rich vocabulary plus separate grammar/kanji parsing, immutable relationships,
  local Japanese/reading/English/romaji search, and canonical round trips.
- Schema/manifest versions, safe relative paths, file-version cache reopening,
  selective vocabulary-only refresh, and unchanged component retention.
- Invalid JSON/schema/reference/ID updates leave good cached content intact;
  concurrent refreshes avoid stale or duplicate writes.
- Drift schema v1 contains user state only; flags preserve counters/scheduling;
  ratings/history, due/weak/favorites/recent/common-mistake queries, daily
  accuracy and unique chapter progress derive from actual records.
- Review + history + session counters + resume position commit atomically;
  invalid session reviews roll back; completion/clearing retain history;
  file-database reopening preserves user flags, history and shuffled order.
- Unsupported database versions fail without deleting valuable existing data.
- An offline widget study flow records a review, navigates Home and resumes
  the second card; prior responsive/navigation/preferences tests still pass.

## Remaining scope

No automatic SRS scheduling/mastery algorithm, Supabase/authentication,
background refresh UI, additional authored JLPT data, audio or release signing
was added. The remote source is configurable but disabled by default; tests
use controlled sources, not a live published content service. Legacy
word/reading corrections require retained published IDs or a deliberate ID
migration policy. Standalone grammar/kanji study screens are deferred.

Recommended next task: define scheduling/mastery semantics and add device
coverage, then publish authored content with permanent IDs and a versioned
manifest. JSON/content, Drift/user-state and SharedPreferences/settings
boundaries are documented in the root README.

## Files changed in the data-foundation task

53 files, including formatting of existing Dart files by the requested formatter.

```text
README.md
assets/data/content-manifest.json
docs/verification.md
lib/app/app.dart
lib/app/providers.dart
lib/app/router/app_router.dart
lib/app/router/app_routes.dart
lib/core/database/app_database.dart
lib/core/network/json_http_client.dart
lib/core/storage/content_cache.dart
lib/core/storage/file_content_cache.dart
lib/core/utils/content_json.dart
lib/core/widgets/tomo_scaffold.dart
lib/features/flashcards/presentation/deck_placeholder_screen.dart
lib/features/grammar/domain/grammar_content.dart
lib/features/kanji/domain/kanji_content.dart
lib/features/level_selection/data/app_preferences.dart
lib/features/level_selection/data/level_catalog_repository.dart
lib/features/level_selection/presentation/level_catalog_controller.dart
lib/features/level_selection/presentation/level_selection_screen.dart
lib/features/progress/data/README.md
lib/features/progress/data/drift_progress_repository.dart
lib/features/progress/domain/progress_repository.dart
lib/features/progress/presentation/progress_providers.dart
lib/features/progress/presentation/progress_screen.dart
lib/features/progress/presentation/review_screen.dart
lib/features/settings/presentation/preferences_controller.dart
lib/features/settings/presentation/settings_screen.dart
lib/features/study_menu/presentation/home_screen.dart
lib/features/study_menu/presentation/startup_screen.dart
lib/features/study_menu/presentation/study_menu_screen.dart
lib/features/study_menu/presentation/widgets/dashboard_sections.dart
lib/features/vocabulary/data/datasources/local_vocabulary_data_source.dart
lib/features/vocabulary/data/datasources/remote_vocabulary_data_source.dart
lib/features/vocabulary/data/models/content_manifest.dart
lib/features/vocabulary/data/models/legacy_vocabulary_mapper.dart
lib/features/vocabulary/data/repositories/json_vocabulary_repository.dart
lib/features/vocabulary/domain/entities/content_example.dart
lib/features/vocabulary/domain/entities/level_content.dart
lib/features/vocabulary/domain/entities/study_deck.dart
lib/features/vocabulary/domain/entities/vocabulary_card.dart
lib/features/vocabulary/domain/repositories/vocabulary_repository.dart
lib/features/vocabulary/presentation/vocabulary_controller.dart
lib/features/vocabulary/presentation/word_detail_sheet.dart
lib/main.dart
pubspec.lock
pubspec.yaml
test/content_foundation_test.dart
test/drift_progress_repository_test.dart
test/json_http_client_test.dart
test/preferences_and_routing_test.dart
test/vocabulary_mapper_test.dart
test/vocabulary_repository_test.dart
```

# Tomo v2 coral UI and study-flow verification

Continued the existing root Flutter application on `flutter-v2`, based on
`97961035998082c3a6dbba6d3a0d885a35b301c8`. Verification used Linux x64 with
Flutter 3.47.6 / Dart 3.13.5 and the writable caches documented in README.
The earlier reports above are historical; their Android APK success does not
apply to this cloud environment.

## Implemented and reused

- Coral Stitch tokens and dark/light ThemeData replace the deprecated teal
  palette. Shared card, badge, scaffold, buttons, dialogs, progress and bottom
  navigation styles include bundled, licensed Noto Sans JP typography.
- Home shows real saved session, level, streak, today's reviews/learned words,
  accuracy, due count, four category cards and a learning tip.
- Study supports local search and category/source/chapter selection. Single
  deck sources skip chapter selection. Chapter totals/progress use shared
  master IDs and persisted learning state; there are no invented locked
  chapters or illustrative numbers.
- Flashcards show actual word/reading, supplied-only metadata, tap/button
  reveal, previous/next, favorite/difficult, explicit shuffle, four ratings,
  Word Detail and persistent resume. Session replacement/reordering requires
  an in-app confirmation. Stale controllers cannot end replacement sessions.
- Word Detail reuses the existing component. Missing examples, collocations,
  kanji information, parts of speech and romaji are hidden.
- Review opens five installed-content collections using real progress/history.
  Weak queries also include difficult flags and the latest Hard/Again rating.
- Progress shows unique studied words, category/chapter progress, review totals,
  accuracy and seven-day activity/streak from review history.

Reused GoRouter, Riverpod, preferences, the content provider/cache/repository,
legacy mapping, stable content IDs, existing word details and Drift progress
repository. Study actions now live in a Riverpod controller rather than the
old placeholder widget. No tables/schema migrations or content changes:
`assets/data/n2.json` and database schema v1 are unchanged. Ordinary study uses
local content; opening cards does not fetch remote JSON. Vocabulary and Kanji
category totals overlap because the original Kanji decks contain vocabulary.

## Executed verification

| Command / check | Result |
| --- | --- |
| `flutter pub get` | Passed; font assets registered, no dependency changes |
| `dart --suppress-analytics format .` | Passed; 66 Dart files formatted |
| `flutter analyze` | Passed; no issues found |
| `flutter test --reporter expanded` | Passed; 52 tests, zero failures/skips |
| `flutter test test/study_ui_flow_test.dart --dart-define=TOMO_CAPTURE_UI=true` | Passed; both phone widths, 11 real-font captures |
| `flutter build apk --debug` | Could not build: no Android SDK installed; no APK produced |
| `flutter build bundle --debug --target-platform linux-x64` | Passed; kernel and asset bundle compiled |
| `git diff --check` | Passed |

The bundle compilation is not an Android build or packaged desktop app.
No Android/iOS emulator, device run, iOS build or release signing was performed.

All 39 previous tests remain, with assertions updated for the new navigation
and button labels. Added 13 tests cover controller reveal/navigation/order,
explicit shuffle/resume, persisted flags/chapter progress, completion,
empty/missing content, session conflicts/stale controllers, real review
collections/latest Hard behavior, calendar activity/streak and complete local
navigation at 320px and 457px. The previous 1100px layout test remains.
The UI flow also checks search, detail flags propagating to cards, rating,
Home resume and empty Grammar/Due Today states. Existing file-database tests
continue to verify persistence across database reopen.

Render captures were inspected for the coral Home and Flashcard references,
shared colors, Japanese text and button typography. Other captures cover
Study, sources, chapters, revealed card, details, Review, Progress and empty
review. These are artifacts at `/workspace/tomo-tools/screenshots` and are
not golden assertions or committed generated images. Reproduction is in
README; captures use real N2 content and a single recorded test review.

## Remaining scope and Phase 3

- Audio and richer educational metadata have no supplied backing data; no fake
  playback controls or educational text were introduced.
- Due counts are accurate but stay zero until explicit schedules exist. Ratings
  do not automatically schedule reviews or increase mastery. No SRS algorithm
  or invented intervals, retention percentages or readiness dates were added.
- New users see empty content/review states; Grammar and standalone kanji study
  remain unavailable. The legacy Kanji vocabulary is fully usable.
- The bundled Japanese font adds about 9 MB before platform packaging.
- Android device/layout behavior still needs verification with an SDK/emulator.

Recommended Phase 3: define scheduling/mastery semantics and implement a small,
tested SRS engine; run Android/iOS device smoke tests; publish authored content
with permanent IDs and real audio/metadata through the existing manifest.

## Files changed in this UI/study task

32 changed paths (including replacement of the flashcard placeholder):

```text
M	README.md
A	assets/fonts/NotoSansJP.ttf
A	assets/fonts/OFL.txt
M	docs/verification.md
M	lib/app/router/app_router.dart
M	lib/app/router/app_routes.dart
M	lib/app/theme/tomo_theme.dart
M	lib/core/widgets/tomo_scaffold.dart
A	lib/core/widgets/ui_action.dart
D	lib/features/flashcards/presentation/deck_placeholder_screen.dart
A	lib/features/flashcards/presentation/flashcard_screen.dart
A	lib/features/flashcards/presentation/study_controller.dart
M	lib/features/progress/data/drift_progress_repository.dart
M	lib/features/progress/domain/progress_repository.dart
A	lib/features/progress/presentation/learning_state_controller.dart
M	lib/features/progress/presentation/progress_providers.dart
M	lib/features/progress/presentation/progress_screen.dart
M	lib/features/progress/presentation/review_screen.dart
A	lib/features/study_menu/domain/study_catalog.dart
A	lib/features/study_menu/presentation/catalog_provider.dart
A	lib/features/study_menu/presentation/category_screen.dart
A	lib/features/study_menu/presentation/chapter_screen.dart
M	lib/features/study_menu/presentation/home_screen.dart
M	lib/features/study_menu/presentation/study_menu_screen.dart
M	lib/features/study_menu/presentation/widgets/dashboard_sections.dart
M	lib/features/vocabulary/presentation/word_detail_sheet.dart
M	pubspec.yaml
M	test/preferences_and_routing_test.dart
A	test/study_activity_test.dart
A	test/study_controller_test.dart
A	test/study_ui_flow_test.dart
A	test/support/test_repositories.dart
```
