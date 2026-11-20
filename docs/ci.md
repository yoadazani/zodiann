# Continuous integration (ZOD-FND-004)

Status: **implemented and verified; [PR #41](https://github.com/yoadazani/zodiann/pull/41) merged as `b042b8d` (2026-11-20).** `Core`, `Lint` and `Full suite` all pass on GitHub; `Full suite` runs on `windows-latest` by owner decision after it failed two cases on `ubuntu-latest` (section 6). Plan: [`docs/plans/ZOD-FND-004-ci-pipeline.md`](plans/ZOD-FND-004-ci-pipeline.md).

## 1. What runs

One workflow, `.github/workflows/ci.yml`, on `push` to `main` and `pull_request` targeting `main` (owner decision O4). Feature-branch pushes are verified through draft pull requests with base `main`; a PR with another base, or one that conflicts with `main`, gets no checks. `Core` and `Lint` run on `ubuntu-latest`; `Full suite` runs on `windows-latest`, the platform its pixel-fidelity tests were calibrated on (O1, amended 2026-11-20). No containers. The jobs are independent so each reports on its own; `defaults.run.shell: bash` gives every step one syntax (Git Bash on Windows).

| Check | Runs | Budget |
|---|---|---|
| `Core` | `dart analyze --fatal-warnings --fatal-infos packages/astro_core packages/gann_core`; `dart test` in those two packages (`melos exec --scope`); `dart test test/architecture` (ARCH-2 no-Flutter guard, L-8 key parity, and the other root guards) | 5 min: the sum of the three timed steps, setup excluded (a warning, never a failure) |
| `Lint` | `melos run lint` (`l10n:check`, `icons:check`, `launcher:check`, `analyze`, `format:check`) | none |
| `Full suite` | `melos run test` (every package; Flutter widget and pixel tests) | 4 min (240 s): 1.5 times the first green run's 144.0 s test step, rounded up to the next whole minute (O3). SDK install and workspace setup (about 2 min) are outside the timed step |

Setup in each job: checkout; read the Flutter version from `.fvmrc`; install that SDK; export `MELOS_SDK_PATH` (Melos 8.10.1 prefers it over `sdkPath: .fvm/flutter_sdk`, which does not exist on a runner); `flutter pub get`; restore the tracked generated l10n files (`git checkout -- packages/shared_ui/lib/l10n`, because a root pub get deletes them); fail if `git status --porcelain` is not empty. Plain `dart pub get` cannot resolve the Flutter members, and `dart run melos bootstrap` needs Melos resolved first, so setup uses `flutter pub get`.

Every action is pinned to a commit SHA; the tag is in a comment beside it. Current pins (each release at least two weeks old on 2026-11-20):

| Action | Tag | Commit |
|---|---|---|
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `subosito/flutter-action` | v2.23.0 | `1a449444c387b1966244ae4d4f8c696479add0b2` |
| `actions/upload-artifact` | v7.0.2 | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` |

To update one: take a release at least two weeks old, resolve its commit with `gh api repos/<owner>/<repo>/git/ref/tags/<tag>` (dereference an annotated tag with `git/tags/<sha>`), edit `ci.yml`; `test/architecture/ci_workflow_test.dart` fails if an action is not a 40-hex SHA.

A newer push to a PR cancels that PR's older run; the newer run reports the required checks. A push to `main` is never cancelled. The workflow has `permissions: contents: read`, no secrets, and downloads only the actions, the Flutter SDK and pub packages.

## 2. Runtime tracking

`tool/ci/timed.dart` wraps a command, records its wall time and exits with the command's own exit code (127 when the program is not found, 2 on a usage error). Each step appends a row to `build/ci-timing.csv` (uploaded as the artifact `ci-timing-core`, `ci-timing-lint`, `ci-timing-full`) and to the job summary table, and prints a non-failing `::warning title=CI runtime budget::` annotation when a step exceeds its `--budget-seconds`.

Recording is best effort: a timing or summary file that cannot be written is reported on stderr and never changes the exit code; a program that is found but cannot be started exits 126. On Windows a `.bat` shim (`dart.bat`, `flutter.bat`) is started directly and `cmd.exe` re-parses its arguments, so an argument containing `,`, `;`, `=`, `&` or `%` can be split or interpreted. Only `melos run test` goes through the timer on the Windows job today, which is safe; if the Core job (its `--scope="astro_core,gann_core"` has a comma) were ever moved to Windows, that would have to be solved first. The timer's own tests (`test/tool/ci_timing_test.dart`) run inside `melos run test`, so only on the Windows job; on Linux the timer is exercised by `Core` and `Lint` using it, not by its own tests (an accepted gap).

Reproduce a job locally with the pinned SDK first on `PATH` (the shell's own `dart` may be older):

```
export PATH=/c/Users/user/fvm/versions/3.50.0/bin:$PATH   # the .fvmrc SDK
export MELOS_SDK_PATH=/c/Users/user/fvm/versions/3.50.0
flutter pub get && git checkout -- packages/shared_ui/lib/l10n
dart run tool/ci/timed.dart analyze-core -- dart analyze --fatal-warnings --fatal-infos packages/astro_core packages/gann_core
```

## 3. Measured runtimes

| Run | Core | Lint | Full suite |
|---|---|---|---|
| Local Windows, `main` at `0599611` (`melos run test`) | n/a | n/a | 2 min 29 s, all passing |
| Local clean clone of the task branch, pinned SDK | 8.4 + 18.2 + 12.9 s | 124.1 s | not run |
| GitHub, PR #41, first run, `Full suite` on `ubuntu-latest` | 1 min 13 s (pass) | 1 min 23 s (pass) | 2 min 23 s (**fail**, section 6) |
| GitHub, PR #41, [run 44728342176](https://github.com/yoadazani/zodiann/actions/runs/44728342176) at `ce8aa00` (the reviewed head), `Full suite` on `windows-latest` | job 45 s (pass); timed steps 1.5 + 11.5 + 8.8 s | job 1 min 8 s (pass); timed step 45.7 s | job 4 min 29 s (**pass**); timed step 119.3 s, under the 240 s budget (no warning) |
| GitHub, push to `main` after the merge, [run 44731049475](https://github.com/yoadazani/zodiann/actions/runs/44731049475) at `b042b8d` | pass | pass | job 5 min 13 s (**pass**); timed step 144.6 s, under the 240 s budget |
| GitHub, PR #41, [run 44727158369](https://github.com/yoadazani/zodiann/actions/runs/44727158369) at `d1de352` | job 45 s (pass) | job 1 min 11 s (pass) | job 4 min 9 s (**pass**) |
| GitHub, PR #41, [run 44726200501](https://github.com/yoadazani/zodiann/actions/runs/44726200501), `Full suite` on `windows-latest` (the first green run; the budget is taken from it) | job 44 s (pass); timed steps 1.5 + 11.7 + 8.4 s | job 59 s (pass); timed step 30.5 s | job 5 min 22 s (**pass**); timed step 144.0 s, the rest is SDK install (about 99 s) and setup (28 s) |

## 4. Guard test

`test/architecture/ci_workflow_test.dart` pins the triggers, read-only permissions, the concurrency group, SHA pinning, the three job names, the runner per job (`ubuntu-latest` for Core and Lint, `windows-latest` for Full suite), the shared `bash` shell, the 240 s Full-suite budget, that no step can be neutralised (`continue-on-error`, a conditional other than `always()`, `|| true`, a chained command) and that Flutter comes from the `.fvmrc` through the action input, timeouts, no `needs`, the `.fvmrc` / `MELOS_SDK_PATH` setup, the pub-get and l10n-restore order, and the core job's scope, strictness and budget. Mutation proof (each edit made the matching test fail and nothing else; then restored): remove `--fatal-warnings`; replace a SHA with a tag; add `paths-ignore`; rename `Core`; add `flutter test` to `core`; drop `gann_core` from the analyze line; `permissions: write-all`; remove a job's `timeout-minutes`; replace `flutter pub get` with `dart pub get`; remove `MELOS_SDK_PATH`; change a trigger to `branches: ['**']`; `core` to `windows-latest`; `full` to `ubuntu-latest`; remove `defaults.run.shell`; change the Full-suite budget to 2400; add `continue-on-error: true` to a core step; add `if: false` to a core step; append `|| true` to a core step; replace the `flutter-version` input with a literal; chain a second command after a timed step; add a job-level `if:`; change the `t > 300` threshold (this one was first missed by a substring check and the assertion was tightened). Editing only the summary echo's `budget 300 s` text is not caught, because the warning line carries the same text.

## 5. Negative scenarios on GitHub (draft PRs against `main`, closed unmerged, branches deleted)

| Scenario | Change | Result |
|---|---|---|
| Failing core test | expected value in `gann_core/test/spiral/spiral_test.dart` changed | `Core` failed at "Test the core packages" (expected 2, actual 1); `Lint` passed. (`Full suite` also failed, but it ran on `ubuntu-latest` then and failed on every run, so that cell is not evidence of this scenario; no scenario has been re-run against the Windows job.) [run](https://github.com/yoadazani/zodiann/actions/runs/44722853597) |
| Flutter import in a core package | `import 'package:flutter/foundation.dart';` in `astro_core/lib` | `Core` failed at "Analyze the core packages" (unused_import warning, and the `depend_on_referenced_package` info, fatal with `--fatal-infos`). [run](https://github.com/yoadazani/zodiann/actions/runs/44722869473). The ARCH-2 test was not reached in CI because analyze stops the job first; run locally on the same code it fails with `packages/astro_core/lib/src/crossing.dart` named. There are two guards for this case, both in the `Core` job: the analyzer with `--fatal-infos` (the import resolves in this workspace, and a used import still raises the fatal `depend_on_referenced_packages` info) and the ARCH-2 test (`pure_dart_test.dart`, which scans `lib/` for `dart:ui` and `package:flutter` imports and checks the dependency closure). The guard test does not pin `--fatal-infos`; ARCH-2 running in the same job is what keeps the case covered if it were dropped |
| `dart:ui` import in a core package | `import 'dart:ui';` in `gann_core/lib/src/model/compass_direction.dart` (second commit of the same PR) | `Core` failed at "Analyze the core packages" (unused_import warning). [run](https://github.com/yoadazani/zodiann/actions/runs/44723452688) |
| Failing core test, **final configuration** (`Full suite` on `windows-latest`) | the same literal in `spiral_test.dart`, on a branch from `ce8aa00` | `Core` failed at "Test the core packages"; **`Full suite` failed at "Full test suite" on `windows-latest`** with the planted test named (expected 2, actual 1), so a test failure propagates through the timer and `dart.bat`; `Lint` passed. The PR was `BLOCKED`, `gh pr merge` and `gh pr merge --admin` were both refused ("2 of 3 required status checks are failing"). [run](https://github.com/yoadazani/zodiann/actions/runs/44729079066) |
| Missing ARB key | `signAries` deleted from `app_he.arb` | `Core` failed at "Architecture guards (ARCH-2, L-8)" (`l10n_key_parity_test`: every language has exactly the template's keys); `Lint` failed at `l10n:check`. (`Full suite` also failed on Ubuntu, failing anyway; not evidence.) [run](https://github.com/yoadazani/zodiann/actions/runs/44722886608) |
| Analyzer warning in core | an unused local variable in `astro_core/lib` | `Core` failed at "Analyze the core packages" (`unused_local_variable`); `Lint` failed. [run](https://github.com/yoadazani/zodiann/actions/runs/44722901066) |

## 6. Resolved by owner decision: `Full suite` on Windows (it failed two cases on Ubuntu)

Decision (2026-11-20, option 1 of three): run `Full suite` on `windows-latest`, keep `Core` and `Lint` on `ubuntu-latest`, no Docker, no change to tolerances, goldens, hashes, geometry or tests, no skipped test. The first Windows run passed all three checks (section 3). The Ubuntu evidence follows as history.

On `ubuntu-latest` two tests failed, both in `packages/feature_wheel/test/canvas/degree_scale_fidelity_test.dart`: "compact dark matches the Chrome reference" (mean 1.341, ceiling 1.15) and "compact light" (mean 1.749, ceiling 1.5). Everything else in the suite passed. The ceilings were calibrated on Windows (measured 0.75 and 0.98). The Linux measurements of the other checks equal the Windows ones for ticks and label radius (tick centroid 0.046, tick tip 0.5, label radius 0.765) and differ slightly for label centroids (compact dark 0.68 against 0.46; desktop 1.22 against 1.08); the desktop means (0.96, 1.26) are at or below the Windows values. This points to the small compact labels' text rasterisation, not to geometry. It has not been isolated by a label-only measurement. No tolerance, golden or hash was changed (owner decision O1). Options and the recommendation are in the task report.

## 7. Ruleset on `main` (owner decision O2)

Created 2026-11-20 with `gh api -X POST repos/yoadazani/zodiann/rulesets`, id `27719587`, named `main protection`, enforcement `active`, target `refs/heads/main`, **no bypass actors**, exactly three rules: `non_fast_forward`; `pull_request` (required approving reviews 0, a sole owner cannot approve their own PR; no code-owner, last-push, stale-review or thread rule); `required_status_checks` with `Core`, `Lint`, `Full suite` (not strict). No deletion, update, linear-history or signature rule. Read-back diff against the posted JSON: the same rules and parameters; GitHub added defaults that were not set: `allowed_merge_methods` (merge, squash, rebase), `require_extra_approval_for_unattributed_changes: true`, `required_reviewers: []`, `do_not_enforce_on_create: false`. The required checks carry no `integration_id`, so a commit status with one of those names from any source that can write statuses would also satisfy a check; pinning the GitHub Actions app is possible hardening and was not part of the approved O2. Before creation: no ruleset existed and `branches/main/protection` returned 404.

Blocking proof: on the proof PR with a failing core test, `mergeStateStatus` was `BLOCKED`; `gh pr merge --merge` was refused ("base branch policy prohibits the merge") and `gh pr merge --merge --admin` was refused ("2 of 3 required status checks are failing"); the PR stayed open until it was closed unmerged. The same result was observed again on the final configuration (section 5, the "final configuration" row). The task's own PR (#41) was marked ready and merged after its three checks passed (merge commit `b042b8d`).

## 8. Not covered

iOS or Android builds and any macOS runner (outstanding from ZOD-FND-005 and ZOD-FND-008), the Gate 1 required-checks group (ZOD-TST-017), the visual regression harness (ZOD-UI-015), and an automatic dependency-update bot.
