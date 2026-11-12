# Zodiann — Development Progress

Verified record of actual development state. See `docs/development/TASKS.md` for the full roadmap and `.claude/skills/zodiann-development/SKILL.md` for the workflow.

## Project Status

- **Current phase:** Phase 1 — Foundations
- **Overall status:** Workspace foundation complete (ZOD-FND-001); no application code yet. 1 of 205 tasks done.
- **Last updated:** 2026-11-12

## Completed Tasks

| ID | Name | Status | Verification evidence |
|---|---|---|---|
| ZOD-FND-001 | Set up the Melos monorepo workspace | Done (PR pending merge) | Bootstrap links 11 packages; `melos run lint` exit 0; `melos run test` exit 0 (15/15 architecture tests); `astro_core` / `gann_core` depend only on `test` (dev), with no Flutter in their transitive closure. See Verification. Plan: [`docs/plans/ZOD-FND-001-melos-workspace.md`](plans/ZOD-FND-001-melos-workspace.md) |

## Current Task

_None._ ZOD-FND-001 is complete and awaiting PR merge.

## Next Recommended Task

- **ID:** ZOD-FND-002 — Define the `EphemerisPort` interface contract
- **Why next:** It's next on the critical path. It depends only on FND-001 and unblocks FND-003 (Swiss Ephemeris FFI spike) and EPH-001.
- **Dependency status:** Needs ZOD-FND-001's PR merged into `main` first (it builds on the workspace).
- **Can run independently:** ZOD-FND-010 (Swiss Ephemeris license research). It has no dependencies and needs no code.
- **Note for ZOD-FND-004 (CI):** Melos `sdkPath: .fvm/flutter_sdk` must resolve on the runner. CI has to install the `.fvmrc` SDK and provide `.fvm/flutter_sdk`, or an equivalent `MELOS_SDK_PATH`.

## Blockers

_None._ Open product decisions D-1…D-5 and design approvals D6–D19 (`TASKS.md` §6) affect later tasks, not the next one.

## Architecture Conventions

Every task follows these infrastructure conventions (established in ZOD-FND-001). Changing one requires an explicit decision recorded below.

**SDK and toolchain**
- The Flutter SDK is pinned in `.fvmrc` (currently 3.50.0 / Dart 3.14.0) and used via FVM. Never use the global Flutter at `C:\Program Files\flutter` for project work.
- **Run Melos as `fvm dart run melos <command>`**, never a bare `melos`. The globally activated `melos` shim runs on whichever `dart` is first on PATH (the global 3.6.0) and fails with "Invalid kernel binary format version". `fvm dart run melos` runs the exact Melos version in `pubspec.lock` on the pinned SDK.
- Run other SDK commands as `fvm flutter …` / `fvm dart …`. Resolve dependencies with `fvm flutter pub get` or `fvm dart run melos bootstrap`. Plain `dart pub get` can't resolve the Flutter members.
- Melos (`sdkPath: .fvm/flutter_sdk`) puts the pinned SDK first on child processes' PATH, so commands inside Melos scripts use it automatically.
- FVM may not edit project files (`.fvmrc`: `updateVscodeSettings`, `updateGitIgnore`, `updateMelosSettings` all `false`).
- On Windows, FVM needs symlink permission: Developer Mode, or an admin terminal for `fvm use`.

**Workspace**
- One Dart pub workspace. All Melos config lives under `melos:` in the root `pubspec.yaml`. There is no `melos.yaml`.
- Every member declares `resolution: workspace`, `publish_to: none`, `environment.sdk: ^<pinned Dart minor>`. Flutter members also declare `environment.flutter: ">=<pinned Flutter>"`.
- New packages go under `packages/`, apps under `apps/`, C sources under `native/`. A new member must be added to the root `workspace:` list.
- Package kinds: pure Dart = `astro_core`, `gann_core`, `ephemeris_swiss`, `ephemeris_astronomy`. Flutter = `feature_wheel`, `feature_square`, `shared_ui`, `shared_storage`, `shared_export_xlsx`, `apps/astro_mobile`. `astro_core` and `gann_core` must stay pure Dart (ARCH-2). The root architecture tests enforce this on every test run, including indirect and conditional-import paths.

