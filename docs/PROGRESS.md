# Zodiann — Development Progress

Verified record of actual development state. See `docs/development/TASKS.md` for the full roadmap and `.claude/skills/zodiann-development/SKILL.md` for the workflow.

## Project Status

- **Current phase:** Phase 1 — Foundations
- **Overall status:** FND-001, FND-002, FND-012, EPH-001, TST-002, GAN-001 and GAN-002 merged; automatic plan review in place. ZOD-GAN-003 merged. Planning ZOD-TST-012 (T-GAN-4 date-mapping suite). 8 of 205 tasks done.
- **Last updated:** 2026-11-12

## Completed Tasks

| ID | Name | Status | Verification evidence |
|---|---|---|---|
| ZOD-GAN-003 | Implement Gann date/number mapping per mode | Done ([PR #10](https://github.com/yoadazani/zodiann/pull/10), merged `8655a9d`) | `gann_core` dates 47 (values 32, format 15): design references (cell 139 = 31.8.26; 52 = 9.11.26 12:00; today 209), spring/autumn DST jumps (05:00 / 03:00) via an injected zone, leap and year-end rollovers, local-midnight and travel today cells, sub-minute before-anchor → null, block boundaries, overflow guards, `d.m.yy` / `HH:MM` literals. Mutants (a)–(f) and 4 format mutants all caught. Plan review: 2 rounds. Code review: Ready to merge, 0 Critical / 0 Important; 2 test minors promoted, 3 deferred. Plan: [`docs/plans/ZOD-GAN-003-date-number-mapping.md`](plans/ZOD-GAN-003-date-number-mapping.md) |
| ZOD-GAN-002 | Implement Gann highlight classification (blue/yellow/gray) | Done ([PR #9](https://github.com/yoadazani/zodiann/pull/9), merged `1284889`) | `gann_core` highlight 13 + spiral 24: geometric oracle and literal angles over 61×61, Appendix B rings 1–6, 9×9 = 16/16/16, 90° column above (forward mapping), outermost ring, FND-012 default-rule equivalence. Mutants (a)–(e) plus a mirrored spiral all caught. Plan review: Approve (2 rounds). Code review: 0 Critical / 0 Important, 2 minors promoted and fixed. Plan: [`docs/plans/ZOD-GAN-002-highlight-classification.md`](plans/ZOD-GAN-002-highlight-classification.md) |
| ZOD-GAN-001 | Implement the Gann spiral position formulas (k, j, i, θ) | Done ([PR #8](https://github.com/yoadazani/zodiann/pull/8), merged `ef1ea48`) | `gann_core` spiral 23/23: reference table (design-checked), geometric clockwise for rings 1–6, neighbours 1…3721, rings vs the integer definition to 200,000 and at 94906263²+1, Appendix B, corners, round trips 9×9 / 61×61 / top of range, −2^63 rejection. Integer-correction mutation → fail. Plan review: Approve (2 rounds; 1 Critical + 5 Important fixed in the plan). Code review: 19 mutants, all non-equivalent killed; 1 minor promoted and fixed test-first, 2 applied. Plan: [`docs/plans/ZOD-GAN-001-spiral-positions.md`](plans/ZOD-GAN-001-spiral-positions.md) |
| ZOD-TST-002 | Author the mean-node formula exactness test (T-EPH-2) | Done ([PR #7](https://github.com/yoadazani/zodiann/pull/7), merged `a86e284`) | T-EPH-2 suite 12/12 + fixture shape 6/6. Production matches an independent reference (Meeus JD, literal coefficients) within 1e-9° on 53 reference dates. Max deviation from full Meeus over ±100 years (daily) = 0.0021292° < 0.01°. Mutation proofs: either coefficient → fail; wrong rate → bound fail (0.012077°); impossible fixture date → fail. Plan review: Approve (2 rounds). Code review: 0 Critical / 0 Important, 1 minor fixed, 3 deferred. Plan: [`docs/plans/ZOD-TST-002-mean-node-exactness.md`](plans/ZOD-TST-002-mean-node-exactness.md) |
| ZOD-EPH-001 | Implement the mean ascending lunar node formula | Done ([PR #5](https://github.com/yoadazani/zodiann/pull/5), merged `a21e4ed`) | `astro_core` 41/41 (epoch exact, 1900 / 2100 / 2026 references, normalization incl. the `−1e-15` edge, constant speed, non-UTC rejection, coefficients, "never direct" 1800–2400, node bypasses `coveredRange`) · lint exit 0. Ad-hoc coefficient mutations each fail 3 tests. Review: 0 Critical / 0 Important. The reviewer fuzzed `normalizeDegrees` over the full double range. 4 minor doc/test items fixed. Plan: [`docs/plans/ZOD-EPH-001-mean-node.md`](plans/ZOD-EPH-001-mean-node.md) |
| ZOD-FND-012 | Define `SquareConfig`, `HighlightRule`, `Crossing` data classes (`UserSettings` → SET-007) | Done ([PR #4](https://github.com/yoadazani/zodiann/pull/4), merged `13ea8e6`) | `gann_core` 33/33 · `astro_core` 26/26 · workspace architecture 17/17 · lint exit 0. The `Crossing` guard was proven to fail on an injected reference. Review: 0 Critical, 2 Important fixed, 3 minors promoted and fixed test-first (strict ISO-8601, out-of-range wall clock, required `anchor` key), 2 deferred. Plan: [`docs/plans/ZOD-FND-012-data-model.md`](plans/ZOD-FND-012-data-model.md) |
| ZOD-FND-002 | Define the `EphemerisPort` interface contract | Done ([PR #3](https://github.com/yoadazani/zodiann/pull/3), merged `331c7dc`) | `astro_core`: 20/20 tests (value types, sealed results, fake-port contract). The exhaustive switch was proven by a mutation that failed to compile. Lint exit 0. ARCH-2 guard 15/15. Review: 0 Critical / 0 Important. 3 doc minors were promoted and fixed, 1 deferred. Plan: [`docs/plans/ZOD-FND-002-ephemeris-port.md`](plans/ZOD-FND-002-ephemeris-port.md) |
| ZOD-FND-001 | Set up the Melos monorepo workspace | Done ([PR #2](https://github.com/yoadazani/zodiann/pull/2), merged `0303645`) | Bootstrap links 11 packages; `melos run lint` exit 0; `melos run test` exit 0 (15/15 architecture tests); `astro_core` / `gann_core` depend only on `test` (dev), with no Flutter in their transitive closure. See Verification. Plan: [`docs/plans/ZOD-FND-001-melos-workspace.md`](plans/ZOD-FND-001-melos-workspace.md) |

## Current Task

- **ID:** ZOD-TST-012
- **Name:** Author the Gann date-mapping test suite (T-GAN-4)
- **Status:** Plan written and reviewed (plan-reviewer: 2 rounds, Approve; 1 Critical + 2 Important + 8 Minor applied), awaiting user approval
- **Plan:** [`docs/plans/ZOD-TST-012-gann-date-mapping-suite.md`](plans/ZOD-TST-012-gann-date-mapping-suite.md)
- **Completed steps:** plan written; reference values verified by a scratch run against `main` @ `8655a9d` and independently by the reviewer; plan review complete.
- **Remaining steps:** approval → Task 1 (oracle, DST, today marking) → Task 2 (leap years, mutation proof) → Task 3 (review, close-out).

## Next Recommended Task

- **ID:** to be selected next. The pure-math Square of Nine core (GAN-001/002/003) is complete; the candidates are the test suites (TST-010/011/012/013) or the shared UI tokens (FND-013 → UI-001).
- **Carry into ZOD-TST-012 / ZOD-TST-013:**
  - Inject a fake `LocalTimeZone` for DST cases (never depend on the machine's zone); expected dates and strings are literals.
  - GAN-003's mutants (wall-clock addition, UTC date for today, anchor date via the zone, dropped `+1`, hard-coded 4; padded day/month, 4-digit or unpadded year) are a ready mutation-proof list.
- **Carry into ZOD-TST-010 / ZOD-TST-011:**
  - The GAN-001 review's 19-mutant list (mirrored x/y, no flip, 90° rotation, j/i off by one, `%` vs `remainder`, segment `<` → `<=`, …) is a ready starting point for the mutation proof.
  - Classification is invariant under rotation and mirroring, so **pin orientation through θ or (x, y) via the forward mapping, not through category**. GAN-002's own mirror mutation showed that a check routed through `spiralNumberAt` misses it.
- **Carry into ZOD-TST-001:**
  - Reuse `packages/astro_core/test/fixtures/reference_dates.json` (add-only, bump `version`).
  - Its shape test limits instants to the T = ±1 window (≤ 2100-01-01T12:00Z). If TST-001 adds later-2100 instants (ACC-1 says "1900 to 2100"), move that window check into the T-EPH-2 suite, which only needs it for the bound.
- **Carry into ZOD-EPH-002/004 (adapters):**
  - Reuse the "node at 1900 succeeds while the Moon is out of range" check in each adapter's tests.
  - Consider an architecture guard so the coefficient literals `125.04452` / `1934.136261` appear only in `mean_node.dart`. Test files stay exempt for TST-002's independent coefficients.
  - Normalize with `normalizeDegrees`.
- **Why not FND-003 yet:** the Swiss Ephemeris FFI spike must run a real computation on **both Android and iOS**. An iOS build needs macOS/Xcode, which this Windows machine can't provide. That needs a decision (a Mac, a cloud macOS runner, or splitting the spike) before FND-003 starts. It also benefits from ZOD-FND-010 (license) first.
- **Can run independently:** ZOD-FND-010 (Swiss Ephemeris license research, Critical, no code).
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

**Planning** (established 2026-11-12, PR #6)
- Every implementation plan, and every material revision of one, goes through the **Automatic Plan Review** in `zodiann-development` before the user sees it.
- The `plan-reviewer` subagent (`.claude/agents/plan-reviewer.md`) reviews the plan. Critical and Important corrections are applied, user decisions are surfaced (never auto-resolved), and there are at most two rounds.
- The plan carries a `## Plan review` record.
- If the agent type isn't loaded yet, the workflow falls back to a general-purpose subagent with the same instructions.

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

**Angles and the node** (established in ZOD-EPH-001)
- Normalize every longitude with `normalizeDegrees` (`astro_core`), never a bare `x % 360`. Dart's `%` can return exactly `360.0` for tiny negatives, and `EclipticPosition` rejects that.
- The mean-node formula exists once (`meanAscendingNodeAt` in `mean_node.dart`). `EphemerisPort` adapters `with MeanAscendingNodeFormula implements EphemerisPort` and answer `Body.node` **before** checking `coveredRange`, because the node is formula-based and not bounded by the data range.
- The node's retrograde state is the fixed flag `Body.hasConstantMeanRetrograde` ("℞ Mean"), never derived from speed.

**Square of Nine spiral** (established in ZOD-GAN-001)
- Use `spiralCell(n)` / `spiralNumberAt(x, y)` from `gann_core`. Never re-derive positions in UI or export code.
- Coordinates are relative to cell 1, with **x right and y down** (screen). The orientation is SQ-8's fixed one: 2 left of 1, clockwise. 90° (north) is the column of cells straight above cell 1, and 270° straight below.
- The valid range is `1 … maxSpiralNumber` / rings `0 … maxSpiralRing`, shared by both directions. The center (`n = 1`) has `null` index, steps and angle.
- Highlight classification works on the integers `i` and `k`, not on the `double` angle `θ`.

**Square of Nine highlights** (established in ZOD-GAN-002)
- `classifyHighlight(spiralCell(position))` is the single source of a cell's highlight category (axis / diagonal / eighth / none). Classify by spiral **position**, never by the displayed number or date. That's the working assumption while the numeric-anchor decision (TASKS.md §6.2) is open.
- Colors come from the square's rules via `highlightRuleFor(category, config.highlights)` → `colorToken`. A missing rule means no highlight. Never hard-code colors per category.
- Arbitrary user-defined rule evaluation is ZOD-EXT-008. Don't evaluate `HighlightRule.match` ad hoc in UI or export code.

**Square of Nine dates** (established in ZOD-GAN-003)
- **Time-zone rule (NFR-A3):** date-and-time cells are `anchor.instant + stepHours·(n−1)` absolute hours, shown in the device's current zone via `localWallClock(…, const DeviceTimeZone())`; the DST hour jump is visible, never corrected. Dates mode is `anchor.wallClock` date + (n−1) days, unaffected by DST or travel. Today's cell uses the device zone.
- Use `cellDate` / `cellMoment` / `todayCellInDatesMode` / `nowCellInDateTimeMode` / `daysAfterAnchor` / `hoursAfterAnchor`; never re-derive dates in UI or export code. Inject `LocalTimeZone` so code stays testable.
- Display through `formatCellDate` (`d.m.yy`) and `formatCellTime` (`HH:MM`); English month-first order is ZOD-L10-010, wrapping these.
- Calendar dates and wall clocks are UTC-flagged `DateTime` carriers; all inputs must be UTC (else `ArgumentError`). Out-of-range cells throw `ArgumentError`, never wrap.

**Accuracy tests** (established in ZOD-TST-002)
- Accuracy and verification suites live in `packages/<pkg>/test/accuracy/`. Their expected values come from an **independent** reference: only the code under test is imported (`show …`), with literal reference coefficients and test-local helpers. Production constants and helpers are never used for expectations.
- Each verification suite is accompanied by a **mutation proof**: alter each production constant or behaviour it guards, observe the failure, restore, and record it in the commit message.
- The shared reference date set is `packages/astro_core/test/fixtures/reference_dates.json`. It's add-only: increment `version` when adding; never drop or change an instant. A v1-subset test enforces this.

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
| 2026-11-12 | Public `normalizeDegrees`; T computed from microseconds since 2000-01-01T12:00Z; the mean-℞ state is a fixed `Body` getter; the coefficients are public constants. | The 360.0-edge test needs a directly testable normalizer, and adapters need it too. Microseconds are exact (int64, no overflow at DateTime limits). The flag is a property of the body, not of a source. One production source for the coefficients, for TST-002's mutation proof (TST-002 keeps independent reference values). | astro_core, EPH-002/004/005, TST-002 | EPH-001 plan |
| 2026-11-12 | Automatic plan review: a `plan-reviewer` subagent integrated into `zodiann-development` (no separate skill; Superpowers `writing-plans` reused unchanged). | Catches plan-level problems (cycles, ownership overlaps, wrong commands, unverified numbers) before the product owner reviews. User request. | All future plans | PR #6 |
| 2026-11-12 | ZOD-TST-002 defines the shared reference date set (`packages/astro_core/test/fixtures/reference_dates.json`, version in the content). ZOD-TST-001 reuses it add-only and bumps the version. | TST-001 is blocked behind EPH-002 / FND-003; T-EPH-1 and T-EPH-2 must share dates. Product-owner decision. | TST-001, TST-002 | TST-001 / TST-002 task Notes, TST-002 plan |
| 2026-11-12 | ZOD-GAN-001's criterion "T-GAN-1 passes" was amended to "covered by its own unit tests; T-GAN-1 tracked by ZOD-TST-010" (same resolution as EPH-001). TST-010 gets independence and mutation-proof rules. | Removes the GAN-001 ↔ TST-010 cycle. Product-owner decision. | GAN-001, TST-010 | GAN-001 / TST-010 task Notes |
| 2026-11-12 | T-GAN-3 wording: **90° is the axis above cell 1** (270° below). The spec's "270 axis (the row above cell 1)" is treated as a typo, and the GAN-002 / TST-010 criteria were corrected. The spec file is unchanged; the notes record the correction. | The formula, SQ-8, Appendix C and the design reference all agree on 90° = North above. Product-owner decision. | GAN-002, TST-010 | GAN-002 / TST-010 task Notes |
| 2026-11-12 | ZOD-GAN-002: the "T-GAN-2/3 passes" criteria were amended (own unit tests; dedicated suites in TST-011 / TST-010). The classifier is fixed and integer-based (spec rules on `i`, `k`), mapped to default rule ids `axes` / `diagonals` / `eighths`. Evaluating arbitrary user rules is ZOD-EXT-008. | Same cycle resolution as EPH-001 / GAN-001. MVP spec rules are fixed, and user rules are an optional extension. Product-owner decisions. | GAN-002, TST-010/011, EXT-008 | GAN-002 / TST-011 / EXT-008 task Notes |
| 2026-11-12 | **Time-zone rule (NFR-A3), resolving the spec's open question:** date-and-time cells step in absolute time and are shown in the **device's local zone** (visible one-hour DST jump). Today's cell uses the device zone. Dates mode uses the anchor's own calendar date plus whole days. The anchor field shows device-zone time. | The spec's working assumption (line 74); DATA-4 is satisfied by the saved instant and offset. Product-owner decision. | GAN-003, SQR-002, SET-002, DAT-005/009, TST-012 | GAN-003 / SQR-002 / TST-012 task Notes |
| 2026-11-12 | ZOD-GAN-003: "T-GAN-4 / T-FMT-1 passes" amended (own unit tests; dedicated suites in TST-012 / TST-013). `stepHours` has **no upper cap** (≥ 1, overflow guarded; SET-004 decides the UI range). | Same cycle resolution as before; a cap isn't needed with the overflow guards. Product-owner decisions. | GAN-003, TST-012/013, SET-004 | GAN-003 plan |
| 2026-11-12 | `Body.node` bypasses `coveredRange` in every adapter. | The analytical formula is independent of the source's data files. Already in the FND-002 contract, restated on the mixin. Pinned by the 1900 test. | EPH-002/003/004 | EPH-001 plan Revision 2 |

## Verification

ZOD-GAN-003, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| AC1: anchor cell = anchor date; today across DST and leap year; T-GAN-4 → TST-012 | `fvm dart run melos exec --scope=gann_core -- dart test test/dates` | Anchor cell exact (incl. 00:30+03:00, UTC date a day earlier); today 4 at 00:30 local across spring DST; leap 4 / common 3; year end 3; design 209; invariant `cellDate(todayCell)` = local date |
| AC2: `d.m.yy` no leading zero; T-FMT-1 → TST-013 | same | `4.1.24`, `14.1.24`, `9.10.26`, `31.12.99`, `5.1.05`, `1.1.00`; mutants padded day / month, 4-digit year, unpadded year each fail (7/4/8/2) |
| AC3: 4-hour square across DST shows the one-hour jump | same + mutation (a) | Spring 20:00 → 00:00 → 05:00, autumn 20:00 → 00:00 → 03:00; wall-clock addition mutant fails 5 tests |
| Mutation proof (Task 1) | ad-hoc mutants, restored | (a) −5, (b) instant date −8, (c) UTC today −2, (d) no +1 −6, (e) hard-coded 4 −2, (f) anchor date via zone −2 |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 / `gann_core` 116 (dates 47) |
| Code review | Fresh reviewer, whole branch | Ready to merge: 0 Critical / 0 Important. Promoted: year-end today cell (catches the UTC-today mutant) and `14.1.24`. 3 deferred (below) |

**Deferred review minors (GAN-003):**
- `cellMoment`'s `on Object` + `ArgumentError`/`RangeError` check can be `on ArgumentError` (`RangeError` is a subtype; identical behaviour).
- `_requireUtc` is duplicated in the three `src/dates` files.
- `DeviceTimeZone` could use `utc.toLocal().timeZoneOffset` (identical behaviour).

ZOD-GAN-002, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| AC1: own unit tests, 9×9 = 16/16/16, Appendix B per ring; T-GAN-2 → TST-011 | `fvm dart run melos exec --scope=gann_core -- dart test test/highlight test/spiral` | 9×9 totals; rings 1–6 literal 4/4/0 and 4/4/8; geometric oracle over 61×61 (0 mismatches); outermost ring (`maxSpiralRing`) exact |
| AC2: axes and diagonals per Appendix C (90° straight above, 270° below); T-GAN-3 → TST-010 | same | First-ring directions; the column above (4, 15, 34 axis; 14, 16 eighth); every 90° cell above / 270° cell below via the forward mapping; literal angles over 61×61 |
| AC3: priority order | same + mutation | Cells 2 / 13 / 12 / 26. Mutants (a) yellow/gray swapped, (b) yellow before blue, (c) 2k → k, (d) indexInRing as i, (e) gray removed: each fails (8/8/8/5/6), then restored |
| FND-012 defaults = classifier | same | Default-rule angles evaluated in ascending priority match the classifier on every 61×61 cell |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 / `gann_core` 70 (highlight 13, spiral 24), `astro_core` 53, workspace 17 |
| Plan review | `plan-reviewer`, 2 rounds | Approve (round 1: 1 Important "position, not value" + 7 Minor applied; round 2: 2 Minor applied) |
| Code review | Fresh reviewer, whole branch | Ready to merge: 0 Critical / 0 Important. 2 minors promoted and fixed: orientation pinned via the forward mapping (a mirrored-spiral mutant now fails; the first attempt didn't, and was replaced) and the outermost-ring test. 1 deferred |

**Deferred review minor (GAN-002):** replace `isCenter` + `stepsFromAxis!` with a type-checked null test (behaviour identical).

ZOD-GAN-001, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| AC1: own unit tests (2 left of 1, clockwise, Appendix B ring ends, 9×9 round trip); T-GAN-1 → TST-010 | `fvm dart run melos exec --scope=gann_core -- dart test test/spiral` | 23/23: reference table (16 rows, design-checked), first-ring order, geometric clockwise for rings 1–6 (one wrap at index k−2), θ = geometric angle on axes and diagonals, neighbours for 1…3721 |
| AC2: ring 1 ends at 9, ring 4 at 81 | same | All six Appendix B rows; ring boundaries 9/10, 25/26, 81/82, 3721/3722 |
| AC3: (x, y) round trip over 9×9 | same | Both directions over 9×9 and 61×61, all four corners for rings 1–5, top of range (`maxSpiralNumber`) |
| Robustness | same + mutation | Rings match the integer definition to 200,000 and at 94906263² ± 1. Removing the correction → fail. n out of range, k out of range and −2^63 coordinates all rejected |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 / `gann_core` 56, `astro_core` 53, workspace 17 |
| Plan review | `plan-reviewer`, 2 rounds | Approve (round 1: 1 Critical + 5 Important + 6 Minor applied; round 2: 2 Minor applied) |
| Code review | Fresh reviewer, whole branch | With fixes: 0 Critical / 0 Important. 19 mutants, all non-equivalent killed (2 equivalent). −2^63 `abs()` overflow promoted and fixed RED→GREEN. 2 minors applied |

ZOD-TST-002, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| AC1: independent reference | `fvm dart run melos exec --scope=astro_core -- dart test test/accuracy` | Only `meanAscendingNodeAt` imported (`show`). Meeus JD self-check exact at 2451545.0 / 2415020.0 / 2488070.0. Production matches the reference within 1e-9° on all 53 reference dates (actual ≤ 8.2e-12°) |
| AC2: coefficient changes are caught | Mutation proof | `125.04453` → reference-match fails; `1934.136262` → reference-match + speed fail. Restored |
| AC3: within 0.01° of full Meeus over ±100 years | same | Daily sweep (73,051 samples, T = −1 … +1 exactly): max 0.0021292° (pinned `closeTo(0.00213, 1e-5)`). Wrong rate `1934.146261` → fails at 0.012077° (T = +1). Restored |
| Shared fixture | `reference_dates_test.dart` | 6/6: version, v1 subset, ≥ 50 unique, canonical (impossible `2026-02-30` rejected by mutation), T = ±1 window, chronological |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 / `astro_core` 53, `gann_core` 33, workspace 17 |
| Plan review | `plan-reviewer`, 2 rounds | Approve (round 1: 1 Important + 6 Minor applied; round 2: 2 Minor applied) |
| Code review | Fresh reviewer, whole branch | Ready to merge: 0 Critical / 0 Important. Its own extra mutations (ΔT-shifted epoch, /36524 speed, 36524-day century, broken seconds term) were all caught. 1 minor fixed, 3 deferred |

**Deferred review minors (TST-002):**
- The 1e-9 exactness check covers the 53 fixture dates only; the daily loop could assert it too.
- The fixture window ends at T = +1 (see the TST-001 carry-over).
- Two test names are longer than 80 columns.

ZOD-EPH-001, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| AC1: matches the formula on spot-checked dates | `fvm dart run melos exec --scope=astro_core -- dart test` | Epoch exactly 125.04452; 1900 → 259.15430411757734, 2100 → 350.93473588242273, 2026-11-12 → 325.48865621351126 (1e-9°). Independently re-derived from JD by the reviewer |
| AC2: implemented and covered by own unit tests | same | All six required areas covered: epoch, before/after, normalization incl. `−1e-15 → 0.0`, constant speed `−1934.136261/36525`, non-UTC rejection, coefficients. Ad-hoc mutations of either coefficient fail 3 tests |
| AC3: never reported as direct | same | Speed < 0 for every year 1800–2400; `hasConstantMeanRetrograde` true only for the node |
| Contract: node bypasses `coveredRange` | same | Adapter with range 2000–2100: node at 1900 succeeds, Moon at 1900 out of range |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 / `astro_core` 41, `gann_core` 33, workspace 17 |
| Code review | Fresh reviewer, whole branch | 0 Critical, 0 Important, 4 Minor (all fixed: 1 promoted to match the accuracy-wording instruction) |

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

- **Current task branch:** `task/ZOD-TST-012-gann-date-mapping-suite` (from `main` @ `8655a9d`)
- **Relevant commits:** FND-001 → `0303645` (PR #2), FND-002 → `331c7dc` (PR #3), FND-012 → `13ea8e6` (PR #4), EPH-001 → `a21e4ed` (PR #5), plan-reviewer → `83ee377` (PR #6), TST-002 → `a86e284` (PR #7), GAN-001 → `ef1ea48` (PR #8), GAN-002 → `1284889` (PR #9), GAN-003 → `8655a9d` (PR #10), all merged. TST-012 branch: planning commits only
- **Pull request:** PRs #2–#10 merged. TST-012: not opened yet
- **Unmerged task branches others depend on:** none
- **Uncommitted changes:** none
- **Preserve:** `.idea/` and `.qodo/` are local IDE folders. Never stage them. `.fvm/` is a local symlink (gitignored).
