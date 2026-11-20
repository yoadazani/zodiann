# ZOD-FND-004 Set up the CI pipeline: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential). No work here is independent enough for subagents: every task edits or depends on the one workflow file, and the later tasks observe the earlier ones on GitHub.

**Goal:** Run the project's tests and static checks on every push and pull request in GitHub Actions, with a fast required "core" job (`astro_core`, `gann_core` plus the root architecture guards), a required lint job, a required full-suite job, and a recorded runtime for each, so a failing core test, a Flutter import in a core package, or a missing ARB key blocks a merge.

**Architecture:** One workflow, `.github/workflows/ci.yml`, with three independent jobs (`core`, `lint`, `full`) that all install the Flutter SDK pinned in `.fvmrc` and point Melos at it through `MELOS_SDK_PATH`. Every command a job runs is an existing Melos script or `dart test` call; the only new code is a small cross-platform Dart timer (`tool/ci/`) that wraps a command, records its duration and warns when a budget is exceeded, and a guard test that pins the workflow's shape. "Blocked from merge" is a GitHub repository ruleset on `main` requiring the three checks; that is an outward-facing setting and needs the owner's approval (open decision O2).

**Tech Stack:** GitHub Actions, `subosito/flutter-action` and `actions/checkout` / `actions/upload-artifact` (each pinned to a full commit SHA), Melos 8 (`melos.yaml` scripts in the root `pubspec.yaml`), Dart 3.14 / Flutter 3.50.0, `package:test`, `package:yaml` (root dev dependency only if already in `pubspec.lock`; see Task 2).

**Spec:** `assets/zodiann-specification.md`: "Automated tests in the pipeline" (line 686), ARCH-2 (line 550), L-8 (line 577), NFR-R3 (pinned versions, line 641). Task file: `docs/development/foundations-architecture/ZOD-FND-004-set-up-the-ci-pipeline.md`. Dependency: ZOD-FND-001 (done). Consumers that extend this work and are **not** done here: ZOD-L10-014 (missing-key test, already present as `test/architecture/l10n_key_parity_test.dart`), ZOD-TST-017 (Gate 1 required-checks group), ZOD-UI-015 (visual regression harness).

## Global Constraints

- Everything pinned: actions by full commit SHA with the tag in a trailing comment, the Flutter SDK by `.fvmrc` (`3.50.0`). NFR-R3: "All libraries are pinned to a fixed version".
- Pure-Dart core (ARCH-2): `astro_core` and `gann_core` must not depend on Flutter or import `dart:ui` (already enforced by `test/architecture/pure_dart_test.dart`; CI must run it in the required core job).
- L-8: "a test fails when a key is missing in one of the languages" (`test/architecture/l10n_key_parity_test.dart`, plus `melos run l10n:check` for stale generated output).
- Melos scripts select packages with `melos exec` CLI filters, never `packageFilters` (comment in the root `pubspec.yaml`). Nested calls use `dart run melos`. Do not change `melos.yaml` scripts' meaning.
- The workflow has `permissions: contents: read` and no secrets, no network calls other than `pub get` and the SDK/action downloads (NFR-R3: no data sent to third parties).
- Development is on Windows; the local shell's `dart` is 3.6.0, so every local command in this plan runs with the pinned SDK first on `PATH` (`/c/Users/user/fvm/versions/3.50.0/bin`).
- No CI job builds an app, signs anything or publishes anything. No macOS runner (iOS stays outstanding, see PROGRESS Blockers).

## Review Focus

