# ZOD-L10-014 Missing-Translation-Key CI Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** L-8's "a test fails when a key is missing in one of the languages" is met by a named, runnable test that is proven to fail, through the real file-discovery path, when a key is missing from `app_en.arb` or `app_he.arb`, and is shown by configuration (and by the PR's `Core` and `Full suite` checks) to run in CI.

**Architecture:** The test already exists from ZOD-L10-001: `test/architecture/l10n_key_parity_test.dart` (helpers in `arb_keys.dart`, unit-tested by `arb_keys_test.dart`). It runs in the `Core` job (`dart test test/architecture`) and in `Full suite` (`melos run test`, root is a Melos package). This task does **not** add a second parity test. It closes the one gap: the pure helpers are unit-tested, but nothing proves the *file-reading wiring* (directory scan, filename regex, `l10n.yaml` lookup) reports a missing key. Today that wiring lives inside `setUpAll`, so it cannot be exercised on a fixture directory.

**Tech Stack:** Dart `package:test` at the workspace root. No new dependencies.

**Spec:** `assets/zodiann-specification.md` L-8 (line 577). Task: `docs/development/localization/ZOD-L10-014-implement-the-missing-translation-key-ci-test.md`. CI: `docs/ci.md`, `.github/workflows/ci.yml`.

## Global Constraints

- Root `test/architecture/` guards are pure Dart (`package:test`), no Flutter imports.
- The ARB files in `packages/shared_ui/lib/l10n/` are never edited in committed form; the mutation proof edits and then restores them (`git diff --stat` must be empty for them afterwards).
- Task acceptance criteria are not changed.
- Every local command below is run through FVM (`fvm dart test …`, `fvm dart analyze …`, `fvm dart format …`, `fvm dart run melos …`); CI uses its own SDK setup.

## Review Focus

- A key removed from `app_he.arb` only → failure names `app_he.arb` and the key.
- A key removed from `app_en.arb` (the template) → failure names `app_he.arb` as having a key not in the template, and `app_en.arb` is not itself reported as missing it.
- A third language file added without all keys (L-1 adds languages) → that file is reported.
- A non-ARB file (`notes.txt`, `app_en.arb.bak`) in the l10n directory is ignored, not parsed.
- `@key` metadata entries and `@@locale` are not counted as message keys (already pinned in `arb_keys_test.dart`; confirm unchanged).

## Decisions

- **No new test file for the parity rule.** Duplicating `l10n_key_parity_test.dart` would give two tests for one rule. The existing test name `every language has exactly the template's keys` is the named test.
- **Extract, don't rewrite.** The directory-loading logic moves, unchanged in behavior, from `setUpAll` into a function in `arb_keys.dart`, so a test can point it at a temp directory.

## File Structure

- Modify `test/architecture/arb_keys.dart`: add `loadArbSources`.
- Modify `test/architecture/l10n_key_parity_test.dart`: call `loadArbSources` instead of inlining.
- Modify `test/architecture/arb_keys_test.dart`: end-to-end tests on temp directories.
- Modify `docs/ci.md` (one sentence naming the test and its proof), task file status, `docs/development/TASKS.md`, `docs/PROGRESS.md`.

## Tasks

### Task 1: Make the file-reading wiring testable (TDD)

**Files:** modify `test/architecture/arb_keys.dart`, `test/architecture/arb_keys_test.dart`, `test/architecture/l10n_key_parity_test.dart`.

