# ZOD-FND-004 Set up the CI pipeline: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential). No work here is independent enough for subagents: every task edits or depends on the one workflow file, and the later tasks observe the earlier ones on GitHub.

**Goal:** Run the project's tests and static checks on every push to `main` and every pull request targeting `main` (O4) in GitHub Actions, with a fast required "core" job (`astro_core`, `gann_core` plus the root architecture guards), a required lint job, a required full-suite job, and a recorded runtime for each, so a failing core test, a Flutter import in a core package, or a missing ARB key blocks a merge.

**Architecture:** One workflow, `.github/workflows/ci.yml`, with three independent jobs (`core`, `lint`, `full`) that all install the Flutter SDK pinned in `.fvmrc` and point Melos at it through `MELOS_SDK_PATH`. Every command a job runs is an existing Melos script or `dart test` call; the only new code is a small cross-platform Dart timer (`tool/ci/`) that wraps a command, records its duration and warns when a budget is exceeded, and a guard test that pins the workflow's shape. "Blocked from merge" is a GitHub repository ruleset on `main` requiring the three checks; that is an outward-facing setting and needs the owner's approval (approved decision O2).

**Tech Stack:** GitHub Actions, `subosito/flutter-action` and `actions/checkout` / `actions/upload-artifact` (each pinned to a full commit SHA), Melos 8 (`melos.yaml` scripts in the root `pubspec.yaml`), Dart 3.14 / Flutter 3.50.0, `package:test`, `package:yaml` (root dev dependency; already resolved transitively in `pubspec.lock`, see Task 2).

**Spec:** `assets/zodiann-specification.md`: "Automated tests in the pipeline" (line 686), ARCH-2 (line 550), L-8 (line 577), NFR-R3 (pinned versions, line 641). Task file: `docs/development/foundations-architecture/ZOD-FND-004-set-up-the-ci-pipeline.md`. Dependency: ZOD-FND-001 (done). Consumers that extend this work and are **not** done here: ZOD-L10-014 (missing-key test, already present as `test/architecture/l10n_key_parity_test.dart`), ZOD-TST-017 (Gate 1 required-checks group), ZOD-UI-015 (visual regression harness).

## Global Constraints

- Everything pinned: actions by full commit SHA with the tag in a trailing comment, the Flutter SDK by `.fvmrc` (`3.50.0`). NFR-R3: "All libraries are pinned to a fixed version".
- Pure-Dart core (ARCH-2): `astro_core` and `gann_core` must not depend on Flutter or import `dart:ui` (already enforced by `test/architecture/pure_dart_test.dart`; CI must run it in the required core job).
- L-8: "a test fails when a key is missing in one of the languages" (`test/architecture/l10n_key_parity_test.dart`, plus `melos run l10n:check` for stale generated output).
- Melos scripts select packages with `melos exec` CLI filters, never `packageFilters` (comment in the root `pubspec.yaml`). Nested calls use `dart run melos`. Do not change `melos.yaml` scripts' meaning.
- The workflow has `permissions: contents: read` and no secrets; it downloads only the actions and the Flutter SDK (from GitHub and Google) and pub packages (pub.dev). It sends no data to third parties (NFR-R3).
- Baseline (local Windows, 2026-11-20, pinned SDK): `melos run test` takes 2 min 29 s wall (astro_core 60 tests, gann_core 196, root 317, astro_mobile 208, shared_ui 638, plus feature_wheel), all passing on `main` at `0599611`.
- Development is on Windows; the local shell's `dart` is 3.6.0, so every local command in this plan runs with the pinned SDK first on `PATH` (`/c/Users/user/fvm/versions/3.50.0/bin`).
- No CI job builds an app, signs anything or publishes anything. No macOS runner (iOS stays outstanding, see PROGRESS Blockers).

## Review Focus