1. **The runner's operating system changes the result of pixel/font tests.** The `*_fidelity_test.dart`, `drawer_reference_test.dart`, `tag_sheet_test.dart` and `test/design/*_png_test.dart` suites were calibrated on Windows. Expected: the full job is green on whichever OS runs it; if Linux fails, the fix is a runner choice recorded as a decision, never a loosened tolerance or a skipped test (Task 4).
2. **A required check that never reports blocks every merge.** Expected: no `paths`/`paths-ignore` filters, job names stable and equal to the ruleset's contexts, push and PR both produce the three checks (Tasks 2, 6).
3. **Melos may not honour `MELOS_SDK_PATH`** (the root `sdkPath: .fvm/flutter_sdk` is a symlink to a user path that does not exist on a runner). Expected: `melos run test` resolves the pinned SDK on a clean runner; a wrong SDK fails loudly instead of silently using another Dart (Task 3, Task 4).
4. **A timer that swallows the wrapped command's failure.** Expected: `tool/ci/timed.dart` exits with the wrapped command's exit code, including signals and "command not found" (Task 1).
5. **Core-only analyze scope drifting.** A new core package added later would be unguarded. Expected: the guard test fails if `pure_dart_test.dart`'s `corePackages` and the workflow's core package list differ (Task 2).

## Open decisions (need the product owner before the step that uses them)

