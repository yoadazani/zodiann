# Zodiann — Development Progress

Verified record of actual development state. See `docs/development/TASKS.md` for the full roadmap and `.claude/skills/zodiann-development/SKILL.md` for the workflow.

## Project Status

- **Current phase:** Phase 1 — Foundations
- **Overall status:** ZOD-FND-001, ZOD-FND-002 and ZOD-FND-012 merged. Planning ZOD-EPH-001 (mean node). 3 of 205 tasks done.
- **Last updated:** 2026-11-12

## Completed Tasks

| ID | Name | Status | Verification evidence |
|---|---|---|---|
| ZOD-FND-012 | Define `SquareConfig`, `HighlightRule`, `Crossing` data classes (`UserSettings` → SET-007) | Done ([PR #4](https://github.com/yoadazani/zodiann/pull/4), merged `13ea8e6`) | `gann_core` 33/33 · `astro_core` 26/26 · workspace architecture 17/17 · lint exit 0. The `Crossing` guard was proven to fail on an injected reference. Review: 0 Critical, 2 Important fixed, 3 minors promoted and fixed test-first (strict ISO-8601, out-of-range wall clock, required `anchor` key), 2 deferred. Plan: [`docs/plans/ZOD-FND-012-data-model.md`](plans/ZOD-FND-012-data-model.md) |
| ZOD-FND-002 | Define the `EphemerisPort` interface contract | Done ([PR #3](https://github.com/yoadazani/zodiann/pull/3), merged `331c7dc`) | `astro_core`: 20/20 tests (value types, sealed results, fake-port contract). The exhaustive switch was proven by a mutation that failed to compile. Lint exit 0. ARCH-2 guard 15/15. Review: 0 Critical / 0 Important. 3 doc minors were promoted and fixed, 1 deferred. Plan: [`docs/plans/ZOD-FND-002-ephemeris-port.md`](plans/ZOD-FND-002-ephemeris-port.md) |
| ZOD-FND-001 | Set up the Melos monorepo workspace | Done ([PR #2](https://github.com/yoadazani/zodiann/pull/2), merged `0303645`) | Bootstrap links 11 packages; `melos run lint` exit 0; `melos run test` exit 0 (15/15 architecture tests); `astro_core` / `gann_core` depend only on `test` (dev), with no Flutter in their transitive closure. See Verification. Plan: [`docs/plans/ZOD-FND-001-melos-workspace.md`](plans/ZOD-FND-001-melos-workspace.md) |

## Current Task

- **ID:** ZOD-EPH-001
- **Name:** Implement the mean ascending lunar node formula
- **Status:** Plan revision 2 written, awaiting user approval
- **Plan:** [`docs/plans/ZOD-EPH-001-mean-node.md`](plans/ZOD-EPH-001-mean-node.md)
- **Completed steps:** Task definitions amended (EPH-001 criterion; TST-002 rules), with product-owner confirmation. Branch created; plan written.
- **Remaining steps:** Plan approval → Task 1 (`normalizeDegrees` + mean-℞ flag) → Task 2 (formula + mixin) → Task 3 close-out.

## Next Recommended Task

- **ID:** to be re-evaluated after ZOD-EPH-001. Candidate: ZOD-TST-002 (T-EPH-2, depends on EPH-001). Its date-set reference to T-EPH-1 (ZOD-TST-001) must be settled when it's planned.
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

**Data model and JSON** (established in ZOD-FND-012)
- Model classes are immutable `final class`es with hand-written `toJson` / `static fromJson(Object?)`, value equality and `toString`. No codegen, no `equatable` / `collection`.
- Constructors validate invariants and throw `ArgumentError`. `fromJson` throws **only** `FormatException` for any invalid input, using `gann_core`'s internal strict readers (`json_read.dart`) and `buildOrFormatError`. Missing keys are errors; a nullable field must still be present (explicit `null`).
- JSON shape: camelCase keys equal to field names. Enums as their `name`. Sealed variants carry a `"type"` discriminator. Doubles accept any JSON number.
- Date-times: UTC timestamps are canonical ISO-8601 ending in `Z`. Moments with an offset use `OffsetDateTime` (canonical ISO-8601 `±HH:MM`). Parsing is strict (`iso8601.dart`): impossible fields are rejected, never normalized.
- Lists held by models are unmodifiable copies.
- `HighlightRule.colorToken` is a MASTER.md §2.2 **role-family key** (`axis`, `diag`, `eighth`, …). The UI resolves it to `<family>-fill` / `<family>-ink`, plus the bare `<family>` accent where the design defines one.
- Derived results (e.g. `Crossing`) have no JSON and are never persisted. `test/architecture/crossing_not_persisted_test.dart` scans the persistence packages, currently `packages/shared_storage/lib`. **Add any new persistence package to its `storageLayers` list.**

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
| 2026-11-12 | `UserSettings` deferred from ZOD-FND-012 to ZOD-SET-007; FND-012 criterion amended. | The spec gives only a field list; several fields depend on open decisions (D-1, D-3, D-5/D19); it mixes wheel and square types. Product-owner decision. | SET-007, FND-012 | FND-012 / SET-007 task files |
| 2026-11-12 | `SquareConfig.anchor` is an `OffsetDateTime` (UTC instant + offset minutes, ISO-8601 with offset). | DATA-4 needs the offset saved; Dart `DateTime` cannot hold it. Product-owner decision. | gann_core, DAT-009, GAN-003 | FND-012 / DAT-009 task files |
| 2026-11-12 | Hand-written JSON and equality for the data model; `fromJson` raises only `FormatException`. | About 7 small types; no build_runner or new dependencies; one failure type for storage and backup import. | gann_core, astro_core, future SET-007/DAT-* | FND-012 plan |
| 2026-11-12 | `Crossing` has no JSON; "not persisted" is enforced by a root guard over `packages/shared_storage/lib`. | The task's JSON purpose is storage/backup, and the spec marks `Crossing` "Saved? No". The app shell is the composition root, not storage (review fix). | astro_core, shared_storage | FND-012 plan + review |
| 2026-11-12 | Strict canonical ISO-8601 parsing instead of `DateTime.parse`. | `DateTime.parse` silently normalizes Feb 30 → Mar 2, `+05:75`, etc., so a hand-edited backup would load a different date (review finding). | gann_core | FND-012 review fix |
| 2026-11-12 | `stepHours` only required ≥ 1 (default 4); no upper cap yet. | The spec says "4 in date and time mode" but SET-004 makes it editable. A cap is a product choice for GAN-003 / SET-004. | gann_core, GAN-003, SET-004 | FND-012 plan, deferred review minor |
| 2026-11-12 | ZOD-EPH-001's criterion "T-EPH-2 passes" was amended to "implemented and covered by its own unit tests; T-EPH-2 tracked by ZOD-TST-002". TST-002 gains explicit rules: a separate reference formula, a coefficient-mutation proof, and the 0.01° bound against the full Meeus formula over ±100 years. | Removes the EPH-001 ↔ TST-002 cycle while keeping EPH-001 → TST-002 and separate delivery. Product-owner decision. | EPH-001, TST-002 | EPH-001 / TST-002 task Notes |

## Verification

ZOD-FND-012, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| AC1: types compile; persisted types round-trip incl. anchor offset | `fvm dart run melos exec --scope=gann_core -- dart test` | 33/33: round-trip per mode with `+05:30` / `-03:30` anchors; offsets `+02:00`, `+05:30`, `+05:45`, `-03:30`, `Z`; extreme years and microseconds |
| AC2: `Crossing` not persisted | Root guard + `Crossing` has no JSON | 17/17 workspace architecture tests. The guard fails on an injected reference in `shared_storage` (then removed) |
| AC3: default highlight rules | `square_config_test` + `highlight_rule_test` | Axes / Diagonals / Eighths, priorities 1/2/3, angles per spec, tokens `axis` / `diag` / `eighth` |
| Robustness | `fromJson` rejection suites | Every malformed / tampered input → `FormatException` (reviewer probed nulls, non-maps, `1e400`, huge ints, `9.0` sizes, unknown enums, lenient dates) |
| `astro_core` | `… --scope=astro_core -- dart test` | 26/26 (`Body` JSON, `Crossing`) |
| Lint | `fvm dart run melos run lint` | Exit 0 |
| Code review | Fresh reviewer, whole branch | With fixes: 0 Critical, 2 Important (fixed), 7 Minor (3 promoted and fixed test-first, 1 folded in, 1 doc fix, 2 deferred) |

**Deferred review minors (FND-012):**
- `stepHours` has no upper bound (a cap belongs to GAN-003 / SET-004).
- `AnglesMatch` equality is order-sensitive and allows duplicates (revisit with EXT-008).

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

- **Current task branch:** `task/ZOD-EPH-001-mean-node` (from `main` @ `13ea8e6`)
- **Relevant commits:** FND-001 → `0303645` (PR #2), FND-002 → `331c7dc` (PR #3), FND-012 → `13ea8e6` (PR #4), all merged. EPH-001 branch: planning/docs commits only
- **Pull request:** PRs #2–#4 merged. EPH-001: not opened yet
- **Unmerged task branches others depend on:** none
- **Uncommitted changes:** none
- **Preserve:** `.idea/` and `.qodo/` are local IDE folders. Never stage them. `.fvm/` is a local symlink (gitignored).
