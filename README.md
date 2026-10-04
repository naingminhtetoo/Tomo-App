# Tomo

Japanese Study Companion. The existing Ionic/Angular application is preserved
at the repository root. Tomo v2 is a separate Flutter application in
[`flutter_app/`](flutter_app/README.md), developed on `flutter-v2`.

The original application uses Angular 20, Ionic 8 and Capacitor 7. It starts
at level selection, supports N2, and offers six vocabulary/kanji collections
through a shared flashcard screen. Its source, assets, native Android project,
`node_modules`, and `www` remain as migration references. Use the existing npm
scripts (`npm start`, `npm run build`) for the Ionic project.

Read the [source audit](flutter_app/docs/legacy-product-audit.md) for observed
navigation, flashcard behavior, remote/cache loading and content counts.

## Tomo v2 Migration Roadmap

1. **Phase 1 — Flutter foundation:** mobile hosts, Riverpod, declarative routes,
   Material 3 themes, minimal dashboard, immutable content models, legacy JSON
   adapter, local content read and versioned remote update boundaries.
2. **Phase 2 — Level selection + study menu:** complete availability behavior,
   selected-level navigation, chapter selection, empty/loading/error states,
   accessibility and device navigation checks.
3. **Phase 3 — JSON repository + offline content:** publish a versioned manifest,
   display local content immediately, orchestrate background version checks,
   refresh status, cache diagnostics and safe update delivery.
4. **Phase 4 — Flashcard engine:** flip, previous/next, chapter filtering,
   non-mutating shuffle, restart confirmation and session behavior.
5. **Phase 5 — Favorites + progress tracking:** publish stable content IDs,
   introduce a database-backed progress repository and migration rules.
6. **Phase 6 — SRS/review system:** scheduling, review history and statistics.
7. **Phase 7 — Additional JLPT levels/content:** expand validated JSON assets,
   categories and grammar content without introducing a backend server.
8. **Phase 8 — Testing, polish and release:** device coverage, content validation,
   platform polish, signing and release readiness.

## Repository hygiene

`node_modules` and `www` are currently tracked. They are deliberately retained.
The new root ignore rules prevent adding more generated output; ignore rules
do not remove already tracked files. In a separately approved cleanup phase,
consider untracking generated dependencies/output, auditing existing Android
build artifacts and documenting reproducible Ionic builds. Do not mix that
cleanup with the Flutter migration. Flutter has its own scoped `.gitignore`,
and its application dependency lockfile is committed.
