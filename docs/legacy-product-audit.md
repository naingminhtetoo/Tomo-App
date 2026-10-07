# Ionic product audit

Inspected before implementation, against commit `c3f57ace3f11a37a784eeb308e8302cac76b274d`.
This is a source inspection, not a device/runtime audit. The inspected Ionic
application remains preserved on `main` and at the source commit above.

## Screens and navigation

`src/app/app-routing.module.ts` starts at `/level-select`. The selector
(`src/app/pages/level-select`) displays N5 through N1; only N2 is enabled.
Selection writes an in-memory signal in `services/level-state.ts`, then opens
`/home`. `src/app/home` is the practice menu with six category links to
`/deck/:type`. Back navigation returns to the menu, then the selector.
The Android root back handler in `app.component.ts` exits the application.
There is also an older `/flashcard-deck` route without a type parameter.
Selected level is not persisted or encoded in the deck URL, so a direct deck
link cannot independently restore its data context.

## Flashcards

`pages/flashcard-deck` owns index, chapter, order, shuffle, and revealed state.
`components/flashcard` is a reusable presentation component: word on the front;
word, reading, and English meaning on the back. Tap flips the card using a
700 ms Y-axis CSS rotation. Previous/Next stop at the ends, with a 1-based
counter (0 / 0 for empty content). There is no scoring, spaced repetition,
audio, saved progress, or swipe navigation in the inspected source.

All chapters (`すべて`) is the default. Changing chapters restarts at index zero
and hides the answer. Adverbs flatten all chapters and hide the selector.
Random uses Fisher–Yates shuffle. Changing it after index zero prompts to
restart; cancel restores the toggle. Reset hides the answer, but Previous/Next
do **not** reset the flipped state. Chapter-specific arrays can be shuffled
in place, mutating service data; Flutter should copy before shuffling.

## Data and content

`services/vocabulary.ts` defines cards `{word, reading, meaning}`, chapters
`{name, words}`, and a level document `{level, <category>: {chapters}}`.
Category sections are optional. Preserve Japanese Unicode and blank chapter
names. The singular route `adverb` maps to the plural JSON key `adverbs`.
Keep the legacy key `vocab_shinkansen` even though the UI names the textbook
新完全マスター. Do not infer new content from category labels.

The only bundled level is `src/assets/datas/n2.json`:

| JSON key | Menu label | Chapters | Cards |
| --- | --- | ---: | ---: |
| kanji | Kanji（総まとめ） | 8 | 1,591 |
| kanji_master | Kanji（漢字マスター） | 1 | 134 |
| adverbs | Adverb | 1 (blank name) | 87 |
| vocab_shinkansen | Vocabulary（新完全マスター） | 1 | 0 |
| vocab_soumatome | Vocabulary（総まとめ） | 1 (blank name) | 0 |
| other | Others | 1 (blank name) | 0 |

Total: 1,812 cards. Empty categories are enabled in the legacy menu and show
an empty card state. Local counts do not establish the current remote counts.

## Loading and state

Selecting a level triggers the vocabulary service effect. Online: GET
`https://gist.githubusercontent.com/naingminhtetoo/aa317f1afb33303017bc78254b110198/raw/<level>.json`
with an 8-second timeout, then save JSON in Capacitor Preferences under
`level_data_<level>`. Offline, or after network failure, parse that cache.
Without a usable cache, report error and offer Retry. The bundled JSON is
**not used** by this service, so first-launch offline fails in Ionic.
Remote data is typed but not runtime validated. Cache writes occur before
publishing ready data, so storage failure can discard a successful download.
There is no versioning, cache TTL, or protection against out-of-order level
requests. Loading/ready/error are global signals; deck controls are local.

`services/theme.ts` persists `theme_preference` using Capacitor Preferences,
defaults to dark, and applies a body class. The theme toggle is commented out
in the selector template, and dark palette imports are commented out globally.
Most screens explicitly use dark styling.

## Visual and platform reference

`src/theme/variables.scss`: background #121212, cards #1f2937, accent #2dd4bf,
medium #374151, white primary text, secondary gray #9ca3af. Rounded menu tiles
and flashcards, Japanese headings with English subtitles, centered content
(menu max 500px; card max 400px), safe-area header padding.
`src/global.scss` supplies shared alert/popover styling.

`package.json` uses Angular 20, Ionic 8, Capacitor 7, RxJS, Preferences and
Network plugins. Flutter should retain product concepts, not Angular DI,
signals, route duplication, or per-category getter repetition. Existing spec
files largely contain creation checks and some obsolete service names; they
are not evidence of tested product behavior.

## Phase 1 decisions

Use a standalone root-level Flutter project on `flutter-v2`. Use immutable
domain types, explicit level context, a single category model, validated legacy
JSON conversion, repository interfaces, and a composition root. Supply the
unchanged bundled N2 as an offline seed. Validated cache/bundled startup with
optional version-gated remote refresh is an intentional v2 improvement. Cache
write failure must not invalidate downloaded content.
Build only a level/menu shell with content availability and theme support;
defer flashcard UI, session persistence, shuffle interaction, and full learning
features. Keep their observed contracts above for the next migration phase.
