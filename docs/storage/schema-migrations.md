# Changing the saved-squares database schema

How to change the SQLite schema in `packages/shared_storage` without corrupting
users' saved squares (spec DATA-1: "a schema version number and a migration when
the structure changes"). Established by ZOD-DAT-012 and proved by
`packages/shared_storage/test/migrations_test.dart`.

All paths below are relative to `packages/shared_storage` unless they start with
`docs/`. Run commands there, with `fvm` in front of `dart` and `flutter`.

## The model in four sentences

- `AppDatabase.currentSchemaVersion` (`lib/src/database/app_database.dart`) is
  the shipped schema version. It is stored in the SQLite file as `user_version`.
- `migrationSteps` (`lib/src/database/migrations.dart`) holds one step per
  version above 1, keyed by the version it produces: step `N` moves a database
  from `N - 1` to `N`.
- On open, drift compares the file's version with `currentSchemaVersion` and
  calls `applyMigrations`, which runs the steps in between, in order, **in one
  transaction**.
- Every shipped version has a committed dump in `drift_schemas/`, and the
  tests prove each upgrade keeps stored data.

## When a migration is needed

Any change to a table class in `app_database.dart`: a new column, a changed
type, nullability or default, a new or removed table, a new index. Changing only
Dart code around the tables needs none.

## Procedure

1. **Change the table class** (for example add `TextColumn get note => text().nullable()();`).
   Prefer additive, nullable (or defaulted) columns: they migrate with no data
   rewrite.
2. **Raise `AppDatabase.currentSchemaVersion`** by exactly one.
3. **Add the step** to `migrationSteps`, keyed by the new version. The map is
   `const` (it is the default of `applyMigrations`' `steps` parameter), so the
   step is a top-level function referenced by name, not a closure:

   ```dart
   Future<void> _toVersion2(Migrator m) async {
     final db = m.database as AppDatabase;
     await m.addColumn(db.savedSquares, db.savedSquares.note);
   }

   const Map<int, MigrationStep> migrationSteps = {2: _toVersion2};
   ```

   Use `Migrator` calls (`addColumn`, `createTable`, `createIndex`,
   `alterTable` for anything SQLite cannot `ALTER` directly). Never drop a table
   and recreate it to "migrate": that loses the rows.
4. **Regenerate and dump** (the staleness command list, below).
5. **Test it.** Copy the `rows written at v1 survive the upgrade unchanged`
   test in `test/migrations_test.dart`: start from `verifier.schemaAt(N - 1)`,
   insert rows through `rawDatabase`, open the real `AppDatabase`, call
   `verifier.migrateAndValidate(db, N)`, and assert the rows are unchanged and
   the new column has its default. The simulated v2 in
   `test/support/simulated_v2_database.dart` is the worked example.
6. **Run the guards.** `test/schema_dumps_test.dart` fails if a dump is missing
   or stale, if a dump above the current version exists, or if
   `migrationSteps` does not hold exactly the keys `2..currentSchemaVersion`.

## Regenerate and check for staleness

Run in `packages/shared_storage`, in this order. The first four write files, the
last two check them.

```text
1. fvm dart run build_runner build
2. fvm dart run drift_dev schema dump lib/src/database/app_database.dart drift_schemas
3. fvm dart run drift_dev schema dump test/support/simulated_v2_database.dart test/schemas
4. fvm dart run drift_dev schema generate test/schemas test/generated_migrations
5. fvm dart format lib/src/database/app_database.g.dart test/support/simulated_v2_database.g.dart test/generated_migrations
6. git diff --exit-code lib/src/database drift_schemas test/support test/schemas test/generated_migrations
```

On a Windows checkout add `--ignore-cr-at-eol` to step 6 (the generated
`.g.dart` files are rewritten with LF).

Commands 3 and 4 serve the **simulated** v2 used to prove the framework. When
the first real version 2 ships, replace the simulation with the real one: dump
`AppDatabase` into `test/schemas` instead (its `drift_schema_v2.json` then
equals the one in `drift_schemas/`), delete `SimulatedV2Database`, and keep the
rest. Until then the shipped schema is version 1 (ZOD-DAT-012, owner decision).

## Never

- Edit a committed dump in `drift_schemas/` or a shipped step. A version that
  has reached a user is history; fix mistakes with a **new** version.
- Skip a version, or reuse a version number.
- Write a "down" migration. A file written by a newer app is refused
  (`StorageException(unsupportedVersion)`) and left untouched.
- Toggle `PRAGMA foreign_keys` inside a step: it is a no-op inside a
  transaction. A step that rebuilds a table referenced by foreign keys needs its
  own handling and a decision at that time (no table has a foreign key today).

## What happens when a step fails

Drift runs `onUpgrade` without a transaction and writes the new `user_version`
only after it returns, so a step that failed part-way would leave its schema
change in the file at the old version, and the next launch would run the step
again and fail. `applyMigrations` therefore checks the whole range first (a
newer file or a missing step throws `unsupportedVersion` before anything
runs), then runs every step inside one transaction: on any failure the file
rolls back to the old version with all its rows, and a corrected app can
retry. Both behaviours are tested (`a step that throws leaves the file at v1`,
`a failed upgrade can be retried`).
