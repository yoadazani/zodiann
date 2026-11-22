# ZOD-DAT-012 Drift schema migration framework: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential). Steps use checkbox (`- [ ]`) syntax. No work here is independent enough for subagents: the three tasks share one test directory, one generated helper and one document.

**Goal:** Turn the `applyMigrations` stub from ZOD-FND-006 into a proven, documented process: committed schema dumps, a migration test that moves stored data from v1 to a simulated v2 (nullable column added) with no loss, guards that keep dumps and steps in step with `schemaVersion`, and a how-to a later task can follow without re-deriving it.

**Architecture:** The **shipped schema stays at v1** (owner decision D1): no unused column ships, `AppDatabase.currentSchemaVersion` and `migrationSteps` are unchanged. The framework is proved on a **test-only database class** (`SimulatedV2Database`) that has the same `SavedSquares` table plus one nullable column, schema version 2, and whose `onUpgrade` calls the real `applyMigrations` with an injected one-step map. drift's official tooling is used (owner decision D2): `drift_dev schema dump` writes one JSON per version, `drift_dev schema generate` writes the `SchemaVerifier` helper, and `SchemaVerifier.migrateAndValidate` proves the migrated schema equals a fresh one.

**Tech Stack:** Dart 3.14 / Flutter 3.50, `drift ^2.35.4`, `drift_dev ^2.35.3` (already dev dependencies of `packages/shared_storage`), `sqlite3`, `flutter_test`. No new dependency.

**Spec:** `assets/zodiann-specification.md` DATA-1 ("a schema version number and a migration when the structure changes"); task file `docs/development/settings-persistence/ZOD-DAT-012-implement-the-drift-schema-migration-framework.md`; the stub `packages/shared_storage/lib/src/database/migrations.dart` and `docs/plans/ZOD-FND-006-local-storage-infrastructure.md`.

## Product-owner decisions

- **D1 (2026-11-22): stay at v1, prove v2 on a test-only class.** Reason: nothing is wired and no user data exists; the real v2 ships with the first task that needs a column. The task note's "first real step" is read as "the first real, tested step of the process".
- **D2 (2026-11-22): use drift's schema tooling** (dumps committed, generated verifier helper).
- **D3 (mine):** the committed v1 dump lives in `packages/shared_storage/drift_schemas/` (real versions only). The test-only dumps and generated helper live under `test/` and carry their own v1 copy; a test asserts the copy equals the real v1 dump so the two cannot drift apart.
- **D4 (mine):** the simulated step is `ALTER TABLE ... ADD COLUMN` through `Migrator.addColumn` (the additive nullable-column case the task names).

## Global Constraints

- DATA-1: a schema version number and a migration when the structure changes.
- No new dependency (`pubspec.yaml` unchanged); no change to `AppDatabase`, `SquareStore`, `StorageException` or any public export of `shared_storage`. The one planned `lib/` behaviour change is in `applyMigrations` (Task 2): the step range runs inside one transaction (review I1).
- Generated and dumped files are committed and share one staleness command list, run in `packages/shared_storage` (the same list goes verbatim into the process doc; Task 3 verifies it leaves a clean diff):
  1. `fvm dart run build_runner build`
  2. `fvm dart run drift_dev schema dump lib/src/database/app_database.dart drift_schemas`
  3. `fvm dart run drift_dev schema dump test/support/simulated_v2_database.dart test/schemas`
  4. `fvm dart run drift_dev schema generate test/schemas test/generated_migrations`
  5. `fvm dart format` on every generated `.dart` file
  6. `git diff --exit-code` on `lib/src/database`, `drift_schemas`, `test/support`, `test/schemas`, `test/generated_migrations`
  (`build_runner` also builds the test directory; there is no `build.yaml`, no config change.)
