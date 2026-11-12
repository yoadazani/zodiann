# Zodiann — Development Progress

Verified record of actual development state. See `docs/development/TASKS.md` for the full roadmap and `.claude/skills/zodiann-development/SKILL.md` for the workflow.

## Project Status

- **Current phase:** Phase 1 — Foundations
- **Overall status:** Planning the first task. No application code exists yet. 0 of 205 tasks done.
- **Last updated:** 2026-11-12

## Completed Tasks

_None yet._

## Current Task

- **ID:** ZOD-FND-001
- **Name:** Set up the Melos monorepo workspace
- **Status:** Plan revision 2 written, awaiting user approval
- **Plan:** [`docs/plans/ZOD-FND-001-melos-workspace.md`](plans/ZOD-FND-001-melos-workspace.md)
- **Completed steps:** Toolchain and dependency versions verified; branch created; plan written; revision 2 addressed review points 1–6 (Melos empty-filter behaviour, pub-deps format, SDK path, symlink permissions, conventions, lock file).
- **Remaining steps:** Plan approval → Tasks 1–5 of the plan (FVM pin, workspace + skeletons, ARCH-2 guard, scripts/docs/verification, close-out).

## Next Recommended Task

- **ID:** ZOD-FND-002 — Define the `EphemerisPort` interface contract
- **Why next:** It's next on the critical path. It depends only on FND-001 and unblocks FND-003 (Swiss Ephemeris FFI spike) and EPH-001.
- **Dependency status:** Blocked until ZOD-FND-001 is merged.
- **Can run independently:** ZOD-FND-010 (Swiss Ephemeris license research). It has no dependencies, needs no code and stays a separate task.

## Blockers

- **Symlink permission (verified)**: Developer Mode is off, there is no symlink privilege, and FVM 4.3.2 has no junction fallback. Needed for `.fvm/flutter_sdk` (ZOD-FND-001 Task 1). User action: enable Developer Mode, or run `fvm use` once from an admin terminal.
- Open product decisions D-1…D-5 and design approvals D6–D19 (`TASKS.md` §6) don't affect ZOD-FND-001.

## Architecture Conventions

Every task follows these infrastructure conventions (established in ZOD-FND-001). Changing one requires an explicit decision recorded below.

**SDK and toolchain**
- The Flutter SDK is pinned in `.fvmrc` (currently 3.50.0 / Dart 3.14.0) and used via FVM. Never use the global Flutter at `C:\Program Files\flutter` for project work.
- Melos (`sdkPath: .fvm/flutter_sdk`) runs every workspace command with the pinned SDK. Run project commands as `melos …` or `fvm flutter …` / `fvm dart …`.
- FVM may not edit project files (`.fvmrc`: `updateVscodeSettings`, `updateGitIgnore`, `updateMelosSettings` all `false`).
- On Windows, FVM needs symlink permission: Developer Mode, or an admin terminal for `fvm use`.

**Workspace**
- One Dart pub workspace. All Melos config lives under `melos:` in the root `pubspec.yaml`. There is no `melos.yaml`.
- Every member declares `resolution: workspace`, `publish_to: none`, `environment.sdk: ^<pinned Dart minor>`. Flutter members also declare `environment.flutter: ">=<pinned Flutter>"`.
- New packages go under `packages/`, apps under `apps/`, C sources under `native/`. A new member must be added to the root `workspace:` list.
- Pure-Dart vs Flutter package kinds are listed in the ZOD-FND-001 plan. `astro_core` and `gann_core` must stay pure Dart (ARCH-2). The root architecture tests enforce this on every `melos run test`.

**Dependencies**
- There's a single root `pubspec.lock`, always committed. Members never get their own lock file.
- Use the latest stable release that's compatible with the pinned SDK. When a dependency can't be the latest, record why under Technical Decisions.
- Before adding a dependency, check it against Flutter's exact pins (currently `test_api`, `matcher`, `material_color_utilities`), because the shared resolution has to satisfy them.

**Scripts and quality gates**
- Run `melos run lint` (analyze with `--fatal-infos` + format check) and `melos run test` (pure-Dart and Flutter suites) before committing.
- Melos scripts must select packages with `melos exec` command-line filters, never with script-level `packageFilters`. Melos 8 fails a script whose `packageFilters` match zero packages.
- Cross-package architecture tests live in the workspace root's `test/architecture/` (`useRootAsPackage: true`).

