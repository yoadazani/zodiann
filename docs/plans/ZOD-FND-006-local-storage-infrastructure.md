# ZOD-FND-006 Local Storage Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the two on-device storage mechanisms behind `packages/shared_storage`: a typed `shared_preferences` settings store and a drift (SQLite) store for `SquareConfig` at schema version 1 with a migration template, plus a typed failure path for blocked or full storage.

**Architecture:** `shared_storage` exposes two interfaces, `SettingsStore` (typed key-value) and `SquareStore` (saved squares), and one error type, `StorageException`. Feature code depends on the interfaces only. Implementations wrap `SharedPreferencesAsync` and a drift `AppDatabase`; every platform failure is translated to a `StorageException` and also announced on a `StorageFailureReporter` stream so the app layer (ZOD-NFR-014, banner wiring; NFR-015 is the audit) can show the banner. No production wiring in this task (the app wires it in ZOD-SET-007 and ZOD-DAT-002).

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_preferences` ^2.5.6, `drift` ^2.35.4, `sqlite3` ^3.9.1 (build-hook bundled SQLite), dev: `drift_dev` ^2.35.3, `build_runner`.

**Task:** `docs/development/foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md`. **Spec:** `assets/zodiann-specification.md` DATA-1, DATA-2, DATA-5..8, NFR-R1.

## Product-owner decisions (2026-11-22)

- **S1. SQLite source:** the `sqlite3` package default: its build hook downloads a precompiled SQLite from the package's GitHub release at **build time** (SHA-256 checked against references published in the package) and bundles it. The shipped app has no runtime network use. Not vendoring SQLite, not `source: system`.
- **S2. Settings API:** a generic typed key-value `SettingsStore`. `UserSettings` is **not** defined here; it stays with ZOD-SET-007 (its fields depend on open decisions D-1, D-3, D-5).

## Decisions made while planning (mine, for correction)

- **P1. Generic store, key registry.** `SettingsKey<T>` (name + type, `T` in bool, int, double, String, `List<String>`). Keys are declared by the feature that owns the setting; this task declares none except a test key.
- **P2. Schema v1 = one table, `saved_squares`:** `id` TEXT primary key, `name` TEXT, `config_json` TEXT (the whole `SquareConfig.toJson()`, so `HighlightRule` is the "nested JSON column" the task allows), `created_at` and `updated_at` INTEGER via `int()` columns, never drift's `dateTime()` (which stores seconds by default), as UTC milliseconds, for list ordering and so queries need no JSON parsing. `id`, `name` and the timestamps duplicate fields inside the JSON; the JSON is authoritative on read and the columns are checked against it by a test.
- **P3. Migration template:** drift's `schemaVersion` getter (= 1) is the version field. `migrations.dart` holds an ordered map of step functions and `applyMigrations(migrator, from, to)`: `from == to` is a no-op, a missing step or `from > to` throws `StorageException(unsupportedVersion)`. It is wired into `MigrationStrategy.onUpgrade`. The real step, the schema dumps and the process documentation are **ZOD-DAT-012's**; this task keeps the stub minimal. Drift calls `onUpgrade` for upgrades **and downgrades** (`from > to`) and never when `from == to`, so the v1→v1 no-op can only be exercised by calling `applyMigrations` directly; the downgrade case is tested through a real file at `user_version` 2 (Task 4).
- **P4. Generated drift code is committed** (`app_database.g.dart`), because CI does not run `build_runner`. It is formatted with `dart format` (the lint's `format:check` covers it). Staleness command, recorded in PROGRESS Conventions: `fvm dart run build_runner build && fvm dart format <generated file> && git diff --exit-code <generated file>`. The generated header's `ignore_for_file` must cover `--fatal-infos`, and the file must contain no `Crossing` identifier (the guard scans `lib/`). If these conflict, decide in Task 4 Step 5 and record a ruling.
- **P5. Failure path.** Stores throw `StorageException(kind, message, cause)`; `kind` is `unavailable` (cannot open, read-only, permission, I/O), `full` (SQLITE_FULL or the platform's equivalent), `corrupt` (unreadable row or value), `unsupportedVersion`. Before throwing, a store calls `StorageFailureReporter.report(failure)`. `list()` on `SquareStore` returns readable rows and reports each corrupt row instead of failing the whole list; each corrupt id is reported **once per store lifetime** (no re-announcing on every call). Corruption is handled the same way in both stores: `SquareStore.get` and `SettingsStore.read` of an unreadable or wrong-typed value **throw `corrupt`** (and report), so the caller defaults and the failure is not hidden.
- **P6. No row cap.** DATA-2's 100-square limit belongs to ZOD-DAT-002; the store does not enforce it. `SettingsStore.clear()` and `SquareStore.deleteAll()` are the wipe primitives; the "Delete all data" flow and confirmation are ZOD-DAT-010's.
- **P7. Database location** is passed in by the app (`openSquareStore(File)`); `shared_storage` does not call `path_provider`.
- **P8. Public surface** of `shared_storage.dart`: `SettingsStore`, `SettingsKey`, `PrefsSettingsStore`, `SquareStore`, `openSquareStore`, `StorageException`, `StorageFailureKind`, `StorageFailureReporter`. Not exported: `AppDatabase`, `DriftSquareStore`, `classifyStorageError` and any `drift` or `sqlite3` type (feature code never touches drift). Tests import `src/...`.
- **P9. Concurrency.** One writer per database file is supported. A second store over the same file in tests is read-after-close or sequential; `PRAGMA busy_timeout` is set in the executor setup so an accidental overlap waits instead of failing at once.

## Global Constraints

- `astro_core` and `gann_core` stay pure Dart; `shared_storage` may depend on `gann_core`, never the reverse.
- **No network at runtime (DATA-7, DATA-8):** `test/architecture/no_network_test.dart` stays green; no network package in any runtime closure; no network permission in the main manifest. A new hook-time download is recorded in `docs/licensing/third-party-inventory.md` and PROGRESS.
- Dependencies are `^x.y.z`, resolved against Flutter's pins (`test_api 0.7.14`, `matcher 0.12.20`, `material_color_utilities 0.13.0`); the lock file is committed.
- `Crossing` is never persisted: `test/architecture/crossing_not_persisted_test.dart` scans `packages/shared_storage/lib` and stays green.
- Run tools as `fvm flutter ...`, `fvm dart ...`, `fvm dart run melos ...`.
- Android and host only; iOS is **not verified** (no macOS), as for FND-003/EPH-004.
- No UI in this task; the red banner is ZOD-NFR-014's (it wires the banner to `StorageFailureReporter.failures` and needs a read-only degraded mode against last-known state). ZOD-NFR-015 is the app-wide input-handling audit that this task only "feeds".

## Review Focus

1. **Corrupt row:** one unreadable `config_json` must not hide the other saved squares or crash `list()` (Task 4).
2. **Same-id save:** saving an existing id replaces it (upsert), never duplicates; `created_at` is preserved by the caller's `SquareConfig`, not rewritten (Task 4).
3. **Anchor offset and every `HighlightMatch` variant** survive the round trip, including a non-UTC offset and a rule with `MultipleOfMatch` (Task 4).
4. **Store opened twice / reopened:** a second store over the same file sees the first's data; a reopened v1 file does not rerun `onCreate` or lose rows (Task 4).
5. **Write failure leaves old data intact:** a failed `save` (full disk) does not corrupt or drop existing rows, and a failed settings write does not change the stored value (Tasks 3 and 4).

---

### Task 1: Dependencies, package scaffold and network guards

**Files:**
- Modify: `packages/shared_storage/pubspec.yaml`, `pubspec.lock` (root), `docs/licensing/third-party-inventory.md`
- Modify: `apps/astro_mobile/pubspec.yaml` (dev dependency, below)
- Create: `packages/shared_storage/build.yaml` only if the format decision (P4) needs it; `packages/shared_storage/lib/src/` (via the first file in Task 2)

**Interfaces:**
- Produces: a resolvable `shared_storage` with `drift`, `shared_preferences`, `sqlite3` and `gann_core` (workspace) as dependencies, and `drift_dev`, `build_runner`, `shared_preferences_platform_interface` (test fakes; its absence would trip `depend_on_referenced_packages` under `--fatal-infos`) as dev dependencies; `path` only if the temp-file tests use `p.join`. `astro_mobile` gains `shared_storage` as a **dev_dependency (path)**, solely for the Task 5 integration test, with no production wiring, so the release closure is unchanged.

- [ ] **Step 1: Add dependencies** with caret constraints (edit the pubspecs, then `fvm flutter pub get` from the root).
- [ ] **Step 2: Resolution, architecture guards and a host smoke test.** Run from the root: `fvm dart test test/architecture/no_network_test.dart test/architecture/dependency_closure_test.dart`. Then add and run a one-statement host test in `packages/shared_storage` (`cd packages/shared_storage && fvm flutter test test/sqlite_smoke_test.dart`) that opens an in-memory drift/sqlite database and runs `SELECT 1`, proving the `sqlite3` build hook loads under `flutter test` on Windows before any TDD task. Expected: resolves; guards pass with the same 10 members; the smoke test passes (the smoke test is deleted once Task 4's tests cover the same ground). **If a network package (for example `http`) appears in a runtime closure, the resolution conflicts with Flutter's pins, or the hook cannot download or load: stop and report.** The whole-workspace `melos run test` is reserved for Task 5 Step 4.
- [ ] **Step 3: Record the licence inventory line** for drift (MIT), sqlite3 (MIT) and the SQLite binary it downloads at build time (public domain), including the SHA-pinned download and that it happens at build time only. Check each package's licence text, do not assume.
- [ ] **Step 4: Verify the Android debug build now**, the biggest feasibility risk: `cd apps/astro_mobile && fvm flutter build apk --debug`, and confirm the APK contains the bundled SQLite for each ABI. Also confirm the release closure is unchanged (the dev dependency is not in it; `no_network_test` still green with 10 members). **If the build hook cannot download or compile: stop and report before Tasks 2 to 4.**
- [ ] **Step 5: Commit** (`build(ZOD-FND-006): add the storage dependencies`).

### Task 2: `StorageException` and `StorageFailureReporter`

**Files:**
- Create: `packages/shared_storage/lib/src/storage_exception.dart`, `storage_failure_reporter.dart`; modify `lib/shared_storage.dart` (export)
- Test: `packages/shared_storage/test/storage_exception_test.dart`

**Interfaces:**
- Produces:
  - `enum StorageFailureKind { unavailable, full, corrupt, unsupportedVersion }`
  - `final class StorageException implements Exception { StorageException(this.kind, this.message, {this.cause}); }`
  - `final class StorageFailureReporter { Stream<StorageException> get failures; void report(StorageException e); void dispose(); }` (broadcast stream; reporting after dispose is a no-op)
  - `StorageException classifyStorageError(Object error)` (internal, not exported): first **unwraps** `DriftWrappedException.cause` and `DriftRemoteException.remoteCause` (errors from drift's background isolate arrive wrapped), then for a `SqliteException` switches on the **primary** `resultCode` (`extendedResultCode & 0xFF`), never the extended code: SQLITE_FULL (13) to `full`; SQLITE_READONLY (8), SQLITE_CANTOPEN (14), SQLITE_IOERR (10), SQLITE_PERM (3), SQLITE_BUSY (5), SQLITE_LOCKED (6) to `unavailable`; SQLITE_CORRUPT (11) and SQLITE_NOTADB (26) to `corrupt`; any other error to `unavailable`. (Verify the numbers against the `sqlite3` package constants.)

- [ ] **Step 1: Write failing tests** named for the behavior: `classifies SQLITE_FULL as full`, one test per other mapped code, extended codes `SQLITE_IOERR_WRITE` (778) maps to `unavailable` and `SQLITE_CORRUPT_INDEX` (779) maps to `corrupt`, `a wrapped SqliteException is unwrapped before classifying` (drift wrapped and remote forms), `an unknown error is unavailable`, `reporter delivers to every listener`, `report after dispose does nothing`, `toString names kind and message`.
- [ ] **Step 2: Run, confirm they fail** (symbols missing). Run: `cd packages/shared_storage && fvm flutter test test/storage_exception_test.dart`. Expected: compile failure.
- [ ] **Step 3: Implement** the three types in the files above.
- [ ] **Step 4: Run, confirm pass.**
- [ ] **Step 5: Commit** (`feat(ZOD-FND-006): add the typed storage failure`).

### Task 3: `SettingsStore` and the `shared_preferences` implementation

**Files:**
- Create: `packages/shared_storage/lib/src/settings_store.dart`, `prefs_settings_store.dart`; modify the barrel
- Test: `packages/shared_storage/test/prefs_settings_store_test.dart`

**Interfaces:**
- Consumes: `StorageException`, `StorageFailureReporter` (Task 2).
- Produces:
  - `final class SettingsKey<T> { const SettingsKey(this.name); final String name; }` (const, no assert: type parameters cannot appear in constant expressions). Supported `T`: bool, int, double, String, `List<String>`. `read`, `write` and `remove` throw `ArgumentError` for any other `T`, checked by `T == bool` and so on, with `List<String>` matched in its own branch.
  - `abstract interface class SettingsStore { Future<T?> read<T>(SettingsKey<T> key); Future<void> write<T>(SettingsKey<T> key, T value); Future<void> remove(SettingsKey<Object?> key); Future<void> clear(); }`
  - `final class PrefsSettingsStore implements SettingsStore { PrefsSettingsStore(SharedPreferencesAsync prefs, {StorageFailureReporter? reporter}); }`
- Note: use `SharedPreferencesAsync` with `SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty()` in tests (verify the exact test API in 2.5.6; if the legacy API is the only one that fits, record a ruling).

- [ ] **Step 1: Write failing tests:** `round-trips each supported type`, `a second store over the same backing sees the written value` (persistence across instances), `read of an unset key is null`, `remove deletes only that key`, `a stored value of the wrong type is reported and read throws corrupt` (P6), `a failing write throws StorageException unavailable, reports it, and leaves the stored value unchanged` (a fake platform with a **pre-written value** whose write throws `PlatformException`; after the failure a **healthy** store over the same backing reads the old value), `read and write with an unsupported key type throw ArgumentError`.
- [ ] **Step 2: Run, confirm they fail.** Expected: compile failure, then assertion failures for the second batch once stubs exist.
- [ ] **Step 3: Implement** the interface and `PrefsSettingsStore`; wrap every platform call, translating `PlatformException` and other errors to `StorageException(unavailable)` and reporting before rethrowing as the typed error.
- [ ] **Step 4: Run, confirm pass.**
- [ ] **Step 5: Commit** (`feat(ZOD-FND-006): add the typed settings store`).

### Task 4: drift schema v1, migration template and `SquareStore`

**Files:**
- Create: `packages/shared_storage/lib/src/database/app_database.dart` (+ committed `app_database.g.dart`), `database/migrations.dart`, `square_store.dart`, `drift_square_store.dart`; modify the barrel
- Test: `packages/shared_storage/test/migrations_test.dart`, `drift_square_store_test.dart`

**Interfaces:**
- Consumes: `StorageException`, `classifyStorageError`, `StorageFailureReporter`; `SquareConfig` (`gann_core`).
- Produces:
  - `abstract interface class SquareStore { Future<List<SquareConfig>> list(); Future<SquareConfig?> get(String id); Future<void> save(SquareConfig config); Future<void> delete(String id); Future<void> deleteAll(); Future<void> close(); }` (`list` is ordered by `updatedAt` descending, then `id`).
  - `final class DriftSquareStore implements SquareStore { DriftSquareStore(AppDatabase db, {StorageFailureReporter? reporter}); }` and `Future<SquareStore> openSquareStore(File file, {StorageFailureReporter? reporter})`.
  - `AppDatabase` with `static const int currentSchemaVersion = 1` returned by `schemaVersion`; `applyMigrations(Migrator m, int from, int to)` in `migrations.dart`.

- [ ] **Step 1: Write failing migration tests:** `from equal to to applies nothing` (direct call to `applyMigrations`), `a missing step throws unsupportedVersion`, `from greater than to throws unsupportedVersion`, `steps run in ascending order and only those after from` (an injected step map is the template test; the real step and process are ZOD-DAT-012's), `schemaVersion is 1`, and `a file at user_version 2 reopened through the store throws unsupportedVersion` (create the file with `PRAGMA user_version = 2`).
- [ ] **Step 2: Write failing store tests.** Most use an in-memory executor, with failures injected through drift's `QueryInterceptor` (`interceptWith`); a temp file is used for reopen tests and for the real-isolate tests below: `round-trips a SquareConfig with all fields` (every `SquareMode`, a non-UTC anchor offset, `AnglesMatch` and `MultipleOfMatch` rules, custom rule colour tokens and priorities, `stepHours` other than 4), `the default highlight rules round-trip`, `save with an existing id replaces the row`, `list is ordered by updatedAt descending`, `get of an unknown id is null`, `delete removes only that row`, `a reopened file returns the saved rows and does not rerun creation`, `a corrupt config_json is skipped by list, reported as corrupt, and get throws corrupt`, `table columns agree with the JSON` (P2), `a failing save keeps the previous row` and `a full disk throws StorageException full, reports it, and the previous rows are intact` (executor that throws `SqliteException` code 13 on write), `blocked storage on open throws unavailable` (code 14 on open), `deleteAll removes every row`, `two squares updated one millisecond apart order correctly` (P2 int columns), `a corrupt id is reported once per store lifetime` (P5), and the **real-isolate tests through `openSquareStore` and `NativeDatabase.createInBackground`**: `a file of garbage bytes throws StorageException corrupt` and `a read-only file or unusable directory throws unavailable`. Record the exception type actually observed on the real path as a ruling; the injected-executor tests alone are not evidence for production.
- [ ] **Step 3: Run, confirm they fail** (symbols missing). Run: `cd packages/shared_storage && fvm flutter test test/migrations_test.dart test/drift_square_store_test.dart`.
- [ ] **Step 4: Implement** the table, `AppDatabase` (`MigrationStrategy(onCreate: m.createAll, onUpgrade: applyMigrations)`, `PRAGMA busy_timeout` in setup), the migration runner, the store and `openSquareStore` (`NativeDatabase.createInBackground`), which **runs a first statement inside its try/catch** so lazy-open failures surface there, not on the first later call. Run `fvm dart run build_runner build` for the generated file.
- [ ] **Step 5: Run, confirm pass; run the P4 staleness command and `fvm dart run melos run lint`; both must be clean.**
- [ ] **Step 6: Commit** (`feat(ZOD-FND-006): add the drift square store at schema v1`).

### Task 5: Device persistence check, documentation, review, verification

**Files:**
- Create: `apps/astro_mobile/integration_test/storage_persistence_test.dart` (uses the dev dependency added in Task 1)
- Modify: `docs/development/foundations-architecture/ZOD-FND-006-...md` (status, criteria, notes; the first Implementation Details bullet is amended to the S2 decision, generic typed store with `UserSettings` in ZOD-SET-007, and the criterion "Settings persist across app restarts" is unchanged and satisfied by a generic key), `docs/development/TASKS.md`, `docs/PROGRESS.md`, and Notes in the consumers: ZOD-SET-007, ZOD-DAT-002, ZOD-DAT-010 (`deleteAll`), ZOD-DAT-012 (owns the real migration process), ZOD-NFR-014 (banner and read-only degraded mode via `StorageFailureReporter.failures`)

- [ ] **Step 1: "Settings persist across app restarts" on a real process restart.** Write a two-phase emulator check: phase 1 writes a key through `PrefsSettingsStore` and a square through `DriftSquareStore` to the app's real data directory; the app is force-stopped (`adb shell am force-stop`); phase 2 starts a fresh process and asserts both values. If the Flutter 3.50 emulator constraint (debug APK with `-t`, read from logcat) makes this impractical, stop and report instead of weakening the criterion.
- [ ] **Step 2: Confirm the release build has no network permission** and the new dependency did not change it (`aapt2 dump permissions` on a release or merged-manifest check, as in ZOD-FND-007).
- [ ] **Step 3: Request the fresh whole-branch review** (`requesting-code-review`), fix Critical and Important findings test-first.
- [ ] **Step 4: Run full verification:** `fvm dart run melos run lint`, `fvm dart run melos run test`, `fvm flutter build apk --debug`; record commands, results and head commit.
- [ ] **Step 5: Update documentation** (task file status and criteria, TASKS.md row, PROGRESS sections including the stale ZOD-EPH-004 "PR open, not merged" line, the `third-party-inventory` line, notes in the consuming tasks) and commit (`docs(ZOD-FND-006): ...`). Push and open the PR; do not merge without approval.

## Acceptance traceability

| Criterion | Evidence |
|---|---|
| Settings persist across restarts | Task 3 (second store over the same backing), Task 5 Step 1 (process restart) |
| `SquareConfig` round-trips with all `HighlightRule` fields | Task 4 round-trip tests |
| Full or blocked disk gives a typed error, no crash | Task 3 failing write, Task 4 full and blocked tests |
| Schema version present, v1→v1 no-op migration wired | Task 4 migration tests, `schemaVersion` = 1, `onUpgrade` wired |

## Risks and open items

- The `sqlite3` build hook downloads at build time. CI and any clean machine need GitHub access; offline builds fail until the artifact is cached. Recorded (S1), not mitigated.
- `sqlite3_flutter_libs` is end-of-life and is **not** used; the hook replaces it.
- Concurrent writers on one file are unsupported (P9).
- iOS is unverified.

## Plan review

**Round 1 (fresh `plan-reviewer`, 2026-11-22): Approve after corrections.** No Critical, no "needs user decision".

| ID | Finding | Disposition |
|---|---|---|
| I1 | Banner owner is ZOD-NFR-014, not NFR-015 | Applied (header, constraints, Task 5 notes) |
| I2 | Drift isolate wraps errors; injected-executor tests hide the production type; lazy open | Applied: unwrap helper, first statement in `openSquareStore`, real-isolate tests, `QueryInterceptor` named |
| I3 | `const SettingsKey<T>` cannot assert on `T` | Applied: const, no assert, `ArgumentError` at use, test renamed |
| I4 | Wrong Melos scope and `flutter test` path | Applied: root `dart test` for guards, `cd packages/shared_storage && flutter test`, melos only in Task 5 |
| I5 | Generated file vs `format:check` and staleness | Applied in P4 and Task 4 Step 5 (format then `git diff --exit-code`; decide by ruling if they conflict) |
| I6 | `shared_preferences_platform_interface` missing as dev dependency | Applied (Task 1) |
| I7 | Android build and integration dependency left undecided | Applied: `astro_mobile` dev_dependency, debug build and host smoke test in Task 1 |
| I8 | Overlap with ZOD-DAT-012; downgrade semantics | Applied (P3, Task 4 Step 1: real `user_version` 2 file test) |
| M1 | Use primary result code | Applied with extended-code tests |
| M2 | Barrel surface | Applied (P8) |
| M3 | `SquareStore.deleteAll` | Applied |
| M4 | Re-reporting corrupt rows | Applied: once per id per store lifetime |
| M5 | Corrupt behaviour inconsistent | Applied: both stores throw `corrupt` (P5/P6) |
| M6 | `int()` columns | Applied (P2) with an ordering test |
| M7 | Concurrent writers | Applied (P9: `busy_timeout`, single writer) |
| M8 | Task file wording | Applied (Task 5 files) |
| M9 | Weak settings failure test | Applied (pre-written value, healthy store reads) |
| M10 | `build.yaml` vague | Applied (only if P4 needs it) |

Open items: none needing a decision. Not verified by the reviewer: resolution of `drift_dev` with `build_runner` against Flutter's pins, and the Android hook build; Task 1 Steps 2 and 4 are the checks and stop and report on failure.
