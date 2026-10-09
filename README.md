# Tomo v2

Tomo is a local-first Japanese study companion. The existing Flutter project
lives at the repository root on `flutter-v2`. The original Ionic app remains
on `main`; this work does not merge into or modify it.

## Run and verify

Use Flutter stable (latest UI work verified with Flutter 3.47.7 / Dart 3.13.5):

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

Android requires its SDK and a compatible Java runtime. iOS requires Xcode.
Mobile hosts retain `io.myjapanese.manabinotomo`. Production signing/store
release remains a separate task. Web is not supported by the current native
file-cache and SQLite adapters.

Linux tests require `libsqlite3.so` (usually provided by `libsqlite3-dev`). In
this cloud workspace, Flutter lives at `/workspace/tomo-tools/flutter/bin`.
The existing verified system `libsqlite3.so.0` has a local linker alias under
`/workspace/tomo-tools/lib`. Cloud commands use:

```sh
export PUB_CACHE=/workspace/tomo-tools/pub-cache
export XDG_CONFIG_HOME=/workspace/tomo-tools/config
export ANALYZER_STATE_LOCATION_OVERRIDE=/workspace/tomo-tools/analyzer
export FLUTTER_SUPPRESS_ANALYTICS=true
export LD_LIBRARY_PATH=/workspace/tomo-tools/lib
export PATH=/workspace/tomo-tools/flutter/bin:$PATH
flutter pub get
dart --suppress-analytics format .
flutter analyze
flutter test
```

These settings avoid writing SDK state into the read-only home directory.
SDKs/caches are outside the repository and are not committed.

## Existing foundation and current workflow

This task extends the existing Riverpod composition root, GoRouter routes,
Material 3 Tomo themes, preferences controllers, local/remote vocabulary data
sources, HTTP client, content cache, legacy mapper and tests. It preserves the
root project and the unchanged `assets/data/n2.json` fixture.

The app now uses the official Stitch coral design: centralized dark/light
ThemeData, rounded bordered cards, coral buttons and navigation, and bundled
Noto Sans JP typography. The dashboard restores the selected level and shows
real daily reviews, learned words, accuracy, streak, due count and category
progress. Continue Session restores the exact saved card order and position.

Normal navigation is Home → Study → Category → Source → Chapter → Flashcards
→ Word Detail. Sources with one deck open it directly. N2 is the only supplied
level; empty Grammar content is identified clearly. The legacy Kanji sources
are vocabulary collections and are labeled accordingly. Vocabulary and Kanji
views share those source memberships, so their totals overlap intentionally.
Category/source/chapter totals count unique master IDs, rather than duplicated
legacy occurrences.

Study has local Japanese/reading/English search. The Riverpod study controller
owns reveal, previous/next, explicit shuffle, flags, session start/end and
review recording. Navigation saves position without recording a review;
ratings require a revealed answer and atomically record history plus advance
the saved session. Shuffle restarts at the first card after an in-app
confirmation; after resume, turning it off restores source/collection order
without changing saved session membership; unfinished sessions require confirmation before replacement.
Word Detail reuses the existing component and hides absent metadata.

Review opens real Due Today, Weak Words, Favorites, Recently Learned and
Common Mistakes collections, filtered to installed vocabulary at the selected
level. Weak words include difficult flags, the latest Hard/Again rating and
repeated incorrect reviews. Recent words are ordered by first studied date;
common mistakes contain recorded incorrect reviews. Progress shows unique
studied words by category/chapter, lifetime accuracy and seven calendar days
of review activity. Accuracy follows the existing repository convention:
Hard/Good/Easy count as correct, Again as incorrect. A streak includes today
or, before today's first review, yesterday.

Ratings record history/counts; no automatic interval, ease or mastery algorithm
is applied. Due Today uses explicitly saved scheduling values, so a new user's
queue is empty. The repository accepts scheduling values for a future engine.
Grammar and standalone kanji have models but no fabricated seed data or study
UI. Audio controls and supplied-only parts of speech/examples/collocations/
kanji breakdowns are absent when their data is unavailable. Accounts and cloud
synchronization remain deferred.