**Analysis**
- The root `analysis_options.yaml` (`package:lints/recommended.yaml` + strict-casts / strict-inference / strict-raw-types) applies to everything. Flutter members add `package:flutter_lints/flutter.yaml` via a multi-include.

## Technical Decisions

| Date | Decision | Reason | Impacted components | Reference |
|---|---|---|---|---|
| 2026-11-12 | Melos 8 (8.10.1) on Dart pub workspaces, configured in the root `pubspec.yaml`. No `melos.yaml`. | Current Melos model, with one shared resolution and lock file. User decision. | Whole workspace | ZOD-FND-001 plan |
| 2026-11-12 | Pin Flutter 3.50.0 / Dart 3.14.0 with FVM 4.3.2 (`.fvmrc`). Melos `sdkPath: .fvm/flutter_sdk`. | Latest stable on 2026-11-12, superseding the initially named 3.47.9. Same SDK locally and in CI. User decision. | Whole workspace, CI (FND-004) | ZOD-FND-001 plan |
| 2026-11-12 | Use `test` 1.32.0 instead of the latest 1.33.0. | 1.33.0 pins `test_api 0.7.15`, which conflicts with Flutter 3.50.0's `flutter_test` pin of `test_api 0.7.14` in the shared workspace resolution. 1.32.0 is the newest compatible release. | Pure-Dart packages' tests | ZOD-FND-001 plan, Version Baseline |
| 2026-11-12 | `ephemeris_swiss` / `ephemeris_astronomy` start as pure-Dart skeletons. | Plugin vs. native-assets packaging is ZOD-FND-003's decision. | FFI packages | ZOD-FND-001 plan |
| 2026-11-12 | Melos test scripts use `melos exec` command-line filters, not script `packageFilters`. | Melos 8.10.1 throws `NoPackageFoundScriptException` when script filters match zero packages, while an empty `melos exec` selection exits 0 (verified in source). | Root `pubspec.yaml` scripts | ZOD-FND-001 plan, Verified fact 1 |
| 2026-11-12 | ARCH-2 guard lives once in the workspace root (`useRootAsPackage: true`) as fixture unit tests plus a live `pub deps --json` check. | Avoids copying the check into each core package. Fixture tests permanently prove that indirect Flutter is detected via regular and dev paths. | `test/architecture/` | ZOD-FND-001 plan, Task 3 |
| 2026-11-12 | Closure rule: start node uses `directDependencies ∪ devDependencies`, every later node uses `directDependencies` only. | In workspace `pub deps --json`, a member's `dependencies` is the union with dev dependencies, so following it would count other packages' dev dependencies (false positives). `root` is the workspace, not the member. | ARCH-2 guard | ZOD-FND-001 plan, Verified fact 4 |

## Verification

_No implementation verification yet._ Version checks performed on 2026-11-12:
- Installed: Flutter 3.27.1 / Dart 3.6.0, global at `C:\Program Files\flutter` (verified via `where.exe` and `flutter --version --machine`; `C:\develop\flutter` does not exist, `FLUTTER_ROOT` unset). Melos and FVM are not installed.
- Symlinks: non-elevated session, no `SeCreateSymbolicLinkPrivilege`, Developer Mode off. `mklink /D` and Dart `Link.createSync` fail (errno 1314); junctions succeed. FVM 4.3.2 has no junction fallback.
- Melos 8.10.1 source: script `packageFilters` with zero matches throw; an empty `melos exec` selection exits 0; `sdkPath` is applied to child-process `PATH`; `useRootAsPackage` is supported.
- `dart pub deps --json` workspace format probed on a scratch workspace; closure rule proven (see the plan's Verified fact 4).
- Flutter 3.50.0 exact pins: `test_api 0.7.14`, `matcher 0.12.20`, `material_color_utilities 0.13.0`. No conflicts with Melos, `lints` or `flutter_lints`; `test` held at 1.32.0.
- Latest stable: Flutter 3.50.0 / Dart 3.14.0 (official release feed), Melos 8.10.1, FVM 4.3.2, `lints` 6.1.0, `flutter_lints` 6.0.0, `test` 1.33.0 (1.32.0 selected, see Technical Decisions).

## Git State

- **Current task branch:** `task/ZOD-FND-001-melos-workspace` (from `main` @ `5f7797f`)
- **Relevant commits:** none on the task branch yet
- **Pull request:** not opened yet
- **Unmerged task branches others depend on:** none
- **Uncommitted changes:** this file and the ZOD-FND-001 plan (to be committed on the task branch)
- **Preserve:** `.idea/` and `.qodo/` are local IDE folders. Never stage them.
