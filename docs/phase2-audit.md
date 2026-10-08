# Phase 2 audit before Phase 3

Audited remote `flutter-v2` at `c42a568320fcf5bb8fc68eee9a7acf0c8cb1148d`.
The working tree matched that commit apart from an unrelated untracked
`.angular/` cache, which was left outside this task. No AGENTS.md instructions
were present. No Phase 3 features, Supabase, dependency changes, schema changes,
new learning data or architecture redesign were introduced.

## Confirmed bugs fixed

| Finding | Trigger / previous behavior | Fix and regression coverage |
| --- | --- | --- |
| Incorrect lifetime metrics | Progress labeled today's review count/accuracy as lifetime values; old reviews disappeared from that display after midnight | Separate lifetime counters derived from all review history. Existing daily/Home metrics retain their semantics. Multi-day widget/repository tests verify counts, accuracy, zero history and installed-ID filtering |
| Resume/shuffle order for combined sources | Shuffle “Study All Chapters”, resume via Home, turn shuffle off: the order stayed shuffled | Reconstruct source/deck order for the saved source, retaining saved membership/index on resume; only explicit shuffle changes order. Controller test verifies persisted restoration |
| Resume/shuffle order for review collections | A saved shuffled Favorites review behaved the same way | Reuse real collection queries to reconstruct collection order, intersect with saved membership, retain removed saved cards and exclude newly added collection cards. Regression test covers restore and membership changes |
| Larger-text layout overflows | At 320px and 1.4× system text, Home's ready badge overflowed by 20px; Word Detail's category/level row overflowed by 40px | Constrain the Home badge and allow detail badges to wrap. Test visits all Phase 2 screens at that width/scale |
| Native theme mismatch | Android launch/window resources used white/system defaults; iOS launch/root storyboards used white | Match native startup backgrounds to the Flutter `#111219` token. Android uses one shared color resource. XML syntax verified; native compilation/visual launch transitions require device tooling |

Resumed combined sessions and word practice now also retain meaningful titles.
After a collection changes, “Restore order” means its current query order for
saved cards; removed saved cards remain appended. This deliberately preserves
session membership. Resume itself always keeps the exact persisted order.

## Screens, navigation and data verified

- Home → Study → category → source → chapter → flashcards → Word Detail;
  one-deck sources skip chapter selection. Search and empty Grammar/review
  states use local content. GoRouter parameters and existing invalid-route
  handling remain covered.
- Card reveal/hide, previous/next, disabled first-card previous button,
  favorite/difficult flags, rating/history, session position and Home resume.
  Added widget coverage exercises shuffle confirmation/cancel/restore and
  end confirmation/cancel against saved SQLite state.
- Session replacement and stale-controller protections remain covered by the
  existing tests. Navigation alone does not record a review.
- Category/chapter counts come from unique content IDs in decks and Drift learned state.
  Vocabulary and Kanji totals overlap because the original Kanji decks are
  vocabulary collections; this is documented rather than counted as a defect.
- Production composition uses `JsonVocabularyRepository`, real bundle/file
  cache, and `DriftProgressRepository`. No runtime mock vocabulary/progress
  repositories or illustrative metric values were found. New production-flow
  test uses default content/progress providers, Flutter assets, actual cache
  files and `AppDatabase.open()` background SQLite across container restart.
  It verifies 1,747 words, a real card, flags/history and saved position. Only
  the platform path result is redirected to a temporary directory and settings
  storage is replaced for that test; no content/progress test doubles are used.
- Normal study uses local content. HTTP update calls remain explicit and the
  remote host is disabled by default. Unchanged JSON/schema/ID boundaries were
  checked; there is no remote fetch for each card.
- Centralized coral ThemeData supplies buttons, cards, navigation, dialogs,
  progress indicators and Japanese fonts. No deprecated teal literals remain
  in `lib`. Home/Flashcard captures were visually inspected after the fixes;
  the capture flow also rendered Study, sources, chapters, revealed cards,
  Word Detail, Review, Progress and empty review.

## Commands and results

Linux x64, Flutter 3.47.6 / Dart 3.13.5. Commands ran at the root using the
writable SDK/caches/SQLite linker alias documented in README.