**Interfaces:**
- Produces: `({String template, Map<String, String> sources}) loadArbSources(String packageDir)` in `arb_keys.dart`. It reads `<packageDir>/l10n.yaml` for `arb-dir` and `template-arb-file` (same regex as today's `_yamlValue`, failing with `<packageDir>/l10n.yaml has no <key>`), and returns `sources` keyed by filename, for files in `<packageDir>/<arb-dir>` whose name matches `^app_[A-Za-z_]+\.arb$`, valued by file content. `arb_keys.dart` currently imports only `dart:convert`; add `import 'dart:io';` and `import 'package:test/test.dart';` (for `fail`; `package:test` is already a root dev dependency).

- [ ] **Step 1: Write failing tests** in `arb_keys_test.dart`, group `loadArbSources + keyParityProblems on a fixture package`. Each test builds a temp package dir (`Directory.systemTemp.createTempSync`, deleted in `tearDown`) with `l10n.yaml` (`arb-dir: lib/l10n`, `template-arb-file: app_en.arb`) and ARB files, then runs `loadArbSources` and `keyParityProblems(template, {file: arbMessageKeys(src)})`:
  - `all keys present → no problems`.
  - `a key missing from app_he.arb → ['app_he.arb is missing: <key>']`.
  - `a key removed from the template → ['app_he.arb has keys not in app_en.arb: <key>']`.
  - `a third language missing a key is reported by name` (add `app_fr.arb`).
  - `non-ARB files are ignored` (`notes.txt`, `app_en.arb.bak` are absent from `sources.keys`).
  - `l10n.yaml without arb-dir fails naming the file` and the same for `template-arb-file` (`throwsA(isA<TestFailure>())`).
  - Fixture ARB files include `@key` and `@@locale` entries; the `all keys present` test must pass with them (they are not counted).
- [ ] **Step 2: Run** `dart test test/architecture/arb_keys_test.dart`. Expected: FAIL, `loadArbSources` undefined.
- [ ] **Step 3: Implement** `loadArbSources` by moving `_yamlValue` and the `setUpAll` body from `l10n_key_parity_test.dart` into `arb_keys.dart`. The test file then calls `loadArbSources(_package)` in `setUpAll` and drops its own `_yamlValue`.
- [ ] **Step 4: Run** `dart test test/architecture/arb_keys_test.dart test/architecture/l10n_key_parity_test.dart`. Expected: all PASS.
- [ ] **Step 5: Commit** `test(ZOD-L10-014): prove the key-parity wiring on fixture packages`.

### Task 2: Mutation proof on the real ARB files and the CI path

**Files:** none committed (proof recorded in PROGRESS).

- [ ] **Step 1:** Precondition: `git status --short packages/shared_ui` is clean. Delete one whole `"key": "value",` line (not the last entry; leave its `@key` entry) from `app_he.arb`; run `dart test test/architecture/l10n_key_parity_test.dart`. Expected: the parity test FAILS with `app_he.arb is missing: <key>`; others pass. Restore via `git checkout -- packages/shared_ui/lib/l10n/app_he.arb`.
- [ ] **Step 2:** Same with `app_en.arb` (same precondition and line rule). Expected: FAIL naming `app_he.arb has keys not in app_en.arb: <key>`. Restore.
- [ ] **Step 3:** Confirm the Full-suite path covers the root: run `fvm dart run melos list --dir-exists=test --no-flutter` and confirm the root package is listed; then `fvm dart run melos exec --scope=zodiann_workspace --dir-exists=test --no-flutter -- dart test test/architecture/l10n_key_parity_test.dart` (the root package is `zodiann_workspace`; the file exists only there, so the scope is required) and confirm it ran only in the root and passed. Optionally record that `fvm dart run melos run test:dart` output includes the architecture tests. Record the output. Also confirm `ci.yml` `Core` runs `dart test test/architecture` (pinned by `ci_workflow_test.dart`). If the root is not listed, report it as a finding. After the PR is open, record its `Core` and `Full suite` results.
- [ ] **Step 4:** `git status --short packages/shared_ui` is empty.

### Task 3: Documentation and verification

- [ ] **Step 1:** Add one sentence to the `docs/ci.md` notes (the `Core` row already says "L-8 key parity"; do not duplicate it) naming the specific L-8 test, `l10n_key_parity_test.dart` › `every language has exactly the template's keys`, and the proof method (fixture-package tests plus a recorded mutation run) is `l10n_key_parity_test.dart` › `every language has exactly the template's keys`, with the proof method.
- [ ] **Step 2:** Run `dart test test/architecture`, `dart analyze --fatal-infos test`, `dart format --output=none --set-exit-if-changed test`. Record results.
- [ ] **Step 3:** Update the task file `Status` to Done and tick its criterion, `TASKS.md` row to Done, `PROGRESS.md` (Completed Tasks, Current Task, Next Recommended, Git State, Verification with commands and commit).
- [ ] **Step 4:** Commit `docs(ZOD-L10-014): record the verified state`, then independent whole-branch review, push, PR (skill Section 8).

## Risks

- Low. The change is test infrastructure only. The one behavior risk is the extraction changing discovery; Task 1 step 4 plus Task 2 confirm it.
- Subagents: none; the tasks are sequential and touch the same files.

## Plan review

### Round 1 (plan-reviewer)

- **Verdict:** approve after corrections. No Critical findings.
- **I1 (Important):** `fail` not available in `arb_keys.dart`. Applied: Task 1 now adds the `dart:io` and `package:test` imports.
- **I2 (Important):** Task 2 step 3 did not show the root is in the Melos test path. Applied: it now uses `melos list` and `melos exec` and records the output.
- **M1:** Goal reworded (applied). **M2:** mutation precondition and line rule (applied). **M3:** `template-arb-file` test and `@key`/`@@locale` fixtures (applied). **M4:** ci.md sentence names the test, no duplication (applied).
- **Needs user decision:** none.

### Round 2 (plan-reviewer), first attempt

- The first round 2 ran against the plan before the round 1 corrections were on disk (my edit step failed), so its "not resolved" findings were stale. Its one new finding was **I3 (Important): commands must use `fvm`**. Applied as a Global Constraint. Round 2 is re-run on commit range 29d1520..HEAD.

### Round 2 (plan-reviewer), on 29d1520..5eace51

- **Verdict:** approve after corrections. No Critical findings. I1, I2 (in intent), M1 to M4 confirmed resolved.
- **I3 (Important, fvm):** applied as a Global Constraint (this also covers M5).
- **I4 (Important):** the `melos exec` in Task 2 step 3 would run the root-only test path in every package. Applied: added `--scope=zodiann_workspace` and removed the quotes.
- **M6:** ci.md sentence grammar (applied).
- **Needs user decision:** none. Two rounds are used; no open items.