### UI verification captures

The full local navigation widget test runs at 320px and 457px widths; existing
responsive dashboard coverage also runs at 1100px. To render screenshots with
the bundled Japanese and Material icon fonts in this cloud workspace:

```sh
flutter test test/study_ui_flow_test.dart --dart-define=TOMO_CAPTURE_UI=true
```

Captures go to the platform temporary directory under
`tomo-ui-screenshots`, outside the repository.
They show real N2 words and a test user who records one review, rather than
illustrative dashboard values. This is a Flutter test-rendering check, not a
mobile device test. See [verification details](docs/verification.md#tomo-v2-coral-ui-and-study-flow-verification).

The Japanese variable font is from
[Google Fonts Noto Sans JP](https://github.com/google/fonts/tree/main/ofl/notosansjp).
Its SIL Open Font License is included at `assets/fonts/OFL.txt`.

## Storage boundaries

| Data | Storage |
| --- | --- |
| Shared words, kanji, grammar, meanings, examples and deck membership | JSON assets and validated file cache |
| User progress, favorites, difficult flags, review history and sessions | Drift / SQLite |
| Selected level, theme and default shuffle | SharedPreferences |
| Future account, backup and multi-device synchronization | Supabase, not implemented or installed |

Widgets consume Riverpod providers; repositories own content and user-data
operations. `ProgressRepository` is the existing boundary extended with a
concrete `DriftProgressRepository`, rather than a competing abstraction.
`app/providers.dart` owns one database/repository per application container.
Tests inject isolated connections. User state never writes learning JSON;
SQLite holds IDs and learning state, not copies of words or meanings.

```text
Remote JSON -> Manifest -> Validated download -> Local content cache
                                                    |
                                              Content repository
                                                    |
                                                 Flutter UI
JSON stable content ID -> SQLite content_id -> User progress
```

## Master content, IDs and legacy compatibility

The 1,812 legacy occurrences map to 1,747 unique master word/reading pairs,
with 13 decks retaining every original chapter/category occurrence. Decks
reference master IDs; the same word in multiple sources shares learning state.
Original kanji collections contain vocabulary examples, not standalone kanji
metadata. Missing romaji, parts of speech, examples, collocations and kanji
readings remain null/empty. Distinct supplied meanings are retained.

New JSON requires published explicit IDs. The compatibility mapper derives
`n2_vocab_<full SHA-256>` from UTF-8 JSON `[trimmedWord, trimmedReading]`.
Meaning edits, examples, source/chapter changes, insertion and reordering do
not affect these IDs. The hash is deterministic, never a per-parse UUID.
Publishers must retain assigned IDs when correcting a word/reading; legacy
identity changes or splitting homographs require an explicit content/progress
migration policy. Old ordinal IDs were never backed by a shipped user database
on this branch, so there is no old database to migrate in this task.

`VocabularyCard` now supports romaji, partOfSpeech, meanings, kanjiIds,
examples, collocations and tags. Existing legacy metadata remains compatible.
`StudyDeck` carries ID, title, level, category, source, chapter and contentIds.
`KanjiContent` and `GrammarContent` are separate immutable domain models.

Canonical level JSON uses `{schemaVersion: 1, level: "N2", vocabulary: [...],
decks: [...], kanji: [...], grammar: [...]}`. Vocabulary IDs and word/reading
pairs must be unique. IDs across content types and decks are validated;
deck references must resolve. Standalone kanji references on a word may
remain unresolved until that metadata is supplied, so word details hide them.

## Versioned local and remote content

`loadLocal` never contacts the network. It validates bundle/cache and picks the
newer usable snapshot. Corrupt cache falls back to the bundle; a good cache
survives a missing bundle. Flashcard advancement and search use that local
master content, without remote calls.

The bundled manifest has schema version 1 and a `legacy` file descriptor for
unchanged `n2.json`. Legacy manifests without `schemaVersion` remain readable.
A published component manifest can instead use independent files:

```json
{
  "schemaVersion": 1,
  "levels": {
    "N2": {
      "version": 8,
      "files": {
        "vocabulary": {"version": 8, "path": "n2/vocabulary/words.json"},
        "decks": {"version": 3, "path": "n2/decks.json"}
      }
    }
  }
}
```

A component file is an object containing `schemaVersion`, `level`, and its
named array, for example `{ "schemaVersion": 1, "level": "N2", "vocabulary":
[...] }`. Supported components are vocabulary, kanji, grammar and decks.
A `legacy` file cannot be mixed with component descriptors.

`checkForUpdate` downloads only newer component versions, merges them into a
temporary level document, validates the entire candidate, and then atomically
replaces a cache envelope containing both content and file versions. Unchanged
components are retained. Schema, duplicate-ID, dangling-reference and stable-ID
failures preserve the old cache. Existing word/reading identity cannot quietly
receive a different ID. Refreshes are serialized to prevent stale writes.
Cache write failures return a usable in-memory snapshot while retaining the
previous persisted cache. File writes use flushed temporary files and rename.

Remote hosting is centralized and disabled by default; no versioned remote
manifest is published/verified by this task. Once matching files are available:

```sh
flutter run --dart-define=TOMO_CONTENT_BASE_URL=https://your-content-host/path/
```

Refresh is an explicit repository operation. Automatic background refresh and
UI update notifications are deferred; normal study remains entirely local.
Manifest paths must stay under the configured HTTPS host/base path.

## SQLite schema and learning semantics

`AppDatabase` uses Drift transactions and schema version 1, with explicit SQL
schema definitions. No generated Dart or code-generation step is needed.
Future schema versions must add incremental migrations; unknown upgrades fail
without dropping user data.

- `study_progress`: composite content ID/type key, status/mastery, counts,
  favorite/difficult, first learned/reviewed/due times, interval/ease,
  updated timestamp and pending sync status.
- `review_history`: rating, time, old/new interval, optional response time and
  session link, plus future-sync metadata.
- `study_sessions`: deck, level, mode, start/end times and review/correct counts.
- `active_session`: singleton unfinished-session pointer, index, mode, shuffle,
  immutable saved order and timestamps.

A recorded rating marks first exposure as learned and a new item as learning.
`again` increments incorrect; hard/good/easy increment correct. Mastered state
is explicit, reserved for the future engine. Chapter progress is unique
learned IDs divided by unique deck IDs; flag-only items are not learned.
Daily reviewed counts count review events; daily learned counts count first
exposures. Accuracy uses non-again events / events for the selected day/level.
Due means nextReviewAt <= now. Weak includes difficult flags, latest Hard/Again,
and incorrect > 0 with incorrect >= correct. Common mistakes sort items with
incorrect > 0 by incorrect count; recent items sort by first exposure.
Home uses today's counts/accuracy; Progress uses separate lifetime review
counts/accuracy, retaining reviews from previous days. Zero history shows zero
counts and no accuracy value.

Reviews, history, session counters, and next resume position commit atomically.
Clearing/completing removes the active pointer while preserving session history.
User-data queries expose a change stream for Riverpod to refresh the UI.
Sync-status fields provide a future boundary without implementing Supabase.

## Verification and next work

See the [Stitch UI implementation report](docs/phase2-stitch-implementation.md),
the [Phase 2 review and device checklist](docs/phase2-audit.md), and
[verification results](docs/verification.md) for commands and their actual
outcomes. The [original product audit](docs/legacy-product-audit.md) records the
preserved Ionic behavior. The next task should define simple review scheduling
and mastery rules, then add authored grammar/kanji content and publish a
versioned manifest with permanent IDs. Device/iOS testing and release signing
remain separate checks.
