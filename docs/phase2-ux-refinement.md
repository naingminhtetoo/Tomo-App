# Phase 2 UX refinement

This refinement started from `07c2d77f11d07f328a091911f535ae14a75e39a7`
on `flutter-v2`. It extends the existing Riverpod, GoRouter, Drift and JSON
architecture and leaves the original N2 asset and database schema unchanged.

## Baseline audit

The existing app already had a strong reusable foundation: the Stitch-based
Material 3 theme, `TomoScaffold` and shared surface/badge/metric widgets,
typed `StudyCatalog` source/deck metadata, immutable content models, local
search, persistent favorites and difficult flags, saved flashcard sessions,
review history, grouped progress queries and safe deep-link validation.

The main UX gaps were structural. Chapter cards opened flashcards immediately,
the flashcard controller had only reveal-first behavior, Home represented only
the active flashcard session, and Progress flattened chapter membership. The
level button was also too easy to read as a static badge. Standalone Kanji and
Grammar models existed, but the installed N2 file contains vocabulary-based
Kanji decks and no Grammar lessons.

## Implemented flow

- Home labels the level action `JLPT N2 · Change Level` and opens the existing
  selector. Continue Learning restores the last browsed level, category,
  source and chapter. Resume Flashcards remains a separate action whenever an
  unfinished session exists.
- Category and chapter routes now open a reusable Learning List. It shows the
  installed word, reading and meaning, supports local search, toggles
  favorites, opens Word Detail, and offers Practice Flashcards as an explicit
  action. Opening a list does not create a study session or progress record.
- Learn Mode displays meanings initially, supports hide/show and previous/next,
  and never presents ratings or writes review history. Review Mode begins with
  the answer hidden and keeps the existing reveal-and-rate persistence rules.
- Progress groups real data as JLPT level → category → source → chapter. Each
  chapter reports learned/total IDs and navigates directly to its Learning
  List.
- Reusable Kanji and Grammar list layouts consume only canonical model fields.
  The current legacy Kanji decks get an honest vocabulary-source explanation,
  while missing Grammar uses a helpful empty state. Handwriting, quizzes,
  audio and invented lesson data were not introduced.

## State and persistence decisions

`LastLearningActivity` is a small SharedPreferences value containing level,
category, source and deck ID. This is sufficient to continue at the last
browsed chapter without changing the Drift schema. It deliberately does not
store a scroll offset. User flags, review records and active flashcard sessions
remain in Drift; static content remains JSON.

`FlashcardMode` belongs to the study controller. New chapter practice sessions
persist `learn`; review collections persist `review`. Existing saved sessions
using the older `flashcards` value resume safely as Learn Mode. Review-only
rating protection also exists in the controller, so a widget cannot
accidentally write review history from Learn Mode.

The Learning List route is:

```text
/study/:level/learn/:category?source=<source>&deck=<deck-id>
```

Existing word, review, session and deck deep links remain valid. Route
parameters continue to use explicit JLPT/category parsing.

## Content constraints and risks

- The legacy N2 asset has 1,747 unique words and 1,812 deck occurrences. Its
  Kanji sources contain related vocabulary rather than character records, and
  its Grammar decks are empty. Rich Kanji and Grammar layouts cannot be fully
  exercised until authored canonical content is published.
- Learning List currently renders the chapter rows within the shared scrolling
  scaffold. The largest current chapter is acceptable on tested phones, but a
  future much larger deck should move to slivers or another lazy list while
  retaining the route and controller boundaries.
- Continue Learning restores the chapter, not its precise scroll position.
- Learn Mode intentionally records no exposure or completion metric. A later
  product decision is needed if browsing progress should differ from reviewed
  progress.
- Automatic SRS scheduling, mastery rules, handwriting recognition and quiz
  generation remain outside this refinement.

## Verification

Verification uses macOS arm64, Flutter 3.47.7 and Dart 3.13.5. Automated
coverage includes the level action, preference persistence, reusable learning
list, favorite and detail actions, Learn/Review separation, continuation,
grouped progress navigation, 320/457px end-to-end flows and a 320px/1.4× text
route sweep.

| Command | Result |
| --- | --- |
| `flutter pub get` | Passed; dependencies resolved |
| `dart format .` | Passed; 70 Dart files checked, no changes required |
| `flutter analyze` | Passed; no issues found |
| `flutter test --reporter compact` | Passed; 60 tests, zero failures |
| `flutter test test/study_ui_flow_test.dart --dart-define=TOMO_CAPTURE_UI=true` | Passed at 320px and 457px |
| `flutter build apk --debug` | Passed; `build/app/outputs/flutter-apk/app-debug.apk` produced |
| `git diff --check` | Passed |

Real-font widget captures were rendered and inspected for Home continuation,
chapter browsing, Learning List, visible Learn Mode, Review, Progress,
Settings, Word Detail and empty states. Captures remain in the platform
temporary directory and are not repository assets.
