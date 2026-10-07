# Tomo v2 — Phase 1

This branch is the standalone Flutter Tomo project. The Flutter application
lives directly at the repository root; there is no wrapper `flutter_app/`
directory and no Ionic/Angular source on `flutter-v2`. The original Ionic app
remains available in Git history and on the `main` branch.

Android and iOS hosts use `io.myjapanese.manabinotomo`, preserving Tomo's
existing application identity.
Before a production release, verify signing, store ownership and version-code
continuity; the generated release signing configuration is for development.

## Run and verify

Install Flutter stable (this project was generated/verified with Flutter
3.47.6 and Dart 3.13.5), then from this directory:

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

For this workspace session, the temporary SDK is also available at
`/tmp/tomo-flutter-sdk/bin/flutter`; use that executable directly if Flutter is
not on your PATH. Install a persistent SDK for ongoing development.

Android requires the Android SDK and Java 17 or the compatible Android Studio
runtime. iOS requires Xcode and its platform tooling. Platform hosts are
included; iOS signing and release distribution are not part of Phase 1.
Flutter Web is deferred. The domain, mapper, repository contracts, HTTP and
routing are independent of mobile APIs; the file cache adapter must be
replaced with a browser-capable adapter when adding Web.

## What runs now

Startup restores simple preferences and opens a responsive dark/teal
dashboard. Continue Studying opens the selected level's minimal study menu.
The selector reads bundled availability from the manifest (N2 only). Menu
counts come from actual JSON; empty collections show “Content coming soon”.
Deck and progress routes are explicitly placeholders. Dashboard progress
values are dashes, not fabricated statistics. Settings can persist a light or
dark theme. No flashcard engine, progress database or SRS is implemented.

## Packages