1. **The runner's operating system changes the result of pixel/font tests.** The `*_fidelity_test.dart`, `drawer_reference_test.dart`, `tag_sheet_test.dart` and `test/design/*_png_test.dart` suites were calibrated on Windows. Expected: the full job is green on `ubuntu-latest` (O1); a failure is investigated and reported to the owner, never met with a loosened tolerance, an altered golden or a skipped test (Task 4).
2. **A required check that never reports blocks every merge.** Expected: no `paths`/`paths-ignore` filters, job names stable and equal to the ruleset's contexts, push and PR both produce the three checks (Tasks 2, 6).
3. **Melos may not honour `MELOS_SDK_PATH`** (the root `sdkPath: .fvm/flutter_sdk` is a symlink to a user path that does not exist on a runner). Expected: `melos run test` resolves the pinned SDK on a clean runner; a wrong SDK fails loudly instead of silently using another Dart (Task 3, Task 4).
4. **A timer that swallows the wrapped command's failure.** Expected: `tool/ci/timed.dart` exits with the wrapped command's exit code, including signals and "command not found" (Task 1).
5. **Line endings.** Local working trees are CRLF (`core.autocrlf=true`, no `.gitattributes`); a Linux checkout is LF. Expected: text-hash and generated-output guards (launcher manifest hashes, `l10n:check` snapshot, icon generator, `format:check`) give the same verdict on the runner as locally (these guards also run in the required `Core` and `Lint` jobs); a difference is classified as a line-ending difference, not a pixel difference or a defect (Task 4).
6. **Core-only analyze scope drifting.** A new core package added later would be unguarded. Expected: the guard test fails if `pure_dart_test.dart`'s `corePackages` and the workflow's core package list differ (Task 2).

## Owner decisions (approved 2026-11-20; these override the recommendations below where they differ)

