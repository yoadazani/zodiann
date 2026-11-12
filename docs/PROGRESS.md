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
- **Status:** Plan written, awaiting user approval
- **Plan:** [`docs/plans/ZOD-FND-001-melos-workspace.md`](plans/ZOD-FND-001-melos-workspace.md)
- **Completed steps:** Toolchain and dependency versions verified; branch created; plan written.
- **Remaining steps:** Plan approval → Tasks 1–5 of the plan (FVM pin, workspace + skeletons, ARCH-2 guard, scripts/docs/verification, close-out).

## Next Recommended Task

- **ID:** ZOD-FND-002 — Define the `EphemerisPort` interface contract
- **Why next:** It's next on the critical path. It depends only on FND-001 and unblocks FND-003 (Swiss Ephemeris FFI spike) and EPH-001.
- **Dependency status:** Blocked until ZOD-FND-001 is merged.
- **Can run independently:** ZOD-FND-010 (Swiss Ephemeris license research). It has no dependencies, needs no code and stays a separate task.

## Blockers

- **Windows Developer Mode** appears disabled. It's needed for FVM's `.fvm/flutter_sdk` symlink (ZOD-FND-001 Task 1). User action required.
- Open product decisions D-1…D-5 and design approvals D6–D19 (`TASKS.md` §6) don't affect ZOD-FND-001.

## Technical Decisions

| Date | Decision | Reason | Impacted components | Reference |
|---|---|---|---|---|
| 2026-11-12 | Melos 8 (8.10.1) on Dart pub workspaces, configured in the root `pubspec.yaml`. No `melos.yaml`. | Current Melos model, with one shared resolution and lock file. User decision. | Whole workspace | ZOD-FND-001 plan |
| 2026-11-12 | Pin Flutter 3.50.0 / Dart 3.14.0 with FVM 4.3.2 (`.fvmrc`). Melos `sdkPath: .fvm/flutter_sdk`. | Latest stable on 2026-11-12, superseding the initially named 3.47.9. Same SDK locally and in CI. User decision. | Whole workspace, CI (FND-004) | ZOD-FND-001 plan |
| 2026-11-12 | Use `test` 1.32.0 instead of the latest 1.33.0. | 1.33.0 pins `test_api 0.7.15`, which conflicts with Flutter 3.50.0's `flutter_test` pin of `test_api 0.7.14` in the shared workspace resolution. 1.32.0 is the newest compatible release. | Pure-Dart packages' tests | ZOD-FND-001 plan, Version Baseline |
| 2026-11-12 | `ephemeris_swiss` / `ephemeris_astronomy` start as pure-Dart skeletons. | Plugin vs. native-assets packaging is ZOD-FND-003's decision. | FFI packages | ZOD-FND-001 plan |

## Verification

_No implementation verification yet._ Version checks performed on 2026-11-12:
- Installed: Flutter 3.27.1 / Dart 3.6.0 (global, `C:\Program Files\flutter`). Melos and FVM not installed.
- Latest stable: Flutter 3.50.0 / Dart 3.14.0 (official release feed), Melos 8.10.1, FVM 4.3.2, `lints` 6.1.0, `flutter_lints` 6.0.0, `test` 1.33.0 (1.32.0 selected, see Technical Decisions).

## Git State

- **Current task branch:** `task/ZOD-FND-001-melos-workspace` (from `main` @ `5f7797f`)
- **Relevant commits:** none on the task branch yet
- **Pull request:** not opened yet
- **Unmerged task branches others depend on:** none
- **Uncommitted changes:** this file and the ZOD-FND-001 plan (to be committed on the task branch)
- **Preserve:** `.idea/` and `.qodo/` are local IDE folders. Never stage them.