- [flutter_riverpod](https://riverpod.dev/): dependency composition and
  async controller state, with provider overrides for isolated tests. Manual
  providers avoid adding code generation to this small foundation.
- [go_router](https://pub.dev/packages/go_router): declarative named routes,
  level/category URL context and invalid-parameter guards.
- [http](https://pub.dev/packages/http): injectable, timeout-bound JSON loading.
- [shared_preferences](https://pub.dev/packages/shared_preferences): simple
  settings only, using the asynchronous API.
- [path_provider](https://pub.dev/packages/path_provider): mobile application
  support directory for a separate JSON content cache.
- `flutter_test` and `flutter_lints`: behavior checks and standard linting.

Exact resolved versions are in `pubspec.lock`. No backend is introduced.

## Architecture

```text
lib/
  app/                     composition root, router, theme
  core/
    constants/             asset paths and optional remote configuration
    errors/                content failures
    network/               injectable HTTP client
    storage/               content cache and preferences boundaries
    utils/                 reserved shared pure utilities
    widgets/               responsive scaffold, loading/error presentation
  features/
    level_selection/       data catalog, JLPT types, selection presentation
    study_menu/            startup, home/dashboard, minimal menu
    vocabulary/            data sources, JSON models/mapping, repository,
                           immutable domain entities, async view model
    flashcards/            configuration contract and route placeholder
    progress/              future database repository contract and placeholder
    settings/              preferences controller and theme settings
  main.dart
```

UI watches Riverpod controller/view-model providers. Controllers call
repositories; repositories use local/remote data sources. Widgets do not parse
JSON, perform HTTP requests, or write preferences directly. `app/providers.dart`
composes concrete implementations; tests replace those dependencies. Local
content state is scoped by explicit JLPT level, avoiding the legacy implicit
selected-level singleton dependency.

Named routes are centralized in `app/router`: `/` startup, `/home`, `/levels`,
`/study/:level`, `/study/:level/deck/:category`, `/settings`, `/progress`.
N2 is the default selected level. Invalid enum parameters redirect to level
selection; unsupported but valid levels show a recoverable local-content error.
The router instance remains stable when preferences/theme change.

## JSON and offline foundation

`assets/data/n2.json` was migrated unchanged from the Ionic app's
`src/assets/datas/n2.json` at source commit
`c3f57ace3f11a37a784eeb308e8302cac76b274d`.
`LegacyVocabularyMapper` validates and maps the existing schema into immutable
cards with ID, word, reading, meanings, JLPT level, category, chapter, optional
examples/tags/difficulty. User progress is not stored on these cards.

The adapter maps `meaning` to a single-element `meanings` list; future JSON may
supply multiple `meanings` and explicit IDs. Legacy categories retain their
original keys, including `vocab_shinkansen` and plural `adverbs`. Chapter names
may be blank. Chapter IDs let future filtering distinguish repeated names.
Unknown JSON sections are ignored; add a category descriptor and mapping when
introducing another vocabulary collection. Grammar can have a separate
feature/schema while continuing to use static JSON.

Generated legacy card IDs are deterministic **ordinal** IDs scoped by
level/category/chapter. They are stable for the copied snapshot, but inserting
or reordering content changes them. Before Phase 5, assign published stable
IDs and define any legacy ID migration; do not attach durable learning history
to ordinal IDs without that policy.

`content-manifest.json` currently declares only `n2: {version: 1}`. This is the
Flutter bundled snapshot version, not an asserted version of the live gist.

- `loadLocal` validates cached JSON, validates the bundle, and returns the newer
  usable version without network access. Corrupt cache falls back to bundled
  data; valid cache remains usable if the bundle cannot be read.
- `checkForUpdate` fetches an optional remote manifest and downloads level JSON
  only if its version is newer. It validates before caching. Cache write failure
  does not invalidate usable downloaded content. Network/validation failures
  propagate to the caller, which must retain its displayed local snapshot.
- Content cache files contain `{version, json}` envelopes in the mobile support
  directory, written via a temporary file and rename. Preferences hold selected
  level, theme and the future shuffle preference. Future review records belong
  behind `ProgressRepository` in a local database.

Phase 1 exposes refresh infrastructure but does not run background sync.
Remote loading is disabled by default because no versioned remote manifest was
verified/published as part of this task. The legacy gist endpoint is retained
in constants as a reference. Once a matching manifest and `<level>.json` files
are published together under an HTTPS base URL, configure:

```sh
flutter run --dart-define=TOMO_CONTENT_BASE_URL=https://your-content-host/path/
```

The URL only configures the source; Phase 3 must wire background refresh into
controllers after local display. Future publishing must address atomic
manifest/content delivery, stable IDs, schema versions, concurrent updates,
and observable cache-write errors. This foundation does not claim a complete
synchronization protocol or import Capacitor preference/cache data.

## Migration scope and verification

See [the Ionic product audit](docs/legacy-product-audit.md), the
[Tomo v2 Migration Roadmap](#tomo-v2-migration-roadmap), and
[verification results](docs/verification.md).

Phase 2 should complete selection/menu UX and chapter navigation using these
contracts. Preserve the audit's observed flashcard behavior for Phase 4, while
explicitly deciding whether moving cards should hide revealed answers.

## Tomo v2 Migration Roadmap

1. **Phase 1 — Flutter foundation:** mobile hosts, Riverpod, declarative routes,
   Material 3 themes, dashboard, immutable content models, legacy JSON adapter,
   and version-aware content boundaries.
2. **Phase 2 — Level selection + study menu:** complete level and chapter UX.
3. **Phase 3 — JSON repository + offline content:** background version checks,
   cache diagnostics and safe content delivery.
4. **Phase 4 — Flashcard engine:** flip, navigation, filtering and shuffle.
5. **Phase 5 — Favorites + progress tracking:** stable content IDs and a local
   progress database.
6. **Phase 6 — SRS/review system:** scheduling, history and statistics.
7. **Phase 7 — Additional JLPT levels/content:** expand validated static data.
8. **Phase 8 — Testing, polish and release:** device coverage and store release.

## Branch layout

- `flutter-v2`: standalone root-level Flutter project.
- `main`: preserved Ionic/Angular application and its original content.

Generated Flutter, Gradle, CocoaPods and IDE output is excluded by
`.gitignore`. The large Ionic `node_modules` and `www` trees are absent from
this branch.