- **O1 (amended 2026-11-20, see below):** all three jobs on `ubuntu-latest`, no Docker. **Amendment:** after the first Ubuntu run failed two compact degree-scale fidelity cases (platform rasterisation, calibrated on Windows), the owner approved `Full suite` on `windows-latest`; `Core` and `Lint` stay on `ubuntu-latest`; still no Docker and no change to tolerances, goldens, hashes, geometry or tests. The original O1 text follows. Pinned Flutter from `.fvmrc`. On a verified Ubuntu-specific failure: find the exact cause, never change hashes, goldens or tolerances, report evidence and the smallest fix, consider `windows-latest` only if the cause is genuinely platform.
- **O2:** create the ruleset on `main` with exactly: require a pull request; require `Core`, `Lint`, `Full suite`; block force pushes; **no bypass actors**. Nothing broader (the plan's earlier "block deletion" is dropped). Verify repository and ruleset configuration before creating it.
- **O3:** `Core` budget 5 minutes; `Full suite` budget 1.5 times the first successful run rounded up to the next whole minute; actual durations and overruns are reported.
- **O4:** triggers are `push` to `main` and `pull_request` targeting `main` only (not every branch push). The guard test therefore asserts `push.branches == [main]` and `pull_request.branches == [main]`, and still forbids `paths`, `paths-ignore` and `branches-ignore`. Feature branches are verified through draft PRs.
- **O5:** no `.gitattributes` unless CI shows a real line-ending failure; then identify the files, explain the cause, present `* text=auto eol=lf`, and wait for explicit approval.

## Original open decisions and recommendations (history, superseded by the owner decisions above)

- **O1: Runner OS for the full suite.** Recommended: run `core` and `lint` on `ubuntu-latest`, and the `full` job on `ubuntu-latest` if Task 4 proves it green with no test changes, otherwise on `windows-latest` (the OS the tests were calibrated on). The plan makes this an observed result, not a guess. Matrix on both is not recommended (double runtime, no extra gate).
- **O2: Repository ruleset on `main` (outward-facing setting).** The branch is currently unprotected, so acceptance criterion 1 ("a PR with a failing core test is blocked from merge") cannot be true without it. Recommended: a ruleset requiring the checks `Core`, `Lint` and `Full suite` to pass, blocking force pushes and deletion of `main`, requiring a PR, **with no bypass actor** so the criterion is provable; the owner can still change it later. Alternative: bypass for the repository admin (an emergency path, but a red PR can then be merged by the owner). Task 6 does not start until the owner picks.
- **O3: Runtime budget.** The timer warns (non-failing) when a step exceeds a budget. Recommended initial budgets: core 5 min, full suite 1.5 times the first green run rounded up to the minute (set from Task 4's measurement and recorded in `docs/ci.md`). The owner can tighten it later.
- **O4: Trigger scope.** The task says "every push/PR", so the plan triggers on `push` (all branches) and `pull_request`. A PR branch therefore runs twice (one run per event, same checks). Alternative: `push` on `main` only plus `pull_request`, halving the runs with no loss of gating. Recommended: the literal reading (all pushes); Actions on a public repository is free.
- **O5: `.gitattributes` (repository-wide line endings), only if Task 4 shows a line-ending failure.** Recommended then: `* text=auto eol=lf` with binary assets marked `binary`. It changes how every file is checked out, so it is never added without the owner's approval; hashes, tolerances and tests are never altered to compensate.

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
- Produces (`timed.dart`): a `main(List<String> args)` that runs the command after `--` with inherited stdio, measures wall time, appends `formatCsvRow` to the file named by `CI_TIMING_FILE` (default `build/ci-timing.csv`, parent directory created), appends `formatSummaryRow` to the file named by `GITHUB_STEP_SUMMARY` when set (writing the table header first if the file has none from this tool), prints `budgetWarning` when non-null, and exits with the command's exit code (127 when the executable cannot be found, 2 on a usage error). The executable is resolved on `PATH` first (honouring `PATHEXT` on Windows, so `dart.bat` / `flutter.bat` shims resolve); only a `.bat` / `.cmd` resolution runs through the shell, with any argument containing a space or a double quote wrapped in double quotes (the Windows-only `.bat` test passes an argument with a space and asserts it arrives as one argument). On GitHub each step has its own `GITHUB_STEP_SUMMARY` file, so the header rule yields one table per step. A missing executable returns 127 from the resolver itself and does not depend on `ProcessException` (under `runInShell`, Windows reports it as exit 1).

- [ ] **Step 1: Write the failing tests** in `test/tool/ci_timing_test.dart`:
  - `formatCsvRow('core', Duration(milliseconds: 12345), 0)` equals `'core,12.3,0\n'`.
  - `formatSummaryRow` equals `'| core | 12.3 s | ok |\n'` for exit 0 and `'| core | 12.3 s | FAILED (3) |\n'` for exit 3.
  - `budgetWarning` returns `null` when under budget, when the budget is `null`, and exactly at the budget; returns the `::warning title=CI runtime budget::core took 61.0 s, budget 60 s` line at 61 s over 60.
  - End to end (spawn `Platform.resolvedExecutable tool/ci/timed.dart t -- <dart> --version`) exits 0 and writes one CSV line to a temp `CI_TIMING_FILE`; spawning with a wrapped command that exits 7 (`<dart> -e`-style: run a tiny temp `.dart` file with `exit(7)`) exits 7 **and** still writes the row with exit code 7; a nonexistent executable exits 127; no `--` exits 2; on Windows, a wrapped `.bat` shim that exits 5 propagates 5 (skipped on other platforms); the summary header is written once when `GITHUB_STEP_SUMMARY` is empty or has no line starting `| Step |`, and not again on a second call.
- [ ] **Step 2: Run to verify it fails.** `export PATH=/c/Users/user/fvm/versions/3.50.0/bin:$PATH; dart test test/tool/ci_timing_test.dart`. Expected: FAIL, "Target of URI doesn't exist: 'tool/ci/timing.dart'" (or equivalent).
- [ ] **Step 3: Implement** `timing.dart` (pure functions above) and `timed.dart` (argument parsing by hand, no new dependency; `Process.start(..., mode: ProcessStartMode.inheritStdio)`; the resolver described in the Interfaces block; header rule: write `| Step | Time | Result |` and its separator row when the summary file is empty or has no line starting `| Step |`).
- [ ] **Step 4: Run to verify it passes.** Same command. Expected: all tests pass.
- [ ] **Step 5: Format and analyze the new files.** `dart format tool/ci test/tool/ci_timing_test.dart` then `dart analyze --fatal-infos tool/ci test/tool`. Expected: no changes, no issues.
- [ ] **Step 6: Commit.** `git add tool/ci test/tool/ci_timing_test.dart && git commit -m "feat(ZOD-FND-004): add the CI step timer"` (with the attribution trailer).

### Task 2: The workflow and its guard test

**Files:** Create `.github/workflows/ci.yml`, `test/architecture/ci_workflow_test.dart`; Modify root `pubspec.yaml` / `pubspec.lock` (add `yaml: ^<the `version:` of the `yaml:` entry in `pubspec.lock`>` under `dev_dependencies`, then `dart run melos bootstrap`, then `git checkout -- packages/shared_ui/lib/l10n`; commit with the guard test).

**Interfaces:**
- Consumes: `Task 1` `tool/ci/timed.dart` CLI; `pure_dart_test.dart`'s `corePackages = ['astro_core', 'gann_core']`.
- Produces: three jobs whose `name:` values are exactly `Core`, `Lint`, `Full suite` (job ids `core`, `lint`, `full`). These names are the ruleset's required contexts in Task 6.

- [ ] **Step 1: Write the failing guard test** `test/architecture/ci_workflow_test.dart`, loading `.github/workflows/ci.yml` and asserting:
  - triggers are exactly `push` with `branches: [main]` and `pull_request` with `branches: [main]` (O4), and neither has `paths` / `paths-ignore` / `branches-ignore` (Review Focus 2);
  - workflow `permissions` is exactly `{contents: read}`; `push` and `pull_request` have no keys other than `branches` (no `tags`); `core` and `lint` have `runs-on: ubuntu-latest` and `full` has `runs-on: windows-latest` (O1 amended); the core job's budget step contains `300` (O3); `concurrency.group` is `ci-${{ github.ref }}`;
  - jobs `core`, `lint`, `full` exist with `name` `Core`, `Lint`, `Full suite`, each with a numeric `timeout-minutes`;
  - every `uses:` is `owner/repo@<40-hex SHA>` (Review Focus: pinning), ignoring `./` local actions;
  - no step in `core` runs `flutter test` or `melos run test:flutter`;
  - the `core` job's analyze command names every package in `corePackages` and contains `--fatal-warnings`; its `dart test` command names every one of them (Review Focus 6);
  - the `core` job runs `test/architecture` (the ARCH-2 and L-8 guards);
  - `lint` runs `melos run lint`; `full` runs `melos run test`;
  - no step runs a bare `dart pub get`, and the bootstrap step is followed by the l10n restore step;
  - every job sets `MELOS_SDK_PATH` and reads the Flutter version from `.fvmrc` (no hard-coded version string equal to the `.fvmrc` value in the workflow, so the two cannot drift).
- [ ] **Step 2: Run to verify it fails.** `dart test test/architecture/ci_workflow_test.dart`. Expected: FAIL, workflow file not found.
- [ ] **Step 3: Resolve the action SHAs.** For `actions/checkout`, `subosito/flutter-action` and `actions/upload-artifact`, take the latest release tag at least two weeks old and resolve its commit with `gh api repos/<owner>/<repo>/git/ref/tags/<tag> --jq .object.sha` (dereference annotated tags with `git/tags/<sha>`). Record tag and SHA in `docs/ci.md`.
- [ ] **Step 4: Write `.github/workflows/ci.yml`.**
  - `on: push` (`branches: [main]`) and `pull_request` (`branches: [main]`); `concurrency` group `ci-${{ github.ref }}` with `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}`; `permissions: contents: read`; `defaults.run.shell: bash` (the runner is Linux only, O1).
  - Common setup steps in each job: checkout (`persist-credentials: false`); read the version (`jq -r .flutter .fvmrc` into a step output); `subosito/flutter-action` with that version, `channel: stable`, pub cache enabled; export `MELOS_SDK_PATH=$FLUTTER_ROOT` (`$GITHUB_ENV`); `dart run melos bootstrap` at the root (the PROGRESS convention: plain `dart pub get` cannot resolve the Flutter members), then `git checkout -- packages/shared_ui/lib/l10n` (a root pub get deletes the tracked generated l10n files, PROGRESS line 249), then a check that `git status --porcelain` is empty before any test runs; print `dart --version` and `flutter --version`.
  - `core` (`Core`, `ubuntu-latest`, `timeout-minutes: 15`): `dart run tool/ci/timed.dart analyze-core -- dart analyze --fatal-warnings --fatal-infos packages/astro_core packages/gann_core`; `... core-tests -- dart run melos exec --scope="astro_core,gann_core" "dart test"` (use the existing `melos exec` filter style; if `--scope` cannot express two packages in this Melos, use two `--scope` flags or `--dir-exists` plus a package-name filter, whichever the local run in Task 3 proves); `... architecture -- dart test test/architecture`; then an `if: always()` shell step that sums column 2 of `build/ci-timing.csv` and prints `::warning title=CI runtime budget::core took <s> s, budget 300 s` when the sum exceeds 300 s (the O3 Core budget is the sum of the three timed steps, setup excluded; job wall time is reported as well, no new Dart code); upload `build/ci-timing.csv` as artifact `ci-timing-core`.
  - `lint` (`Lint`, `ubuntu-latest`, `timeout-minutes: 20`): `timed.dart lint -- dart run melos run lint`; upload timing artifact.
  - `full` (`Full suite`, `windows-latest` (O1 amended), `timeout-minutes: 45`): `timed.dart full-suite --budget-seconds <O3> -- dart run melos run test`; upload timing artifact; a final step prints `build/ci-timing.csv` into the job summary.
  - Do not give the `full` job `needs: core`: independent jobs report in parallel and each is its own required check. (A failing core shows up in seconds.)
- [ ] **Step 5: Run the guard test to verify it passes.** Expected: all pass. Also run `dart format --output=none --set-exit-if-changed test/architecture/ci_workflow_test.dart` and `dart analyze --fatal-infos test/architecture`.
- [ ] **Step 6: Mutation check on the guard (prove it can fail).** For each of: remove `--fatal-warnings`; replace one SHA with a tag; add `paths-ignore`; rename `Core`; add `flutter test` to `core`; drop `gann_core` from the analyze line; set `permissions: write-all`; remove `timeout-minutes` from one job; replace the bootstrap with a bare `dart pub get`; remove `MELOS_SDK_PATH`; change a trigger to `branches: ['**']` (or remove it); change `core` or `lint` to `windows-latest`, or `full` to `ubuntu-latest`; remove the `300` from the core budget step: edit the workflow, confirm exactly the matching test fails, then restore. Record the thirteen results in the Verification notes.
- [ ] **Step 7: Commit.** `feat(ZOD-FND-004): add the CI workflow and its guard test`.

### Task 3: Run each job's commands locally with the pinned SDK

**Files:** none changed unless a command needs correcting (then fix it in `ci.yml` and re-run Task 2's guard test).

- [ ] **Step 1:** `export PATH=/c/Users/user/fvm/versions/3.50.0/bin:$PATH; export MELOS_SDK_PATH=/c/Users/user/fvm/versions/3.50.0` and first run the setup commands exactly as written in `ci.yml` (bootstrap, l10n restore, clean-status check), recording `git status --short` afterwards (expected: empty). Then run the `core` job's three commands exactly as written (from the repository root). Expected: exit 0 each; `build/ci-timing.csv` has three rows. Confirm `melos exec` selected exactly `astro_core` and `gann_core` and not the root package (the output names them).
- [ ] **Step 2:** Temporarily rename `.fvm` (`mv .fvm .fvm.off`) to simulate the runner, run `dart run melos run lint` with `MELOS_SDK_PATH` set; expected: green. Then `unset MELOS_SDK_PATH` and run again; expected: fails naming the missing `.fvm/flutter_sdk` path (Melos 8.10.1 resolves `commandSdkPath ?? envSdkPath ?? configSdkPath`, so a wrong environment should fail loudly, Review Focus 3); if it behaves differently, record what it does. Restore `.fvm`.
- [ ] **Step 3:** Run the `full` job's command (`melos run test`) via the timer; record the local wall time as the Windows baseline (the background run started during planning is the first sample).
- [ ] **Step 4:** Melos 8.10.1 is expected to honour `MELOS_SDK_PATH` (it takes precedence over the config), so this step should be unneeded. Only if Step 2 shows it does not, replace it with a step that creates `.fvm/flutter_sdk` as a symlink to `$FLUTTER_ROOT` on Linux (and a junction via `cmd //c mklink /J` on Windows), keep the guard test's SDK assertion in line, and note the decision in PROGRESS Technical Decisions.

### Task 4: First runs on GitHub (Core and Lint on ubuntu-latest, Full suite on windows-latest, O1 amended)

- [ ] **Step 1:** Push the branch (`git push -u origin task/ZOD-FND-004-ci-pipeline`) and open a **draft** PR into `main` (`gh pr create --draft --base main`; a PR with any other base gets no checks, and a PR that conflicts with `main` gets none either, so if no run appears check `gh pr view --json mergeable`; watch with `gh pr checks <pr>` and `gh run list --event pull_request`, then `gh run view <id>`); the first push also tests that the token's `workflow` scope can push a workflow file.
- [ ] **Step 2:** Expected: `Core` and `Lint` green on `ubuntu-latest`. If any of `Core`, `Lint` or `Full suite` fails on Linux, read only the failing excerpts (`gh run view --log-failed`), classify each failure as a pixel/font difference, a line-ending or text-hash difference (Linux checks out LF; local trees are CRLF), or a real defect. A real defect gets a test-first fix. A line-ending or text-hash difference never gets an altered hash, tolerance or test: present `.gitattributes` to the owner as O5 and wait. A pixel/font difference: find the exact cause (font, rasteriser, path, locale); never change a hash, golden or tolerance; report the evidence and the smallest fix to the owner and wait. Consider `windows-latest` only if the cause is genuinely platform, and only with the owner's approval; record the outcome in PROGRESS Technical Decisions and `docs/ci.md`.
- [ ] **Step 3:** Once all three are green, record each job's duration and the full suite's wall time (from the timing artifact and `gh run view`). Set the O3 `--budget-seconds` for the full job to 1.5 times the full-suite time rounded up to the minute; re-run the guard test; commit `chore(ZOD-FND-004): set the full-suite runtime budget`.

### Task 5: Prove the three blocking criteria with throwaway branches

Each proof is a branch off the task branch that is pushed, opened as a draft PR **with `--base main`** (a PR with another base, or a conflict with `main`, gets no checks), observed red, then **closed without merging and its branch deleted**; the one exception is proof 1, which stays open (still red) until Task 6 Step 3. Nothing from these branches reaches `main`.

- [ ] **Step 1 (criterion 1, failing core test):** branch `ci-proof/failing-core-test`; change one expected literal in a `gann_core` test; push; expected `Core` red (`core-tests` step) and `Full suite` red.
- [ ] **Step 2 (criterion 2, UI import in core):** branch `ci-proof/core-flutter-import`; add `import 'package:flutter/foundation.dart';` to a file under `packages/astro_core/lib/` (and, separately in the same branch's second commit, `import 'dart:ui';` in `gann_core`; record per commit which step went red, the analyzer or `architecture`); expected `Core` red from `architecture` (ARCH-2 test) and, for the import, the analyzer.
- [ ] **Step 3 (L-8, missing ARB key):** branch `ci-proof/missing-arb-key`; delete one key from the Hebrew ARB; expected `Core` red (`l10n_key_parity_test`) and `Lint` red (`l10n:check` if the generated output goes stale).
- [ ] **Step 4 (analyzer warning in core):** branch `ci-proof/core-analyzer-warning`; add an unused local variable in `astro_core/lib`; expected `Core` red at `analyze-core`.
- [ ] **Step 5:** Record run URLs and which step failed in `docs/ci.md` (Verification evidence), close proofs 2 to 4 with `gh pr close --delete-branch` (keep `ci-proof/failing-core-test` and its PR open for Task 6 Step 3), and confirm `git branch -r` shows only that one `ci-proof/*` branch.

### Task 6: Make the checks block a merge (O2 approved 2026-11-20)

- [ ] **Step 1:** Show the owner the exact ruleset (target `refs/heads/main`; required status checks `Core`, `Lint`, `Full suite`; require a pull request; block force pushes; no bypass actors, per the approved O2) and compare it with the approved settings. The owner approved creation on 2026-11-20, so no further wait. Pre-checks: the repository is `yoadazani/zodiann` (public, default branch `main`); `gh api repos/yoadazani/zodiann/rulesets` is empty; `gh api repos/yoadazani/zodiann/branches/main/protection` is 404 (no classic protection, so the result is attributable to the ruleset alone). The exact JSON to post: `name: "main protection"`, `target: "branch"`, `enforcement: "active"`, `conditions.ref_name: {include: ["refs/heads/main"], exclude: []}`, `bypass_actors: []`, and exactly three rules: `non_fast_forward`; `pull_request` with `required_approving_review_count: 0` and `dismiss_stale_reviews_on_push`, `require_code_owner_review`, `require_last_push_approval`, `required_review_thread_resolution` all `false` (a sole owner cannot approve their own PR, so a required review would be broader than approved); `required_status_checks` with contexts `Core`, `Lint`, `Full suite` and `strict_required_status_checks_policy: false` (no `integration_id` unless the read-back needs it). No `deletion`, `update`, `required_linear_history` or `required_signatures` rule.
- [ ] **Step 2:** Create it with `gh api -X POST repos/yoadazani/zodiann/rulesets --input <json file in the scratchpad>`; read it back with `gh api repos/yoadazani/zodiann/rulesets` and diff the rule list against the JSON above (any difference is corrected before going on); save the returned JSON (without tokens) to `docs/ci.md` as the recorded configuration.
- [ ] **Step 3 (prove criterion 1 end to end):** on the still-open proof PR from Task 5 step 1, re-run its checks if needed, then assert `gh pr view --json mergeStateStatus` is `BLOCKED`, `gh pr merge` is refused, and `gh pr merge --admin` is also refused (no bypass actors); then close it with `--delete-branch` and confirm `git branch -r` has no `ci-proof/*` left. Also confirm this task's own PR reports `mergeStateStatus` `CLEAN` once green; do not merge it without the owner.

### Task 7: Documentation and records (after Tasks 1 to 6 pass)

- [ ] **Step 1:** Write `docs/ci.md`: jobs and the commands each runs; that feature-branch pushes are verified through draft PRs targeting `main` (the owner's O4 reading of "every push/PR"); that a superseded PR run is cancelled and the newer run reports the required checks; that the Core budget is the sum of three timed steps; the required check names; how to reproduce each job locally (including the pinned-SDK `PATH` note); where timing lives (job summary table, `ci-timing-*` artifacts); the baseline durations and budget; the action SHAs and tags and how to update them; the ruleset JSON; what is deliberately not covered (iOS, Gate 1 group, visual harness).
- [ ] **Step 2:** Set ZOD-FND-004's `Status` to completed in the task file and `TASKS.md` only after the verification below passes; leave the acceptance criteria text unchanged and tick them with evidence references. Add to the task file a Note pointing at `docs/ci.md` (the existing L10 note stays).
- [ ] **Step 3:** Update `docs/PROGRESS.md`: Project Status line, Completed Tasks entry with commands, results and the commit; Current Task; Next Recommended Task (and remove the "Note for ZOD-FND-004"); Technical Decisions (O1 to O5 outcomes (O5: no `.gitattributes` unless a line-ending failure appears), `MELOS_SDK_PATH` or the symlink fallback, the dependency on `yaml` if added); Verification; Git State (branch, PR).
- [ ] **Step 4: Verification before completion** (`superpowers:verification-before-completion`), with the pinned SDK on `PATH`: `dart run melos run lint`; `dart run melos run test`; `dart test test/tool/ci_timing_test.dart test/architecture/ci_workflow_test.dart`; the latest `gh run` for the branch head shows `Core`, `Lint`, `Full suite` all `success`. Record counts and the head commit.
- [ ] **Step 5:** Independent whole-branch code review (`superpowers:requesting-code-review`), resolve findings, then commit and push per the skill's Section 8, add the PR link in a small follow-up commit, and recommend the next task.

---

## Self-review (writing-plans checklist)

- **Spec coverage:** all four Implementation Details bullets and three Acceptance Criteria map to tasks: run `melos run test` on push to `main` and on pull requests to `main`, O4 (Tasks 2, 4); fast core job separate from the full suite (Task 2); ARB key failure (core `architecture` and `lint`, proved in Task 5 step 3); core analyzer failure (Task 2, proved in Task 5 step 4); failing core test blocks merge (Tasks 5 and 6); UI import fails CI (Task 5 step 2); runtime tracked (Task 1, Task 4 step 3, `docs/ci.md`). The task-file note (CI needs the pinned Flutter SDK) is handled by the version read and `MELOS_SDK_PATH`.
- **Names:** job ids `core`/`lint`/`full`, names `Core`/`Lint`/`Full suite`, files `tool/ci/timed.dart`, `tool/ci/timing.dart` are used identically across tasks.
- **Proportion:** the only new code is a small timer and two tests; the rest is workflow configuration, observation on GitHub and documentation.
- **Known uncertainties, stated not hidden:** Linux behaviour of pixel tests (O1, Task 4); `MELOS_SDK_PATH` support (Task 3 step 2); line endings in the text-hash guards (Review Focus 5, Task 4 step 2); the `melos exec` filter form for two packages (Task 3 step 1); the latest-but-two-weeks-old action tags (Task 2 step 3).

## Plan review

### Round 1 (comprehensive): approve after corrections

No Critical findings. No scope or decision conflicts. The reviewer confirmed that Melos 8.10.1 honours `MELOS_SDK_PATH` over the config `sdkPath`, that `yaml` is already in `pubspec.lock`, and that the repository is public.

| ID | Severity | Finding | Disposition |
|---|---|---|---|
| I1 | Important | `dart pub get` cannot resolve the Flutter members; a root pub get deletes the tracked generated l10n files; `yaml` addition lacked a lock-regeneration step | Applied: setup is `dart run melos bootstrap` + `git checkout -- packages/shared_ui/lib/l10n` + clean-status check; guard test forbids a bare `dart pub get`; Task 3 runs the setup locally; `yaml` step spelled out |
| I2 | Important | exit 127 relies on `ProcessException`, which `runInShell` on Windows does not raise | Applied: the timer resolves the executable itself (PATHEXT aware), shells only for `.bat`/`.cmd`; tests for 127 and a propagated `.bat` exit code |
| I3 | Important | no `.gitattributes`; CRLF locally vs LF on a Linux runner; not in the plan | Applied: new Review Focus 5, third failure class in Task 4 Step 2, new open decision O5 (`.gitattributes` only with owner approval) |
| M1 | Minor | Task 3 Step 2 expectation, symlink fallback probably unneeded | Applied: expectation reworded; Step 4 marked probably unneeded |
| M2 | Minor | root package must not be selected by `melos exec` | Applied in Task 3 Step 1 |
| M3 | Minor | guard mutations did not cover permissions, timeout, setup, SDK env | Applied: four mutations added (ten in total) |
| M4 | Minor | `dart:ui` import may go red at the analyzer, not the ARCH-2 test | Applied: Task 5 records the step that went red per commit |
| M5 | Minor | "no network calls" wording | Applied in Global Constraints |

Also added from the planning baseline: local `melos run test` is 2 min 29 s wall on `main`.

Open items: O1 to O5 for the owner (O5 only if Task 4 shows a line-ending failure).

### Round 2 (focused on the revision)

Verdict: approve after corrections. Round-1 findings I1 to I3 and M1 to M5 were checked as correctly applied. No Critical findings; no new user decision.

| ID | Severity | Finding | Disposition |
|---|---|---|---|
| I4 | Important | the line-ending classification covered only `Full suite`, but the text-hash guards also run in the required `Core` and `Lint` jobs | Applied: Task 4 Step 2 now covers any of the three jobs; Review Focus 5 says so |
| M6 | Minor | "pubspec.lock line 764" is the key, not the version | Applied |
| M7 | Minor | known-uncertainties list pointed at the wrong Task 3 step and omitted line endings | Applied |
| M8 | Minor | each GitHub step has its own summary file | Applied (stated in Task 1) |
| M9 | Minor | argument quoting on the `.bat` path unspecified | Applied (rule plus a Windows-only test with a spaced argument) |
| M10 | Minor | O5 listed before O4 | Applied: reordered; the round-2 record filled in |

Open items: O1 to O5 for the owner. The two-round limit for this cycle is used; nothing is unresolved.

### Round 3 (revision for the owner's decisions O1 to O5, 2026-11-20)

Verdict: approve after corrections; no Critical findings and no new owner decision. The owner's decisions were recorded correctly; the wording they invalidate was not all updated.

| ID | Severity | Finding | Disposition |
|---|---|---|---|
| I1 | Important | Task 4 Step 2 switched the runner to `windows-latest` on a pixel failure, contradicting O1 | Applied: find the cause, report to the owner and wait; Windows only if genuinely platform and with approval; Task 4 retitled; Review Focus 1 and the `full` job text updated |
| I2 | Important | Goal and self-review said "every push/PR", false under O4 | Applied; `docs/ci.md` will state the owner's reading; the task file is not edited |
| I3 | Important | proof PRs must target `main` or no checks run | Applied: `--base main` in Task 4 and Task 5, conflict note, `gh pr checks` |
| I4 | Important | Task 6 could not reopen a deleted proof branch | Applied: proof 1 stays open until Task 6 Step 3; `BLOCKED`, `merge` and `merge --admin` both refused; own PR `CLEAN`, not merged |
| I5 | Important | the Core budget (5 min) was on one step only | Applied: sum of the three timed steps checked in an `if: always()` step |
| I6 | Important | ruleset JSON not specified | Applied: exact JSON, pre-checks (no classic protection), read-back diff; `required_approving_review_count: 0` (a sole owner cannot approve their own PR) |
| M1 | Minor | guard and mutations did not cover O1 and O4 | Applied: assertions and three mutations (thirteen in total) |
| M2 | Minor | stale Windows and O1-to-O4 wording, history heading | Applied |
| M3 | Minor | concurrency note | Applied in the `docs/ci.md` list |

Open items: none for the plan. `required_approving_review_count: 0` is shown to the owner with the report.

### Round 4 (revision: O1 amended, `Full suite` on `windows-latest`, 2026-11-20)

*(pending)*
