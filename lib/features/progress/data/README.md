# Local learning state

`DriftProgressRepository` implements the existing `ProgressRepository` boundary.
It uses `core/database/AppDatabase` schema version 1. Shared content remains
JSON; SQLite stores content IDs and dynamic user state only. SharedPreferences
is limited to small settings. Supabase is deferred.

The four tables cover progress, review events, historical sessions and the
unfinished-session pointer/order. Review + history + counters + resume index
commit in one Drift transaction. Favorite/difficult upserts preserve all review
fields. Queries calculate chapter and daily progress from records rather than
stored percentages. Incremental migrations must be supplied before raising
schemaVersion; no destructive reset is used. See the root README for schemas,
query definitions and scheduling limitations.
