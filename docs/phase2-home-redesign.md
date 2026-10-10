# Phase 2 Home UX redesign

This focused update keeps the established Stitch theme and existing Riverpod,
GoRouter, JSON, SharedPreferences and Drift boundaries. It changes only Home
composition, shared scaffold display behavior and related tests.

## Information hierarchy

Home now answers “What will you learn today?” in this order:

1. Tomo brand, settings and the interactive JLPT level selector
2. Welcome heading and short guidance
3. Study Categories
4. Pick up where you left off, when saved activity exists
5. A review reminder, when at least one installed word is due
6. Today's Learning

The previous large generic start/continuation panel, zero-state Review Queue
and static Daily Learning Tip were removed. The dedicated Study, Review and
Progress navigation remains unchanged.

## Reused data and behavior

- `StudyCatalog.categoryProgress` determines category availability. Available
  cards open their existing category route; empty Grammar is dimmed, locked
  and noninteractive.
- `LastLearningActivity` resolves the real category, source and chapter for
  the compact continuation row. `activeSessionProvider` independently keeps
  Resume Flashcards available.
- `progressSummaryProvider` supplies due, learned-today and reviewed-today
  values. The due reminder is omitted at zero.
- `studyActivityProvider` supplies the saved review streak.
- `TomoScaffold` can hide a brand-level badge while retaining the level value
  used by bottom navigation. Home uses this to avoid showing N2 twice beside
  the explicit Change Level button.

No counts, percentages, lessons or review schedules are invented. No database
schema, content ID, learning algorithm or non-Home route changed.

## Responsive behavior

The category grid remains two columns on phones, uses whole-card InkWell touch
targets, and keeps descriptions more prominent than status. Tests cover the
full conditional Home state at 320px and 457px with 1.4× system text. The
real-font capture path renders both the new-user Home and returning-user
continuation state for visual inspection.

## Verification

Verified on macOS arm64 with Flutter 3.47.7 and Dart 3.13.5.

| Command | Result |
| --- | --- |
| `flutter pub get` | Passed; dependencies resolved |
| `dart format .` | Passed; 71 Dart files checked |
| `flutter analyze` | Passed; no issues found |
| `flutter test --reporter compact` | Passed; 65 tests, zero failures |
| `flutter test test/study_ui_flow_test.dart --dart-define=TOMO_CAPTURE_UI=true` | Passed; 320px and 457px flows rendered |
| `flutter build apk --debug` | Passed; debug APK produced |
| `git diff --check` | Passed |

The captures were inspected for the new-user Home and the returning-user
continuation state. They use actual N2 availability and test-owned persisted
activity rather than illustrative dashboard values. No emulator, physical
device or iOS build was run.