- Commands: `fvm flutter test`, `fvm dart run ...`; static checks use the CI forms (`docs/ci.md`): `fvm dart run melos run lint` (format check and `analyze --fatal-infos`) and `fvm dart run melos run test`; per-package quick check `fvm dart analyze --fatal-infos` in `packages/shared_storage`. Import style as in the existing tests. Never stage `grep.exe.stackdump`.
- Owner item kept open and out of scope: Android Auto Backup / iOS iCloud exclusion before stores are wired.

## Review Focus

- A step that throws part-way (after a successful `addColumn`) must not leave a half-migrated file. **Drift does not roll back by itself** (`drift-2.35.4` `db_base.dart:127` runs `onUpgrade` from `beforeOpen` with no `BEGIN`; `engines.dart:528` writes `user_version` only afterwards), so a failed step would leave the new column with `user_version` 1 and every later launch would fail with "duplicate column name". `applyMigrations` therefore runs the whole step range in `migrator.database.transaction(...)`. Tests in Task 2: file stays at v1 with rows and no new column; reopening with a corrected step succeeds.
- A multi-step chain (v1 to v3) runs every step once, in order, and keeps data. Test in Task 2.
- A file written by a newer app (`user_version` above the app's) is refused with `unsupportedVersion` and is not modified. Test in Task 2 (extends the existing FND-006 test: file bytes and `user_version` unchanged and no `-journal` file left; `openSquareStore` sets only `busy_timeout`, no WAL, so byte equality is feasible).
- An empty v1 database (no rows) migrates. Test in Task 2.
- A shipped version bump without a dump or a step, or a stale dump above the current version (the most likely future mistakes), fails CI. Guard tests in Task 1.

---

## File structure

- Create `packages/shared_storage/drift_schemas/drift_schema_v1.json`: dump of the shipped v1 schema (real, committed).
- Create `packages/shared_storage/test/support/simulated_v2_database.dart`: test-only `SimulatedV2Database` (+ its table class and one-step map).
- Create `packages/shared_storage/test/schemas/drift_schema_v1.json`, `drift_schema_v2.json`: dumps used by the verifier (v2 from the simulated class).
- Create `packages/shared_storage/test/generated_migrations/` (`schema.dart`, `schema_v1.dart`, `schema_v2.dart`): output of `drift_dev schema generate`.
- Modify `packages/shared_storage/test/migrations_test.dart`: add the migration tests (new groups; existing tests untouched).
- Create `packages/shared_storage/test/schema_dumps_test.dart`: the staleness and consistency guards.
- Create `docs/storage/schema-migrations.md`: the process.
- Modify `packages/shared_storage/lib/src/database/migrations.dart` (doc comment only: point to the process doc), `app_database.dart` (doc comment on `currentSchemaVersion` only).
- Update task file, `docs/development/TASKS.md`, `docs/PROGRESS.md`.

---

### Task 1: Dumps, simulated v2 class, generated helper, guards

**Files:** as listed above (all `Create` except none modified).

**Interfaces:**
- Produces: `@DriftDatabase(tables: [SavedSquaresV2]) class SimulatedV2Database extends _$SimulatedV2Database` in `test/support/simulated_v2_database.dart` (`part 'simulated_v2_database.g.dart'`), `SimulatedV2Database(super.e)`, `schemaVersion == 2`, `onCreate: (m) => m.createAll()`, `onUpgrade: (m, from, to) => applyMigrations(m, from, to, steps: simulatedSteps)`. The table class is `SavedSquaresV2 extends Table` with `@override String get tableName => 'saved_squares'`, the five `SavedSquares` columns and `TextColumn get note => text().nullable()()` (generated row type `SavedSquaresV2Data`; tests read rows with `customSelect` to stay independent of it). `final Map<int, MigrationStep> simulatedSteps = {2: (m) { final db = m.database as SimulatedV2Database; return m.addColumn(db.savedSquaresV2, db.savedSquaresV2.note); }}` (a top-level step has only the `Migrator`, so it reaches the table through `m.database`).
- Produces: `SchemaVerifier(GeneratedHelper)` helper via `test/generated_migrations/schema.dart` (`GeneratedHelper`, `schema_v1.dart`'s `DatabaseAtV1`, `schema_v2.dart`'s `DatabaseAtV2`).
- Consumes: `applyMigrations`, `MigrationStep` from `lib/src/database/migrations.dart`.

- [ ] **Step 1: Write the failing guard tests** in `test/schema_dumps_test.dart`:
  - `'the committed dump of the current version matches the live schema'`: open `AppDatabase(NativeDatabase.memory())`, read `sqlite_master.sql` for `saved_squares`, and compare with the `CREATE TABLE` text in `drift_schemas/drift_schema_${AppDatabase.currentSchemaVersion}.json` (`fixed_sql` of the table entity, compared after whitespace normalisation); this catches defaults, constraints and the primary key, not only column names. Fails first because the dump does not exist.
  - `'the dump versions are exactly 1 to currentSchemaVersion'`: the set of `drift_schema_v<N>.json` files in `drift_schemas/` equals `{1..currentSchemaVersion}` (also catches a stale future dump).
  - `'migrationSteps has exactly the keys 2..currentSchemaVersion'`: `expect(migrationSteps.keys.toSet(), equals(<int>{for (var v = 2; v <= AppDatabase.currentSchemaVersion; v++) v}))` (note `equals`: `Set ==` is identity). Vacuous at v1 by design; its mutation proof (Task 2 step 4) sets `migrationSteps` to `{2: _noStep}` at version 1 and must turn it red.
  - `'the test copy of the v1 dump equals the real one'`: byte-equal `test/schemas/drift_schema_v1.json` and `drift_schemas/drift_schema_v1.json`.
- [ ] **Step 2: Run** `fvm flutter test test/schema_dumps_test.dart` in `packages/shared_storage`. Expected: FAIL (missing files).
- [ ] **Step 3: Produce the files, in this order.** (1) Re-run staleness command 2; keep the already-generated `drift_schemas/drift_schema_v1.json` only if it is reproduced byte for byte. (2) Write `SimulatedV2Database`. (3) Command 1 (`build_runner`). (4) Copy the real v1 dump to `test/schemas/drift_schema_v1.json`. (5) Command 3 (writes `test/schemas/drift_schema_v2.json`). (6) Command 4. (7) Command 5.
- [ ] **Step 4: Run** the guard tests and `fvm dart analyze --fatal-infos`. Expected: PASS, analyzer clean (add `// ignore_for_file` only if the generated header lacks it; do not widen `analysis_options.yaml`).
- [ ] **Step 5: Commit** `test(ZOD-DAT-012): add schema dumps, simulated v2 and dump guards`.

### Task 2: The migration tests

**Files:** Modify `test/migrations_test.dart`.

**Interfaces:** Consumes Task 1's `SimulatedV2Database`, `simulatedSteps`, `SchemaVerifier`, `DatabaseAtV1`, `DatabaseAtV2`.

- [ ] **Step 1: Write the failing tests** (a `group('v1 to simulated v2')`, using `SchemaVerifier(GeneratedHelper())`):
  - `'rows written at v1 survive the upgrade unchanged'`: `final schema = await verifier.schemaAt(1); schema.rawDatabase.execute('INSERT INTO saved_squares ...', [...])` for three rows (distinct `id`, `name`, `config_json` strings including non-ASCII, `created_at`, `updated_at`); do **not** close `rawDatabase` (it backs `newConnection`); `final db = SimulatedV2Database(schema.newConnection()); addTearDown(db.close); await verifier.migrateAndValidate(db, 2);` then `customSelect('SELECT * FROM saved_squares ORDER BY id')`: same three rows, field for field, and `note` is `null` for each. This is acceptance criterion 1. (`testWithDataIntegrity` is not used: it generates its own data for the generated schema classes; here the rows are chosen to include the real shape of `config_json`.)
  - `'the migrated schema equals a fresh v2 schema'`: the `migrateAndValidate` call itself (it fails on any structural difference); also assert the column set contains `note` with nullable true.
  - `'an empty v1 database migrates'`: same with no rows.
  - `'a chain of steps runs every step once, in order, and keeps data'`: migrator from `DatabaseAtV1(schema.newConnection()).createMigrator()` (rows inserted through `rawDatabase` as above); call `applyMigrations(m, 1, 3, steps: {2: raw-SQL step, 3: recording step})` where step 2 is `m.database.customStatement('ALTER TABLE saved_squares ADD COLUMN note TEXT')`; assert `ran == [2, 3]`, the rows, and the `note` column via `PRAGMA table_info`. This calls the function directly, so it neither sets `user_version` nor validates a schema; it is a chain test, not a "v3 schema".
  - `'a step that throws leaves the file at v1 with its rows'`: create a v1 file in a temp directory (`AppDatabase(NativeDatabase(file))`, one row, `await close()`); open it as `SimulatedV2Database` with a step map whose step 2 does `addColumn` then throws a `StateError`; the failure surfaces when the database first opens (force it with a first statement inside `expectLater(..., throwsStateError)`; await `close()` inside the test, not only in `tearDown`); then with plain `sqlite3` assert `PRAGMA user_version == 1`, no `note` column, the row intact. RED reason on the unmodified framework: the `note` column is present.
  - `'a failed upgrade can be retried with a corrected step'`: continue from the failed file: open it again with a correct step map; expect it opens, ends at `user_version` 2, rows intact, `note` present.
  - `'a file from a newer app is refused and left untouched'`: extend the existing `user_version = 2` case: record the file bytes and the temp-directory listing before; after the `await expectLater` and after the store is closed assert `user_version` is still 2, the bytes are equal and no `-journal` file appeared.
- [ ] **Step 2: Run** `fvm flutter test test/migrations_test.dart`. Expected: the data-survival, empty, chain and newer-file tests PASS (the framework already does this), the failed-step and retry tests FAIL because the `note` column is left behind.
- [ ] **Step 3: Implement the planned `lib/` change** in `applyMigrations` (`migrations.dart`): keep the `from == to`, `from > to` and missing-step checks before any work (validate the whole range first so nothing runs when a step is missing), then run the step loop inside `await migrator.database.transaction(() async { ... })`. Update its doc comment (atomic, why: drift runs `onUpgrade` without a transaction). Check that `m.addColumn`, raw statements and `Migrator.alterTable` (which nests a transaction) work inside it; if one does not, stop and report. List this change in PROGRESS.
- [ ] **Step 4: Mutation proof** (record results in the plan's Completion notes): (a) drop the step map entry, (b) make `applyMigrations` skip the last step, (c) run steps in descending order, (d) make the upgrade `dropTable` then recreate, (e) remove the transaction wrapper, (f) set `migrationSteps` to `{2: _noStep}` at version 1; each must turn at least one named test red ((e): the failed-step test; (f): the key-set guard). Revert each.
- [ ] **Step 5: Run** the whole package `fvm flutter test` and `fvm dart analyze --fatal-infos`; **Commit** `feat(ZOD-DAT-012): run migration steps atomically and prove v1 to v2 keeps stored data`.

### Task 3: The process document and records

**Files:** Create `docs/storage/schema-migrations.md`; modify the two doc comments; task file, `TASKS.md`, `PROGRESS.md`.

- [ ] **Step 1: Write `docs/storage/schema-migrations.md`**, covering exactly: when a migration is needed (any table or column change); the numbered procedure (1 change the table class, 2 bump `AppDatabase.currentSchemaVersion`, 3 add `N: (m) async { ... }` to `migrationSteps` using `Migrator` calls, never raw table drops, 4 run `build_runner`, 5 `drift_dev schema dump` to `drift_schemas/`, 6 add the new version to the simulated-verifier chain: regenerate helpers with the exact commands, 7 add a data-survival test per the template in `migrations_test.dart`, 8 run the guards); the exact commands (Windows/`fvm`); the staleness command list verbatim (Global Constraints); what never to do (edit a shipped dump, change a published step, downgrade, skip a version); the failure behaviour (`unsupportedVersion`; the step range is atomic and why, because drift does not roll back); a worked example pointing at the simulated v2.
- [ ] **Step 1b: Walk the doc.** Criterion 2 is subjective; the evidence is (a) every path and command in the document exists or runs (run the staleness list, expect a clean `git diff --exit-code`), and (b) a recorded walk of the procedure against the simulated v2 showing each step maps to a file in this task.
- [ ] **Step 2: Update the two doc comments** (`migrations.dart`, `app_database.dart`) to point at the document; no code change. Run `fvm dart analyze` and the package tests again.
- [ ] **Step 3: Records.** Task file: tick both criteria with evidence and a Completion note (shipped schema stays v1 by owner decision; the real v2 belongs to the first task that needs it); `TASKS.md` status; `PROGRESS.md` (Completed Tasks row with commands and head commit, Current Task, Next Recommended, Technical Decisions D1 to D4, Git State).
- [ ] **Step 4: Verification** (`verification-before-completion`): `fvm flutter test` and `fvm dart analyze --fatal-infos` in `packages/shared_storage`; then the CI forms `fvm dart run melos run test` and `fvm dart run melos run lint`; record exit codes and counts and the head commit.
- [ ] **Step 5: Commit** `docs(ZOD-DAT-012): document the migration process and record verification`; push; open the PR.

## Risks and open items

- Drift does not roll back a failed `onUpgrade` (read in the drift source, review I1); the transaction wrapper is the fix and is proved by test and mutation (e).
- `drift_dev schema generate` output style may need formatting or a lint ignore; handled in Task 1.
- iOS is not exercised (pure SQLite logic on the host; the same code path as Android).
- The simulated class adds a second `part` / generated file to the test tree; its staleness command is documented in Task 3.

## Self-review

Spec coverage: DATA-1 migration and version, criterion 1 (Task 2 first test), criterion 2 (Task 3). Types: `simulatedSteps`, `SimulatedV2Database`, `GeneratedHelper` used consistently. One planned `lib/` change: `applyMigrations` runs the range in one transaction.

## Plan review

### Round 1 (verdict: approve after corrections; no product-owner decision needed)

| ID | Severity | Finding | Done |
|---|---|---|---|
| I1 | Important | Drift does not roll back a failed `onUpgrade` (`db_base.dart:127`, `engines.dart:528`); the atomicity test would fail on the unmodified framework and a failed step would brick the file | Applied: `applyMigrations` runs the range in one transaction (planned `lib/` change, Task 2 step 3), retry test, mutation (e), Review Focus and constraints reworded |
| I2 | Important | Test-data flow with `SchemaVerifier` wrong (`rawDatabase` must not be closed) | Applied: insert through `rawDatabase`, `newConnection`, `addTearDown`; `testWithDataIntegrity` reasoned out |
| I3 | Important | `simulatedSteps` could not compile | Applied: reaches the table through `m.database`; `SavedSquaresV2` with `tableName`, part file name, row reading via `customSelect` |
| I4 | Important | Chain test cannot reuse the v2 step body | Applied: raw SQL step on a `DatabaseAtV1` migrator, no "v3 schema" claim |
| I5 | Important | `Set ==` is identity | Applied: `equals(...)`, vacuity stated, mutation (f) |
| I6 | Important | No executable staleness check for dumps and helpers | Applied: six-command list, whole `fixed_sql` comparison, list goes into the doc and Task 3 verifies it |
| M1 to M7 | Minor | Failure-test set-up, journal check, doc evidence for criterion 2, ordering, untracked noise, CI command forms, stale future dump | All applied |

Open items: none. Round 2 pending.
