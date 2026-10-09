# Phase 2 Stitch UI implementation

This implementation started from `00aa0b3c7a9d56fc4be34aa8cf11e05b9c916e86`
on `flutter-v2`. The supplied Google Stitch package is retained under
`design/stitch/` with its five PNG references, five HTML exports and
`DESIGN.md`.

## Native Flutter translation

The Stitch colors, tonal surfaces, rounded cards, pills, spacing and coral
actions now come from `TomoTheme` and shared widgets. The implementation is
native Flutter; no HTML or WebView is used. Layouts cap their content width on
larger screens and remain usable at 320 logical pixels and 1.4x system text.

- Home keeps the real selected level, saved-session continuation, daily
  counts, review queue, study categories and activity streak.
- Study and category screens retain local search and the existing source
  mapping. Chapter selection now follows the Stitch course-roadmap design and
  derives every unit and progress value from installed N2 content and Drift.
- Flashcards adopt the Stitch session hierarchy, progress bar, large Japanese
  card and color-coded ratings while retaining reveal/hide, previous/next,
  shuffle/restore, favorite/difficult flags, Word Detail, confirmations and
  exact saved-session resume behavior.
- Review uses the Stitch card hierarchy with real Due, Weak, Favorites,
  Recently Learned and Common Mistakes collections.
- Progress uses persisted lifetime and seven-day data. It shows learned words,
  reviews, streak, accuracy, category/chapter progress and weak words without
  illustrative statistics.
- Settings translates the supplied section/card treatment into the available
  selected-level, shuffle, theme and offline-content controls. Level selection,
  startup, errors and empty states share the same visual system.

`TomoScaffold`, `SurfacePanel`, `TomoBrand`, `TomoBadge`, the existing
controllers and the repository/provider boundaries were reused.
`TomoSectionLabel`, `TomoIconTile`, `TomoMetricCard` and `TomoEmptyState` were
added for repeated visual patterns.

## Deliberate differences from the exports

The exports contain illustrative N3 profiles, chapter locks, completion
percentages, study-time estimates, audio controls, notifications, cloud sync,
SRS stages, quiz answers and handwriting recognition. These are omitted
because the current application has no backing services or content for them.
The app continues to use its installed N2 dataset and displays actual local
state. Classic reveal-and-rate flashcards remain the working study mode; the
quiz and handwriting exports are future references rather than nonfunctional
screens.

The four-tab navigation and all existing deep links remain intact. Settings is
still opened from Home. No content IDs, JSON files, Drift schema or stored user
progress were changed.

## Verification

Verification used Flutter 3.47.7 and Dart 3.13.5 on macOS arm64.

| Check | Result |
| --- | --- |
| `flutter pub get` | Passed |
| Formatting of changed Dart files | Passed |
| `flutter analyze` | Passed with no issues |
| `flutter test --reporter compact` | Passed: 59 tests |
| UI render capture test | Passed at 320px and 457px; 12 captures |
| 1.4x text-scale navigation test | Passed at 320px across all Phase 2 routes |
| `flutter build apk --debug` | Passed; debug APK produced |

Render captures are optional local artifacts written under the platform
temporary directory at `tomo-ui-screenshots/`; they are not committed golden
files. Android/iOS safe areas, native back gestures, keyboard behavior and
final visual fidelity still need physical-device review.

## Remaining Phase 2 review

Check the redesigned screens on representative Android and iOS devices in
dark and light modes. Pay particular attention to long Japanese text, native
safe areas, keyboard search, route transitions, persisted theme/shuffle state
and cold-launch session restoration. Automatic SRS, quizzes, audio,
handwriting, accounts and cloud sync remain later-phase work.