**Dependencies**
- There's a single root `pubspec.lock`, always committed. Members never get their own lock file.
- Use the latest stable release that's compatible with the pinned SDK. When a dependency can't be the latest, record why under Technical Decisions.
- Before adding a dependency, check it against Flutter's exact pins (currently `test_api 0.7.14`, `matcher 0.12.20`, `material_color_utilities 0.13.0`), because the shared resolution has to satisfy them.

**Scripts and quality gates**
- Before committing, run `fvm dart run melos run lint` (analyze with `--fatal-infos` + format check) and `fvm dart run melos run test` (pure-Dart and Flutter suites).
- Melos scripts select packages with `melos exec` command-line filters, never with script-level `packageFilters`. Melos 8 fails a script whose `packageFilters` match zero packages.
- Nested Melos calls in scripts are written `dart run melos exec <filters> "<command and its args>"`, with the command as **one quoted argument**. `dart run` strips a `--` separator, which would make Melos parse the command's own flags.
- Cross-package architecture tests live in the workspace root's `test/architecture/` (`useRootAsPackage: true`) and run from the repo root.

**Analysis**
- The root `analysis_options.yaml` (`package:lints/recommended.yaml` + strict-casts / strict-inference / strict-raw-types) applies to everything. Flutter members add `package:flutter_lints/flutter.yaml` via a multi-include. The Flutter tool also maintains an `analyzer: exclude: [build/**]` entry there. Leave it.
- Pure-Dart members inherit `lints` through the shared workspace resolution (it's a root dev dependency).

## Technical Decisions

| Date | Decision | Reason | Impacted components | Reference |
|---|---|---|---|---|
| 2026-11-12 | Melos 8 (8.10.1) on Dart pub workspaces, configured in the root `pubspec.yaml`. No `melos.yaml`. | Current Melos model, with one shared resolution and lock file. User decision. | Whole workspace | ZOD-FND-001 plan |
| 2026-11-12 | Pin Flutter 3.50.0 / Dart 3.14.0 with FVM 4.3.2 (`.fvmrc`). Melos `sdkPath: .fvm/flutter_sdk`. | Latest stable on 2026-11-12, superseding the initially named 3.47.9. Same SDK locally and in CI. User decision. | Whole workspace, CI (FND-004) | ZOD-FND-001 plan |
| 2026-11-12 | Use `test` 1.32.0 instead of the latest 1.33.0. | 1.33.0 pins `test_api 0.7.15`, which conflicts with Flutter 3.50.0's `flutter_test` pin of `test_api 0.7.14` in the shared workspace resolution. 1.32.0 is the newest compatible release. | Root and pure-Dart packages' tests | ZOD-FND-001 plan, Version Baseline |
| 2026-11-12 | `platform` stays at 3.1.6 (latest 3.2.0). | Melos 8.10.1, the latest, constrains it to `>=3.1.6 <3.2.0`. Transitive dev-only dependency. | Tooling only | `fvm flutter pub outdated` |
| 2026-11-12 | `ephemeris_swiss` / `ephemeris_astronomy` start as pure-Dart skeletons. | Plugin vs. native-assets packaging is ZOD-FND-003's decision. | FFI packages | ZOD-FND-001 plan |
| 2026-11-12 | Melos test scripts use `melos exec` command-line filters, not script `packageFilters`. | Melos 8.10.1 throws `NoPackageFoundScriptException` when script filters match zero packages, while an empty `melos exec` selection exits 0 (verified in source). | Root `pubspec.yaml` scripts | ZOD-FND-001 plan, Verified fact 1 |
| 2026-11-12 | Invoke Melos via `fvm dart run melos`. Nested script calls use `dart run melos exec <filters> "<cmd>"`. | The global melos shim runs on the global Dart 3.6.0 and fails. `dart run` strips `--`, so the command is passed as one quoted argument. Verified that child processes run Dart 3.14.0 / Flutter 3.50.0. | Root `pubspec.yaml` scripts, README, all tasks | ZOD-FND-001 Task 2 rulings |
| 2026-11-12 | ARCH-2 guard lives once in the workspace root (`useRootAsPackage: true`) as fixture unit tests plus a live `pub deps --json` check. | Avoids copying the check into each core package. Fixture tests permanently prove that indirect Flutter is detected via regular and dev paths. | `test/architecture/` | ZOD-FND-001 plan, Task 3 |
| 2026-11-12 | Closure rule: start node uses `directDependencies ∪ devDependencies`, every later node uses `directDependencies` only. | In workspace `pub deps --json`, a member's `dependencies` is the union with dev dependencies, so following it would count other packages' dev dependencies (false positives). `root` is the workspace, not the member. | ARCH-2 guard | ZOD-FND-001 plan, Verified fact 4 |
| 2026-11-12 | The import scan covers whole import/export statements, including conditional alternatives. | The code review found that `import 'stub.dart' if (dart.library.ui) 'dart:ui';` was missed. | ARCH-2 guard | Final review fix |

## Verification

ZOD-FND-001, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| Pinned SDK | `fvm flutter --version --machine` | 3.50.0, stable, Dart 3.14.0 |
| AC1: bootstrap links all packages | `fvm dart run melos bootstrap`, `… melos list --long` | Exit 0, "11 packages bootstrapped" (root + 10 members) |
| AC2: core has no Flutter | ARCH-2 tests + `dart pub deps` | `astro_core` and `gann_core`: direct=[], dev=[test]. Transitive closure clean. The live guard fails with `astro_core -> shared_ui -> flutter` when a violation is injected (then reverted) |
| AC3: workspace-wide tests | `fvm dart run melos run test` | Exit 0. 15/15 root architecture tests. `test:flutter` selects 0 packages and succeeds |
| Lint | `fvm dart run melos run lint` | Exit 0, no analyzer issues, no formatting changes |
| Child processes use the pinned SDK | `melos exec --scope=astro_core "dart --version"` | Dart 3.14.0 (Flutter children: 3.50.0) |
| Global SDK rejected | global `dart pub get` | Exit 1: "requires SDK version ^3.14.0", lock unchanged |
| Code review | Fresh reviewer, whole branch | With fixes: 0 Critical, 1 Important (stale command conventions here, fixed), 6 Minor (1 promoted and fixed, 5 deferred, listed below) |

**Known failures:** none.

**Deferred review minors** (candidates for later tasks):
- Root `analyze` / `format:check` on `.` also re-cover member directories (double work and double-reported failures).
- The architecture tests use cwd-relative paths and must run from the repo root.
- If `pub deps` fails, closure tests add an unhelpful `FormatException` (the exit-code test stays clear).
- There's no `.gitattributes`. With `core.autocrlf=true`, clones get CRLF. The format gate was verified OK; it's a candidate for ZOD-FND-004.
- Pure-Dart members inherit `lints` without declaring it (works via the shared resolution).

## Git State

- **Current task branch:** `task/ZOD-FND-001-melos-workspace` (from `main` @ `5f7797f`)
- **Relevant commits:** `2c66f9b` FVM pin · `2d810e3` workspace + skeletons · `0063563` ARCH-2 guard · `aeccc8e` README · `4733e36` conditional-import fix · plus planning/docs commits
- **Pull request:** to be opened (link recorded after push)
- **Unmerged task branches others depend on:** `task/ZOD-FND-001-melos-workspace` (ZOD-FND-002 and later need it on `main`)
- **Uncommitted changes:** none
- **Preserve:** `.idea/` and `.qodo/` are local IDE folders. Never stage them. `.fvm/` is a local symlink (gitignored).