- **O1: Runner OS for the full suite.** Recommended: run `core` and `lint` on `ubuntu-latest`, and the `full` job on `ubuntu-latest` if Task 4 proves it green with no test changes, otherwise on `windows-latest` (the OS the tests were calibrated on). The plan makes this an observed result, not a guess. Matrix on both is not recommended (double runtime, no extra gate).
- **O2: Repository ruleset on `main` (outward-facing setting).** The branch is currently unprotected, so acceptance criterion 1 ("a PR with a failing core test is blocked from merge") cannot be true without it. Recommended: a ruleset requiring the checks `Core`, `Lint` and `Full suite` to pass, blocking force pushes and deletion of `main`, requiring a PR, **with no bypass actor** so the criterion is provable; the owner can still change it later. Alternative: bypass for the repository admin (an emergency path, but a red PR can then be merged by the owner). Task 6 does not start until the owner picks.
- **O3: Runtime budget.** The timer warns (non-failing) when a step exceeds a budget. Recommended initial budgets: core 5 min, full suite 1.5 times the first green run rounded up to the minute (set from Task 4's measurement and recorded in `docs/ci.md`). The owner can tighten it later.
- **O4: Trigger scope.** The task says "every push/PR", so the plan triggers on `push` (all branches) and `pull_request`. A PR branch therefore runs twice (one run per event, same checks). Alternative: `push` on `main` only plus `pull_request`, halving the runs with no loss of gating. Recommended: the literal reading (all pushes); Actions on a public repository is free.

## Out of scope

Android/iOS builds, release signing, store uploads (ZOD-REL-*); the Gate 1 required-checks group and its documentation (ZOD-TST-017); the visual regression harness (ZOD-UI-015); a Mac runner or the iOS verification outstanding from ZOD-FND-005/008; dependency-update bots; code coverage upload; changing any existing test, tolerance or Melos script.

## File Structure

- Create `.github/workflows/ci.yml`: the three jobs.
- Create `tool/ci/timing.dart`: pure functions `formatCsvRow`, `formatSummaryRow`, `budgetWarning`.
- Create `tool/ci/timed.dart`: the command wrapper (`dart run tool/ci/timed.dart <label> [--budget-seconds N] -- <command> [args...]`).
- Create `test/tool/ci_timing_test.dart`: unit tests for `timing.dart` and an end-to-end test of `timed.dart`.
- Create `test/architecture/ci_workflow_test.dart`: pins the workflow's shape (Task 2).
- Create `docs/ci.md`: what each job runs, the required checks, how to read the timing, baseline runtimes, how to reproduce a job locally.
- Modify the root `pubspec.yaml` only to add `yaml` under `dev_dependencies` (if already resolved in `pubspec.lock`) and regenerate `pubspec.lock`.
- Modify `docs/development/TASKS.md`, the task file's `Status`, and `docs/PROGRESS.md` (Task 7).

---

### Task 1: The timing wrapper `tool/ci/timed.dart`

**Files:** Create `tool/ci/timing.dart`, `tool/ci/timed.dart`, `test/tool/ci_timing_test.dart`.

**Interfaces:**
- Produces (`timing.dart`):
  - `String formatCsvRow(String label, Duration elapsed, int exitCode)` → `label,<seconds with one decimal>,<exitCode>\n`.
  - `String formatSummaryRow(String label, Duration elapsed, int exitCode)` → a Markdown table row `| label | 12.3 s | ok |` (`ok` when 0, `FAILED (n)` otherwise).
  - `String? budgetWarning(String label, Duration elapsed, int? budgetSeconds)` → `::warning title=CI runtime budget::<label> took <s> s, budget <n> s` when `elapsed` exceeds a non-null budget, else `null`.
- Produces (`timed.dart`): a `main(List<String> args)` that runs the command after `--` with inherited stdio, measures wall time, appends `formatCsvRow` to the file named by `CI_TIMING_FILE` (default `build/ci-timing.csv`, parent directory created), appends `formatSummaryRow` to the file named by `GITHUB_STEP_SUMMARY` when set (writing the table header first if the file has none from this tool), prints `budgetWarning` when non-null, and exits with the command's exit code (127 when the executable cannot be started, 2 on a usage error).

- [ ] **Step 1: Write the failing tests** in `test/tool/ci_timing_test.dart`:
  - `formatCsvRow('core', Duration(milliseconds: 12345), 0)` equals `'core,12.3,0\n'`.
  - `formatSummaryRow` equals `'| core | 12.3 s | ok |\n'` for exit 0 and `'| core | 12.3 s | FAILED (3) |\n'` for exit 3.
  - `budgetWarning` returns `null` when under budget, when the budget is `null`, and exactly at the budget; returns the `::warning title=CI runtime budget::core took 61.0 s, budget 60 s` line at 61 s over 60.
  - End to end (spawn `Platform.resolvedExecutable tool/ci/timed.dart t -- <dart> --version`) exits 0 and writes one CSV line to a temp `CI_TIMING_FILE`; spawning with a wrapped command that exits 7 (`<dart> -e`-style: run a tiny temp `.dart` file with `exit(7)`) exits 7 **and** still writes the row with exit code 7; a nonexistent executable exits 127; no `--` exits 2.
- [ ] **Step 2: Run to verify it fails.** `export PATH=/c/Users/user/fvm/versions/3.50.0/bin:$PATH; dart test test/tool/ci_timing_test.dart`. Expected: FAIL, "Target of URI doesn't exist: 'tool/ci/timing.dart'" (or equivalent).
- [ ] **Step 3: Implement** `timing.dart` (pure functions above) and `timed.dart` (argument parsing by hand, no new dependency; `Process.start(..., mode: ProcessStartMode.inheritStdio)`; `runInShell: Platform.isWindows` so `.bat` shims such as `flutter` resolve; a `ProcessException` maps to 127).
- [ ] **Step 4: Run to verify it passes.** Same command. Expected: all tests pass.
- [ ] **Step 5: Format and analyze the new files.** `dart format tool/ci test/tool/ci_timing_test.dart` then `dart analyze --fatal-infos tool/ci test/tool`. Expected: no changes, no issues.
- [ ] **Step 6: Commit.** `git add tool/ci test/tool/ci_timing_test.dart && git commit -m "feat(ZOD-FND-004): add the CI step timer"` (with the attribution trailer).

### Task 2: The workflow and its guard test

**Files:** Create `.github/workflows/ci.yml`, `test/architecture/ci_workflow_test.dart`; Modify root `pubspec.yaml` / `pubspec.lock` (add `yaml` only if `grep -n "^  yaml:" pubspec.lock` shows it already resolved; otherwise parse with line-oriented checks and add no dependency).

**Interfaces:**
- Consumes: `Task 1` `tool/ci/timed.dart` CLI; `pure_dart_test.dart`'s `corePackages = ['astro_core', 'gann_core']`.
- Produces: three jobs whose `name:` values are exactly `Core`, `Lint`, `Full suite` (job ids `core`, `lint`, `full`). These names are the ruleset's required contexts in Task 6.

- [ ] **Step 1: Write the failing guard test** `test/architecture/ci_workflow_test.dart`, loading `.github/workflows/ci.yml` and asserting:
  - triggers include `push` and `pull_request`, and neither has `paths` / `paths-ignore` / `branches-ignore` (Review Focus 2);
  - workflow `permissions` is exactly `{contents: read}`;
  - jobs `core`, `lint`, `full` exist with `name` `Core`, `Lint`, `Full suite`, each with a numeric `timeout-minutes`;
  - every `uses:` is `owner/repo@<40-hex SHA>` (Review Focus: pinning), ignoring `./` local actions;
  - no step in `core` runs `flutter test` or `melos run test:flutter`;
  - the `core` job's analyze command names every package in `corePackages` and contains `--fatal-warnings`; its `dart test` command names every one of them (Review Focus 5);
  - the `core` job runs `test/architecture` (the ARCH-2 and L-8 guards);
  - `lint` runs `melos run lint`; `full` runs `melos run test`;
  - every job sets `MELOS_SDK_PATH` and reads the Flutter version from `.fvmrc` (no hard-coded version string equal to the `.fvmrc` value in the workflow, so the two cannot drift).
- [ ] **Step 2: Run to verify it fails.** `dart test test/architecture/ci_workflow_test.dart`. Expected: FAIL, workflow file not found.
- [ ] **Step 3: Resolve the action SHAs.** For `actions/checkout`, `subosito/flutter-action` and `actions/upload-artifact`, take the latest release tag at least two weeks old and resolve its commit with `gh api repos/<owner>/<repo>/git/ref/tags/<tag> --jq .object.sha` (dereference annotated tags with `git/tags/<sha>`). Record tag and SHA in `docs/ci.md`.
- [ ] **Step 4: Write `.github/workflows/ci.yml`.**
  - `on: push` (all branches) and `pull_request`; `concurrency` group `ci-${{ github.ref }}` with `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}`; `permissions: contents: read`; `defaults.run.shell: bash` so Windows and Linux share syntax.
  - Common setup steps in each job: checkout (`persist-credentials: false`); read the version (`jq -r .flutter .fvmrc` into a step output); `subosito/flutter-action` with that version, `channel: stable`, pub cache enabled; export `MELOS_SDK_PATH=$FLUTTER_ROOT` (`$GITHUB_ENV`); `dart pub get` at the root (workspace resolution); print `dart --version` and `flutter --version`.
  - `core` (`Core`, `ubuntu-latest`, `timeout-minutes: 15`): `dart run tool/ci/timed.dart analyze-core --budget-seconds 300 -- dart analyze --fatal-warnings --fatal-infos packages/astro_core packages/gann_core`; `... core-tests -- dart run melos exec --scope="astro_core,gann_core" "dart test"` (use the existing `melos exec` filter style; if `--scope` cannot express two packages in this Melos, use two `--scope` flags or `--dir-exists` plus a package-name filter, whichever the local run in Task 3 proves); `... architecture -- dart test test/architecture`; upload `build/ci-timing.csv` as artifact `ci-timing-core`.
  - `lint` (`Lint`, `ubuntu-latest`, `timeout-minutes: 20`): `timed.dart lint -- dart run melos run lint`; upload timing artifact.
  - `full` (`Full suite`, OS per O1, `timeout-minutes: 45`): `timed.dart full-suite --budget-seconds <O3> -- dart run melos run test`; upload timing artifact; a final step prints `build/ci-timing.csv` into the job summary.
  - Do not give the `full` job `needs: core`: independent jobs report in parallel and each is its own required check. (A failing core shows up in seconds.)
- [ ] **Step 5: Run the guard test to verify it passes.** Expected: all pass. Also run `dart format --output=none --set-exit-if-changed test/architecture/ci_workflow_test.dart` and `dart analyze --fatal-infos test/architecture`.
- [ ] **Step 6: Mutation check on the guard (prove it can fail).** For each of: remove `--fatal-warnings`; replace one SHA with a tag; add `paths-ignore`; rename `Core`; add `flutter test` to `core`; drop `gann_core` from the analyze line, edit the workflow, confirm exactly the matching test fails, then restore. Record the six results in the Verification notes.
- [ ] **Step 7: Commit.** `feat(ZOD-FND-004): add the CI workflow and its guard test`.

### Task 3: Run each job's commands locally with the pinned SDK

**Files:** none changed unless a command needs correcting (then fix it in `ci.yml` and re-run Task 2's guard test).

- [ ] **Step 1:** `export PATH=/c/Users/user/fvm/versions/3.50.0/bin:$PATH; export MELOS_SDK_PATH=/c/Users/user/fvm/versions/3.50.0` and run the `core` job's three commands exactly as written in `ci.yml` (from the repository root). Expected: exit 0 each; `build/ci-timing.csv` has three rows. Confirm `melos exec` selected exactly `astro_core` and `gann_core` (the output names them).
- [ ] **Step 2:** Temporarily rename `.fvm` (`mv .fvm .fvm.off`) to simulate the runner, run `dart run melos run lint` with `MELOS_SDK_PATH` set; expected: green. Then `unset MELOS_SDK_PATH` and run again; expected: fails naming the missing SDK (so a wrong environment fails loudly, Review Focus 3). Restore `.fvm`.
- [ ] **Step 3:** Run the `full` job's command (`melos run test`) via the timer; record the local wall time as the Windows baseline (the background run started during planning is the first sample).
- [ ] **Step 4:** If Melos does not honour `MELOS_SDK_PATH`, replace it with a step that creates `.fvm/flutter_sdk` as a symlink to `$FLUTTER_ROOT` on Linux (and a junction via `cmd //c mklink /J` on Windows), keep the guard test's SDK assertion in line, and note the decision in PROGRESS Technical Decisions.

### Task 4: First runs on GitHub; resolve the runner question (O1)

- [ ] **Step 1:** Push the branch (`git push -u origin task/ZOD-FND-004-ci-pipeline`) and open a **draft** PR into `main` (`gh pr create --draft`). Watch with `gh run list --branch <branch> --limit 4` and `gh run view <id>`; the first push also tests that the token's `workflow` scope can push a workflow file.
- [ ] **Step 2:** Expected: `Core` and `Lint` green on `ubuntu-latest`. If `Full suite` fails on Linux, read only the failing excerpts (`gh run view --log-failed`), classify each failure as a pixel/font difference or a real defect. A real defect gets a test-first fix. A pixel/font difference does not get a loosened tolerance: switch the `full` job to `windows-latest`, push, and record the evidence and the decision (O1) in PROGRESS Technical Decisions and `docs/ci.md`.
- [ ] **Step 3:** Once all three are green, record each job's duration and the full suite's wall time (from the timing artifact and `gh run view`). Set the O3 `--budget-seconds` for the full job to 1.5 times the full-suite time rounded up to the minute; re-run the guard test; commit `chore(ZOD-FND-004): set the full-suite runtime budget`.

### Task 5: Prove the three blocking criteria with throwaway branches

Each proof is a branch off the task branch that is pushed, opened as a draft PR, observed red, then **closed without merging and its branch deleted**. Nothing from these branches reaches `main`.

- [ ] **Step 1 (criterion 1, failing core test):** branch `ci-proof/failing-core-test`; change one expected literal in a `gann_core` test; push; expected `Core` red (`core-tests` step) and `Full suite` red.
- [ ] **Step 2 (criterion 2, UI import in core):** branch `ci-proof/core-flutter-import`; add `import 'package:flutter/foundation.dart';` to a file under `packages/astro_core/lib/` (and, separately in the same branch's second commit, `import 'dart:ui';` in `gann_core`); expected `Core` red from `architecture` (ARCH-2 test) and, for the import, the analyzer.
- [ ] **Step 3 (L-8, missing ARB key):** branch `ci-proof/missing-arb-key`; delete one key from the Hebrew ARB; expected `Core` red (`l10n_key_parity_test`) and `Lint` red (`l10n:check` if the generated output goes stale).
- [ ] **Step 4 (analyzer warning in core):** branch `ci-proof/core-analyzer-warning`; add an unused local variable in `astro_core/lib`; expected `Core` red at `analyze-core`.
- [ ] **Step 5:** Record run URLs and which step failed in `docs/ci.md` (Verification evidence), close the four PRs with `gh pr close --delete-branch`, and confirm `git branch -r` shows no `ci-proof/*` left.

### Task 6: Make the checks block a merge (after the owner decides O2)

- [ ] **Step 1:** Show the owner the exact ruleset (target `refs/heads/main`; required status checks `Core`, `Lint`, `Full suite`; require a pull request; block force pushes and deletion; bypass per O2) and wait for approval. Do not create it before.
- [ ] **Step 2:** Create it with `gh api -X POST repos/yoadazani/zodiann/rulesets --input <json file in the scratchpad>`; read it back with `gh api repos/yoadazani/zodiann/rulesets` and save the returned JSON (without tokens) to `docs/ci.md` as the recorded configuration.
- [ ] **Step 3 (prove criterion 1 end to end):** reopen a proof PR from Task 5 step 1 (or push it again), confirm `gh pr view --json mergeStateStatus,mergeable` reports it blocked and `gh pr merge` is refused; close it without merging. Also confirm this task's own PR can be merged once green.

### Task 7: Documentation and records (after Tasks 1 to 6 pass)

- [ ] **Step 1:** Write `docs/ci.md`: jobs and the commands each runs; the required check names; how to reproduce each job locally (including the pinned-SDK `PATH` note); where timing lives (job summary table, `ci-timing-*` artifacts); the baseline durations and budget; the action SHAs and tags and how to update them; the ruleset JSON; what is deliberately not covered (iOS, Gate 1 group, visual harness).
- [ ] **Step 2:** Set ZOD-FND-004's `Status` to completed in the task file and `TASKS.md` only after the verification below passes; leave the acceptance criteria text unchanged and tick them with evidence references. Add to the task file a Note pointing at `docs/ci.md` (the existing L10 note stays).
- [ ] **Step 3:** Update `docs/PROGRESS.md`: Project Status line, Completed Tasks entry with commands, results and the commit; Current Task; Next Recommended Task (and remove the "Note for ZOD-FND-004"); Technical Decisions (O1 to O4 outcomes, `MELOS_SDK_PATH` or the symlink fallback, the dependency on `yaml` if added); Verification; Git State (branch, PR).
- [ ] **Step 4: Verification before completion** (`superpowers:verification-before-completion`), with the pinned SDK on `PATH`: `dart run melos run lint`; `dart run melos run test`; `dart test test/tool/ci_timing_test.dart test/architecture/ci_workflow_test.dart`; the latest `gh run` for the branch head shows `Core`, `Lint`, `Full suite` all `success`. Record counts and the head commit.
- [ ] **Step 5:** Independent whole-branch code review (`superpowers:requesting-code-review`), resolve findings, then commit and push per the skill's Section 8, add the PR link in a small follow-up commit, and recommend the next task.

---

## Self-review (writing-plans checklist)

- **Spec coverage:** all four Implementation Details bullets and three Acceptance Criteria map to tasks: run `melos run test` on every push/PR (Tasks 2, 4); fast core job separate from the full suite (Task 2); ARB key failure (core `architecture` and `lint`, proved in Task 5 step 3); core analyzer failure (Task 2, proved in Task 5 step 4); failing core test blocks merge (Tasks 5 and 6); UI import fails CI (Task 5 step 2); runtime tracked (Task 1, Task 4 step 3, `docs/ci.md`). The task-file note (CI needs the pinned Flutter SDK) is handled by the version read and `MELOS_SDK_PATH`.
- **Names:** job ids `core`/`lint`/`full`, names `Core`/`Lint`/`Full suite`, files `tool/ci/timed.dart`, `tool/ci/timing.dart` are used identically across tasks.
- **Proportion:** the only new code is a small timer and two tests; the rest is workflow configuration, observation on GitHub and documentation.
- **Known uncertainties, stated not hidden:** Linux behaviour of pixel tests (O1, Task 4); `MELOS_SDK_PATH` support (Task 3 step 4); the `melos exec` filter form for two packages (Task 3 step 1); the latest-but-two-weeks-old action tags (Task 2 step 3).

## Plan review

*(to be added after the plan-reviewer cycle)*
