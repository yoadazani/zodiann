# Zodiann — Development Progress

Verified record of actual development state. See `docs/development/TASKS.md` for the full roadmap and `.claude/skills/zodiann-development/SKILL.md` for the workflow.

## Project Status

- **Current phase:** Phase 1 — Foundations
- **Overall status:** Workspace foundation (ZOD-FND-001) merged. `EphemerisPort` contract (ZOD-FND-002) complete, PR pending merge. 2 of 205 tasks done.
- **Last updated:** 2026-11-12

## Completed Tasks

| ID | Name | Status | Verification evidence |
|---|---|---|---|
| ZOD-FND-002 | Define the `EphemerisPort` interface contract | Done (PR pending merge) | `astro_core`: 20/20 tests (value types, sealed results, fake-port contract). The exhaustive switch was proven by a mutation that failed to compile. Lint exit 0. ARCH-2 guard 15/15. Review: 0 Critical / 0 Important. 3 doc minors were promoted and fixed, 1 deferred. Plan: [`docs/plans/ZOD-FND-002-ephemeris-port.md`](plans/ZOD-FND-002-ephemeris-port.md) |
| ZOD-FND-001 | Set up the Melos monorepo workspace | Done ([PR #2](https://github.com/yoadazani/zodiann/pull/2), merged `0303645`) | Bootstrap links 11 packages; `melos run lint` exit 0; `melos run test` exit 0 (15/15 architecture tests); `astro_core` / `gann_core` depend only on `test` (dev), with no Flutter in their transitive closure. See Verification. Plan: [`docs/plans/ZOD-FND-001-melos-workspace.md`](plans/ZOD-FND-001-melos-workspace.md) |

## Current Task

_None._ ZOD-FND-002 is complete and awaiting PR merge.

## Next Recommended Task

- **ID:** ZOD-FND-012 — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes (Critical)
- **Why next:** It depends only on FND-001 (merged) and, together with FND-002, unblocks ZOD-EPH-001 (mean-node formula), which is on the critical path. It adds JSON to the `Body` enum defined in FND-002, so it builds on this branch. **FND-002's PR should be merged first.**
- **Why not FND-003 yet:** the Swiss Ephemeris FFI spike must run a real computation on **both Android and iOS**. An iOS build needs macOS/Xcode, which this Windows machine can't provide. That needs a decision (a Mac, a cloud macOS runner, or splitting the spike) before FND-003 starts. It also benefits from ZOD-FND-010 (license) first.
- **Can run independently:** ZOD-FND-010 (Swiss Ephemeris license research, Critical, no code).
- **Note for ZOD-EPH-001:** the task file now records the shared `mean_node.dart` location, the `implements` (not `on`) mixin rule, the `x % 360 == 360.0` pitfall, and `T` from UTC.
- **Note for ZOD-FND-004 (CI):** Melos `sdkPath: .fvm/flutter_sdk` must resolve on the runner. CI has to install the `.fvmrc` SDK and provide `.fvm/flutter_sdk`, or an equivalent `MELOS_SDK_PATH`.

## Blockers

- **iOS build environment for ZOD-FND-003** (and later iOS work): development runs on Windows, and iOS builds need macOS/Xcode. A decision is needed before FND-003.
- Open product decisions D-1…D-5 and design approvals D6–D19 (`TASKS.md` §6) affect later tasks, not the next one.

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
- Pass a command to `melos exec` as `melos exec <filters> -- <command and its args>`. **Exception:** if the command contains `--version` or `-v`, pass it as one quoted argument (`melos exec <filters> "<command>"`), because Melos 8.10.1 treats those flags as its own wherever they appear, even after `--` (`command_runner.dart:120`). The existing root scripts use the quoted form, which works in every case.
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
| 2026-11-12 | Invoke Melos via `fvm dart run melos`. Nested script calls use `dart run melos exec <filters> "<cmd>"`. | The global melos shim runs on the global Dart 3.6.0 and fails. Verified that child processes run Dart 3.14.0 / Flutter 3.50.0. **Corrected 2026-11-12 (ZOD-FND-002):** the original reason given for the quoted form ("`dart run` strips `--`") was wrong. `dart run` passes `--` intact; Melos intercepts `--version` / `-v` anywhere (`command_runner.dart:120`). `-- <command>` is the normal form, and quoting is required only for those two flags. | Root `pubspec.yaml` scripts, README, all tasks | ZOD-FND-001 Task 2 rulings |
| 2026-11-12 | ARCH-2 guard lives once in the workspace root (`useRootAsPackage: true`) as fixture unit tests plus a live `pub deps --json` check. | Avoids copying the check into each core package. Fixture tests permanently prove that indirect Flutter is detected via regular and dev paths. | `test/architecture/` | ZOD-FND-001 plan, Task 3 |
| 2026-11-12 | Closure rule: start node uses `directDependencies ∪ devDependencies`, every later node uses `directDependencies` only. | In workspace `pub deps --json`, a member's `dependencies` is the union with dev dependencies, so following it would count other packages' dev dependencies (false positives). `root` is the workspace, not the member. | ARCH-2 guard | ZOD-FND-001 plan, Verified fact 4 |
| 2026-11-12 | The import scan covers whole import/export statements, including conditional alternatives. | The code review found that `import 'stub.dart' if (dart.library.ui) 'dart:ui';` was missed. | ARCH-2 guard | Final review fix |
| 2026-11-12 | ZOD-FND-002 declares the mean-node method and documents its formula; ZOD-EPH-001 implements it; ZOD-TST-002 verifies T-EPH-2. FND-002's node criterion was changed to "declared + contract documented". | The original criterion created a cycle (FND-002 → TST-002 → EPH-001 → FND-002). Product-owner decision. | astro_core, EPH-001, TST-002 | FND-002 / EPH-001 task Notes |
| 2026-11-12 | `Body` is defined by ZOD-FND-002; ZOD-FND-012 adds JSON only. | Both task files listed it; FND-002 needs it first. | astro_core, FND-012 | FND-002 / FND-012 task Notes |

## Verification

ZOD-FND-002, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| AC1: no Flutter/UI dependency | ARCH-2 guard in `fvm dart run melos run test` | 15/15. `astro_core` closure and import scan clean |
| AC2–AC4 + Review Focus | `fvm dart run melos exec --scope=astro_core -- dart test test/ephemeris` | 20/20: `Body` order; `EclipticPosition` range/NaN/−0.0; `UtcRange` inclusive and UTC-only; fake-port contract (injection, retrograde from speed, typed out-of-range, exhaustive switch, node delegation) |
| Exhaustiveness guard | Mutation: add an unhandled `EphemerisFailure` subtype | Compile error "not exhaustively matched" (reverted) |
| Lint | `fvm dart run melos run lint` | Exit 0 |
| Code review | Fresh reviewer, whole branch | With fixes (optional): 0 Critical, 0 Important, 4 Minor. 3 doc minors promoted and fixed; 1 deferred (below). The cross-package `MeanAscendingNodeFormula` mixin plan was verified to compile |

**Deferred review minor (FND-002):** the contract-test fake doesn't enforce the UTC requirement on its node path, and there's no port-level local-time test (`UtcRange` covers the rule).

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

- **Current task branch:** `task/ZOD-FND-002-ephemeris-port` (from `main` @ `0303645`)
- **Relevant commits:** ZOD-FND-001 merged to `main` as `0303645` (PR #2). FND-002: `32da922` value types · `025725e` port contract + sealed results · `4f9db30` FND-001 record correction · `8da2b91` review doc fixes · plus planning/docs commits
- **Pull request:** FND-001 → https://github.com/yoadazani/zodiann/pull/2 (merged). FND-002: to be opened (link recorded after push)
- **Unmerged task branches others depend on:** `task/ZOD-FND-002-ephemeris-port` (ZOD-FND-012, ZOD-EPH-001, ZOD-FND-003 need it on `main`)
- **Uncommitted changes:** none
- **Preserve:** `.idea/` and `.qodo/` are local IDE folders. Never stage them. `.fvm/` is a local symlink (gitignored).