| Check | Actual result |
| --- | --- |
| Remote branch comparison | Local HEAD matched remote `flutter-v2` at audit start; `main` remained `c3f57ace3f11a37a784eeb308e8302cac76b274d` |
| Baseline `flutter analyze` | Passed, no issues |
| Baseline `flutter test --reporter expanded` | Passed, 52 tests |
| Targeted bug reproductions | New lifetime, combined/review restore, and larger-text tests failed against the original implementation, then passed with fixes |
| Dart formatting of changed source/tests | Passed |
| Final `flutter analyze` | Passed, no issues |
| Final `flutter test --reporter expanded` | Passed, 59 tests, no failures/skips; all original tests retained |
| `flutter test test/study_ui_flow_test.dart --dart-define=TOMO_CAPTURE_UI=true` | Passed, 320px/457px flows; real-font captures inspected |
| `flutter build bundle --debug --target-platform linux-x64` | Passed; application kernel/assets compiled |
| `flutter build apk --debug` | Blocked: no Android SDK found; no APK produced |
| Android resource / iOS storyboard XML parse | Passed for 7 files; structural syntax only, not AAPT/Xcode compilation |
| `git diff --check` | Passed |

The Linux bundle is not a packaged desktop or Android application. No mobile
emulator, physical-device run, iOS build or release signing was performed.

## Missing integrations retained within Phase 2 scope

- Audio, authored examples/collocations/parts of speech and standalone kanji
  metadata are not supplied by the current N2 fixture; unavailable sections
  are hidden. No fake audio control or educational content was added.
- Grammar and other JLPT levels remain unavailable. N2 Kanji vocabulary and
  adverb collections are usable; empty states identify absent content.
- Ratings record history and first exposure, not automatic schedules/mastery.
  Due Today uses explicitly stored due times; zero due counts for a new user
  are expected. Hard/Good/Easy count as correct, Again as incorrect under the
  existing repository convention. Automatic SRS remains outside this audit.
- Release signing, native plugin/platform behavior and live content hosting
  remain unverified. These gaps are not represented as passing build checks.

## Physical-device checks before relying on Phase 2

1. Install and cold-launch a debug build on Android and iOS. Check splash/root
   transition colors in light/dark OS modes (including Android 12+), status and
   navigation bars, notch/safe areas, orientation and Japanese font rendering.
2. With airplane mode enabled, start a chapter and a combined-source session;
   flip, navigate, rate, flag and open details/search. Confirm the full flow
   uses bundled/cached content without a network dependency.
3. Shuffle, advance, background and force-close/relaunch the app. Confirm exact
   position/order plus favorite/difficult/history persistence, then explicitly
   restore order. Check end/replacement dialogs and Android system Back/iOS
   swipe back during the same flow.
4. Check native SQLite/path_provider and SharedPreferencesAsync settings on the
   actual devices. Change theme, relaunch, and verify the preference remains.
5. Check phone keyboards/Japanese IME, large system text, landscape and small
   screens. Automated checks cover 320/457/1100px and 1.4× text, not every OS
   font scale, inset or keyboard configuration.
6. Review Progress on later days/local time zones. Lifetime totals should stay
   stable while today's counters reset. Due collection integration can be
   tested with explicitly scheduled data; no automatic scheduling is promised.

## Files changed

```text
README.md
android/app/src/main/res/drawable-v21/launch_background.xml
android/app/src/main/res/drawable/launch_background.xml
android/app/src/main/res/values-night/styles.xml
android/app/src/main/res/values/colors.xml
android/app/src/main/res/values/styles.xml
docs/phase2-audit.md
ios/Runner/Base.lproj/LaunchScreen.storyboard
ios/Runner/Base.lproj/Main.storyboard
lib/features/flashcards/presentation/study_controller.dart
lib/features/progress/data/drift_progress_repository.dart
lib/features/progress/domain/progress_repository.dart
lib/features/progress/presentation/progress_screen.dart
lib/features/study_menu/presentation/widgets/dashboard_sections.dart
lib/features/vocabulary/presentation/word_detail_sheet.dart
test/phase2_audit_test.dart
test/production_storage_flow_test.dart
test/study_controller_test.dart
```
