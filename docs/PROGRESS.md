# Zodiann — Development Progress

Verified record of actual development state. See `docs/development/TASKS.md` for the full roadmap and `.claude/skills/zodiann-development/SKILL.md` for the workflow.

## Project Status

- **Current phase:** Phase 1 — Foundations
- **Overall status:** FND-001, FND-002, FND-012, EPH-001, TST-002, GAN-001 and GAN-002 merged; automatic plan review in place. ZOD-GAN-003, ZOD-TST-012, ZOD-TST-013 and ZOD-TST-010 merged; ZOD-TST-011 merged — the Square of Nine core and all its verification suites are complete. ZOD-FND-005 (Flutter app shell) merged; iOS build/runtime verification outstanding (needs a Mac). ZOD-FND-013 (theme token skeleton) merged. ZOD-UI-001 (colour token values) done, PR open. 15 of 205 tasks done.
- **Last updated:** 2026-11-12

## Completed Tasks

| ID | Name | Status | Verification evidence |
|---|---|---|---|
| ZOD-UI-001 | Implement the color token values (dark + light) | Done (PR pending) | `shared_ui` 44/44: all 52 × 2 values against MASTER's tables and against `_source/kit.css` (second source); the 43 reference tiles per theme pixel-exact against `components_{dark,light}.png` (translucent over `surface` ±1, uniformity, per-theme rows, exact sizes); WCAG AA sanity (text roles, on-accent); test-only `TokenSwatchGrid` harness whose rendered pixels equal the same oracle. Mutants V1–V5 as planned. Harness PNGs match the reference crops side by side. Emulator-5554: bg exactly `#F5F6F8` / `#08080A`. Plan review: 2 rounds (7 Important applied). Code review: Ready to merge, all 104 values re-checked by hand; 3 minors deferred. Plan: [`docs/plans/ZOD-UI-001-color-token-values.md`](plans/ZOD-UI-001-color-token-values.md) |
| ZOD-FND-013 | Establish the design-token theme skeleton (dark + light `ColorScheme`) | Done ([PR #16](https://github.com/yoadazani/zodiann/pull/16), merged `ae666da`) | `shared_ui` 26/26 (5 extensions × MASTER key lists typed literally + values pinned to constructor order, lerp 0/0.5/1/null, copyWith one/all; `BodyColors.of` per `Body`; themes: brightness, all five extensions, ColorScheme mapping, no hidden defaults, sign tint 10 %/9 %). `astro_mobile` 16/16 (FND-005's 13 unchanged + device default, set dark/light/system without restart, mid-animation interpolated instance). Architecture 23/23 incl. the ARCH-7 colour-literal guard (only `shared_ui/lib/src/theme/tokens/` exempt). Mutants G1–G8 all caught. Emulator-5554: light unchanged from FND-005, dark OK. Plan review: Approve (2 rounds, 7 Important applied). Code review: Ready to merge; scanner gaps re-graded Important and fixed test-first; 3 minors deferred. Plan: [`docs/plans/ZOD-FND-013-theme-token-skeleton.md`](plans/ZOD-FND-013-theme-token-skeleton.md) |
| ZOD-FND-005 | Flutter app shell bootstrap (`apps/astro_mobile`) | Done (iOS build/runtime verification outstanding) ([PR #15](https://github.com/yoadazani/zodiann/pull/15), merged `e4a8859`) | `astro_mobile` 13/13 (shell 10: blank boot with no overrides, light/dark/live switch, Scaffold surface, fr → en, he → RTL, he Material strings, fake port by one override, `main()` single root `ProviderScope` wired to `appOverrides`; DI 3). Mutants M1–M8 all caught as planned (M8 proves the Hebrew Material test is independent of RTL). `flutter build apk --debug` ✓. Android on-device: emulator-5554 (Android 9, x86 + ARM translation), blank light and dark screens, no crash. iOS: project scaffolded, static checks only; build/runtime **outstanding**. Plan review: 4 rounds (2 + 2 after product-owner review), Approve. Code review: Ready to merge, 0 Critical / 0 Important, 5 minors deferred. Plan: [`docs/plans/ZOD-FND-005-flutter-app-shell.md`](plans/ZOD-FND-005-flutter-app-shell.md) |
| ZOD-TST-011 | Author the ring highlight-count test (T-GAN-2) | Done ([PR #14](https://github.com/yoadazani/zodiann/pull/14), merged `30ea9eb`) | `gann_core` T-GAN-2 suite 8: Appendix B rows 1–6 with every column asserted (cells placed geometrically, angle per cell, blue/yellow/gray/unhighlighted, side, last number), named 9×9 total 16/16/16 with unhighlighted center, T-GAN-2 rule for rings 7–30. Mutants H1–H7 caught exactly as planned. Plan review: Approve (2 rounds, 3 Important applied). Code review: Ready to merge, comment minors fixed, 1 deferred. Plan: [`docs/plans/ZOD-TST-011-gann-ring-counts-suite.md`](plans/ZOD-TST-011-gann-ring-counts-suite.md) |
| ZOD-TST-010 | Author the Gann spiral direction test suite (T-GAN-1, T-GAN-3) | Done ([PR #13](https://github.com/yoadazani/zodiann/pull/13), merged `3a447d5`) | `gann_core` T-GAN-1 6 + T-GAN-3 11: all 169 cells of the 13×13 design grid (literal, re-checked by two reviewers), 2 left of 1, unit-step + clockwise over 61×61 (3690 same-ring pairs), ring corners k ≤ 30, inverse round-trip 61×61; Appendix C rows over 30-cell rays (angle, category, `isNot` others), "only" over 61×61, 48 design highlight literals, angles in [0, 360). Mutants S1–S9, C1–C4 all caught. Plan review: Approve (2 rounds, 4 Important applied). Code review: Ready to merge, 2 minors promoted, 1 deferred. Plan: [`docs/plans/ZOD-TST-010-gann-axes-suite.md`](plans/ZOD-TST-010-gann-axes-suite.md) |
| ZOD-TST-013 | Author the date-format test (T-FMT-1) | Done ([PR #12](https://github.com/yoadazani/zodiann/pull/12), merged `c5e442f`) | `gann_core` T-FMT-1 suite 20: 15 literal spot checks (all single/double day-month combinations, `00`/`05`/`09` years, design references), parse-back over every valid date of 2024/2026 at 00:00 and 23:59:59.999 UTC (366/365 per time of day), two-digit year 1900–2100. Mutants F1–F8 all caught with the planned counts. Plan review: Approve (2 rounds, 1 Important applied). Code review: Ready to merge, 3 minors promoted and fixed. Plan: [`docs/plans/ZOD-TST-013-date-format-suite.md`](plans/ZOD-TST-013-date-format-suite.md) |
| ZOD-TST-012 | Author the Gann date-mapping test suite (T-GAN-4) | Done ([PR #11](https://github.com/yoadazani/zodiann/pull/11), merged `718edf1`) | `gann_core` T-GAN-4 suite 28: independent record-based Gregorian oracle (self-checked), fake zones mirroring real 2026 Israel / New York DST, full 61×61 chains in both modes, the one-hour jump (exactly one in 169 cells), R-4 duplicate/skip with 1-hour steps, today marking (literals, travel, 30-min sweeps at all four transitions), leap years incl. 2000/2100. Mutants M1–M9 all caught. Plan review: Approve (2 rounds). Code review: With fixes, 1 Important + 3 minors fixed test-first (probe mutants), 1 deferred. Plan: [`docs/plans/ZOD-TST-012-gann-date-mapping-suite.md`](plans/ZOD-TST-012-gann-date-mapping-suite.md) |
| ZOD-GAN-003 | Implement Gann date/number mapping per mode | Done ([PR #10](https://github.com/yoadazani/zodiann/pull/10), merged `8655a9d`) | `gann_core` dates 47 (values 32, format 15): design references (cell 139 = 31.8.26; 52 = 9.11.26 12:00; today 209), spring/autumn DST jumps (05:00 / 03:00) via an injected zone, leap and year-end rollovers, local-midnight and travel today cells, sub-minute before-anchor → null, block boundaries, overflow guards, `d.m.yy` / `HH:MM` literals. Mutants (a)–(f) and 4 format mutants all caught. Plan review: 2 rounds. Code review: Ready to merge, 0 Critical / 0 Important; 2 test minors promoted, 3 deferred. Plan: [`docs/plans/ZOD-GAN-003-date-number-mapping.md`](plans/ZOD-GAN-003-date-number-mapping.md) |
| ZOD-GAN-002 | Implement Gann highlight classification (blue/yellow/gray) | Done ([PR #9](https://github.com/yoadazani/zodiann/pull/9), merged `1284889`) | `gann_core` highlight 13 + spiral 24: geometric oracle and literal angles over 61×61, Appendix B rings 1–6, 9×9 = 16/16/16, 90° column above (forward mapping), outermost ring, FND-012 default-rule equivalence. Mutants (a)–(e) plus a mirrored spiral all caught. Plan review: Approve (2 rounds). Code review: 0 Critical / 0 Important, 2 minors promoted and fixed. Plan: [`docs/plans/ZOD-GAN-002-highlight-classification.md`](plans/ZOD-GAN-002-highlight-classification.md) |
| ZOD-GAN-001 | Implement the Gann spiral position formulas (k, j, i, θ) | Done ([PR #8](https://github.com/yoadazani/zodiann/pull/8), merged `ef1ea48`) | `gann_core` spiral 23/23: reference table (design-checked), geometric clockwise for rings 1–6, neighbours 1…3721, rings vs the integer definition to 200,000 and at 94906263²+1, Appendix B, corners, round trips 9×9 / 61×61 / top of range, −2^63 rejection. Integer-correction mutation → fail. Plan review: Approve (2 rounds; 1 Critical + 5 Important fixed in the plan). Code review: 19 mutants, all non-equivalent killed; 1 minor promoted and fixed test-first, 2 applied. Plan: [`docs/plans/ZOD-GAN-001-spiral-positions.md`](plans/ZOD-GAN-001-spiral-positions.md) |
| ZOD-TST-002 | Author the mean-node formula exactness test (T-EPH-2) | Done ([PR #7](https://github.com/yoadazani/zodiann/pull/7), merged `a86e284`) | T-EPH-2 suite 12/12 + fixture shape 6/6. Production matches an independent reference (Meeus JD, literal coefficients) within 1e-9° on 53 reference dates. Max deviation from full Meeus over ±100 years (daily) = 0.0021292° < 0.01°. Mutation proofs: either coefficient → fail; wrong rate → bound fail (0.012077°); impossible fixture date → fail. Plan review: Approve (2 rounds). Code review: 0 Critical / 0 Important, 1 minor fixed, 3 deferred. Plan: [`docs/plans/ZOD-TST-002-mean-node-exactness.md`](plans/ZOD-TST-002-mean-node-exactness.md) |
| ZOD-EPH-001 | Implement the mean ascending lunar node formula | Done ([PR #5](https://github.com/yoadazani/zodiann/pull/5), merged `a21e4ed`) | `astro_core` 41/41 (epoch exact, 1900 / 2100 / 2026 references, normalization incl. the `−1e-15` edge, constant speed, non-UTC rejection, coefficients, "never direct" 1800–2400, node bypasses `coveredRange`) · lint exit 0. Ad-hoc coefficient mutations each fail 3 tests. Review: 0 Critical / 0 Important. The reviewer fuzzed `normalizeDegrees` over the full double range. 4 minor doc/test items fixed. Plan: [`docs/plans/ZOD-EPH-001-mean-node.md`](plans/ZOD-EPH-001-mean-node.md) |
| ZOD-FND-012 | Define `SquareConfig`, `HighlightRule`, `Crossing` data classes (`UserSettings` → SET-007) | Done ([PR #4](https://github.com/yoadazani/zodiann/pull/4), merged `13ea8e6`) | `gann_core` 33/33 · `astro_core` 26/26 · workspace architecture 17/17 · lint exit 0. The `Crossing` guard was proven to fail on an injected reference. Review: 0 Critical, 2 Important fixed, 3 minors promoted and fixed test-first (strict ISO-8601, out-of-range wall clock, required `anchor` key), 2 deferred. Plan: [`docs/plans/ZOD-FND-012-data-model.md`](plans/ZOD-FND-012-data-model.md) |
| ZOD-FND-002 | Define the `EphemerisPort` interface contract | Done ([PR #3](https://github.com/yoadazani/zodiann/pull/3), merged `331c7dc`) | `astro_core`: 20/20 tests (value types, sealed results, fake-port contract). The exhaustive switch was proven by a mutation that failed to compile. Lint exit 0. ARCH-2 guard 15/15. Review: 0 Critical / 0 Important. 3 doc minors were promoted and fixed, 1 deferred. Plan: [`docs/plans/ZOD-FND-002-ephemeris-port.md`](plans/ZOD-FND-002-ephemeris-port.md) |
| ZOD-FND-001 | Set up the Melos monorepo workspace | Done ([PR #2](https://github.com/yoadazani/zodiann/pull/2), merged `0303645`) | Bootstrap links 11 packages; `melos run lint` exit 0; `melos run test` exit 0 (15/15 architecture tests); `astro_core` / `gann_core` depend only on `test` (dev), with no Flutter in their transitive closure. See Verification. Plan: [`docs/plans/ZOD-FND-001-melos-workspace.md`](plans/ZOD-FND-001-melos-workspace.md) |

## Current Task

- **None in progress.** ZOD-UI-001 is done on `task/ZOD-UI-001-color-token-values`, PR open (see Git State); merge on approval.

## Next Recommended Task

- **ID:** ZOD-UI-002 — Implement the typography scale (next in the Shared UI token track: tokens 001–003 before any component). Depends on UI-001 (PR open). Alternatives: ZOD-UI-003 (spacing/radius/elevation/sizing tokens), ZOD-FND-014 (go_router scaffold), ZOD-L10-001 (ARB infrastructure), ZOD-FND-010 (license research, no code). Handoff from UI-001: dark `text-3` is below 4.5:1 on `surface-2` / `surface-3` / `accent-soft` (4.48 / 4.05 / 4.03): avoid it there, or ZOD-NFR-009 decides.
- **Done in TST-012 / TST-013** (kept for reference; the same pattern applies to TST-010 / TST-011):
  - Inject a fake `LocalTimeZone` for DST cases (never depend on the machine's zone); expected dates and strings are literals.
  - GAN-003's mutants (wall-clock addition, UTC date for today, anchor date via the zone, dropped `+1`, hard-coded 4; padded day/month, 4-digit or unpadded year) are a ready mutation-proof list.
- **Done in TST-010 / TST-011** (kept for reference):
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

- **iOS build environment for ZOD-FND-003** (and later iOS work): development runs on Windows, and iOS builds need macOS/Xcode. A decision is needed before FND-003. It also blocks **ZOD-FND-005's outstanding iOS build + runtime verification** (ZOD-FND-004's task file includes no macOS runner). When the Mac run happens, also check two iOS items no task owns (FND-005 review minors): the launch screen is hard-coded white (`ios/Runner/Base.lproj/LaunchScreen.storyboard`, white flash in dark mode; use `systemBackgroundColor`), and `Info.plist` lacks `CFBundleLocalizations` (en, he), which iOS needs to treat the bundle as Hebrew-capable and to show the per-app language picker (L-3).
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
- Format and display oracles **parse the output back** and compare against the inputs, rather than rebuilding the expected string the way production does (T-FMT-1). Wall-clock carriers are checked at both ends of the day, to catch a stray `toLocal()` (effective on a non-UTC machine).
- `gann_core` suites live in `packages/gann_core/test/accuracy/` too. DST cases use **test-local fake zones mirroring real rules** (Israel / New York 2026 in T-GAN-4) and never the machine zone; calendar oracles work on records, not `DateTime` date arithmetic. Large-square properties are checked over all 3,721 cells, not samples.
- Each verification suite is accompanied by a **mutation proof**: alter each production constant or behaviour it guards, observe the failure, restore, and record it in the commit message.
- The shared reference date set is `packages/astro_core/test/fixtures/reference_dates.json`. It's add-only: increment `version` when adding; never drop or change an instant. A v1-subset test enforces this.

## Technical Decisions

| Date | Decision | Reason | Impacted components | Reference |
|---|---|---|---|---|
| 2026-11-13 | Token values verified three ways: MASTER's tables (typed), `_source/kit.css` (parsed) and the reference PNG pixels (43 shown tiles); swatch-grid harness is test-only (`shared_ui/test/support/`), no committed goldens (platform font rendering), PNGs written on demand via `ZODIANN_SWATCH_DIR`. | Independent oracles for a transcription task; UI-015 owns the gallery; goldens would be fragile in Linux CI. | `packages/shared_ui` tests | ZOD-UI-001 plan |
| 2026-11-13 | Theme lives in `shared_ui`: five `ThemeExtension`s (one per MASTER §2 group, fields = MASTER tokens, `tokens` map keyed by MASTER names), `ZodiannTokens`, `buildZodiannTheme` (ColorScheme + scaffold derived from `ZodiannSurfaces`), `ZodiannTheme.graphite/porcelain`. | Feature packages can import `shared_ui`, not the app; one source per colour. | `packages/shared_ui`, all UI | ZOD-FND-013 plan |
| 2026-11-13 | Token values are placeholders from Material's default `ColorScheme` (no literals; `bg` = default `surface` so the shell is unchanged); UI-001 fills MASTER values in `tokens/`. | User decision; keeps the FND-013 / UI-001 boundary exact. | `shared_ui/lib/src/theme/tokens` | ZOD-FND-013 plan, decision 1 | **Superseded by ZOD-UI-001** (MASTER values).
| 2026-11-13 | `themeModeProvider` (app, default system) drives `MaterialApp.themeMode`; app-level placeholder, not a feature contract (SET-003/SET-007 decide). | Runtime toggle without restart; feature packages can't import the app. | `apps/astro_mobile/lib/src/theme` | ZOD-FND-013 plan |
| 2026-11-13 | ARCH-7 guard: `test/architecture/no_color_literals_test.dart` fails on any colour literal in `apps/*/lib` or `packages/*/lib` outside `packages/shared_ui/lib/src/theme/tokens/`. | "Enforced by lint or review" made automatic; runs in `melos run test` (and in FND-004's CI once it exists). | All Flutter packages | ZOD-FND-013 plan |
| 2026-11-13 | App ID `com.zodiann.app` (Android `applicationId`/`namespace`, iOS bundle ID), display name "Zodiann". | Store identity; nothing in spec/tasks set it. User decision. | `apps/astro_mobile` android/ios | ZOD-FND-005 plan, decision 1 |
| 2026-11-13 | Placeholder theme seam `AppTheme.light/dark` (plain `ThemeData`, no color literals, `ThemeMode.system`). | **Superseded by ZOD-FND-013.** UI-001 → FND-013 → FND-005 makes the token theme unavailable. User decision; FND-013/UI-001 replace it. | `apps/astro_mobile/lib/src/theme` | ZOD-FND-005 plan, decision 2 |
| 2026-11-13 | Material types and `GlobalMaterialLocalizations.delegates` come from `package:material_ui`; never import `package:flutter/material.dart` or `flutter/cupertino.dart`. | Deprecated since Flutter 3.47; they fail `--fatal-infos`. | All Flutter packages | ZOD-FND-005 plan review C1 |
| 2026-11-13 | `ephemerisPortProvider` is an app-level placeholder (not exported, not a feature-package contract); unbound read throws a `StateError` naming `appOverrides`; `appOverrides` is the single binding list and deliberately non-const. | Feature packages must not import the app layer; an unbound source must fail loudly; a const list would hide a `main()` that drops `overrides:`. The first feature-side consumer decides the real contract. | `apps/astro_mobile/lib/src/di` | ZOD-FND-005 plan, P2 |
| 2026-11-13 | ARCH-3 means one Provider per screen, not one `ProviderScope`; single root scope in `main()`. Verification handed to ZOD-WHL-001 and ZOD-SQR-001 (added criteria). | Product-owner correction of FND-005 criterion 3. | Screen tasks | ZOD-FND-005 plan, decision 4 |
| 2026-11-13 | FND-005 marked `Done (iOS build/runtime verification outstanding)` with criterion 1 unchecked. | Product-owner decision 5: a conscious departure from "never mark complete before criteria are verified", limited to iOS verification this machine cannot perform (Android on-device was verified on emulator-5554). | Task status | ZOD-FND-005 plan, decision 5 + Task 4 ruling |
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

ZOD-UI-001, final run on 2026-11-13 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| shared_ui | `fvm dart run melos exec --scope=shared_ui -- flutter test` | 44/44 (values 4, reference 4, contrast 2, harness 8, FND-013's 26) |
| Mutation proof | V1–V5 on the token files, each confirmed applied, restored | V1 −3, V2 −3, V3 −3, V4 −4 (incl. contrast), V5 −2 (unshown token: MASTER + kit.css only). No compile errors |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 (root 23, astro_core 53, gann_core 189, shared_ui 44, astro_mobile 16) |
| Visual | harness PNGs (`ZODIANN_SWATCH_DIR`) vs reference crops | Same sections, order and colours in both themes |
| On device | debug APK on emulator-5554 | Background `#F5F6F8` light, `#08080A` dark; no crash |
| Code review | Fresh opus reviewer | Ready to merge; all 104 values re-checked by hand; 3 minors deferred (harness doesn't assert full token set, harness hex text from token, duplicated test helpers) |

**Known failures:** none.

ZOD-FND-013, final run on 2026-11-13 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| shared_ui | `fvm dart run melos exec --scope=shared_ui -- flutter test` | 26/26 |
| App | `… --scope=astro_mobile -- flutter test` | 16/16 (FND-005's 13 unchanged) |
| Architecture | `fvm dart test test/architecture` | 23/23 (ARCH-2 + ARCH-7 guard) |
| Mutation proof | ad-hoc mutants, each confirmed applied (`git diff`), all three suites run, restored | G1 literal in app −2, G2 `Colors.white` in theme −1, G3 primary→text −2, G4 lerp returns this −2, G5 drop `ok` −2, G6 hard-coded themeMode −2, G7 drop AspectColors −2, G8 lerp throws −6. No compile errors |
| Review fix | scanner: 5 new flagged samples (0X, digit separators, trailing comma, HSL, HSV) | RED (11 of 16) → GREEN |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 (root 23, astro_core 53, gann_core 189, shared_ui 26, astro_mobile 16) |
| On device | debug APK on emulator-5554 | Light identical to FND-005, dark OK, no crash |
| Code review | Fresh opus reviewer, whole branch | Ready to merge; 1 minor re-graded Important and fixed; 3 minors deferred (block comments, generated doc wording, `set` name) |

**Known failures:** none.

ZOD-FND-005, final run on 2026-11-13 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| App tests | `fvm dart run melos exec --scope=astro_mobile -- flutter test` | 13/13 (shell 10, DI 3) |
| Mutation proof | ad-hoc mutants on `lib/`, each confirmed applied against a backup, restored, `diff -r` clean | M1 ThemeMode.light −2, M2 he first −1, M3 no delegates −2, M4 ShellHome watches port −9, M5 unbound returns stub −1, M6 `main()` without overrides −1, M7 Widgets delegate only −2, M8 English Material delegate −1 (he Material only). No compile errors |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 (analyze clean in 11 packages; root 17, astro_core 53, gann_core 189, astro_mobile 13) |
| Android build | `fvm flutter build apk --debug` | ✓ `app-debug.apk` (first Gradle run ~595 s; NDK/CMake auto-installed) |
| Android on-device | `adb install` + `am start` on emulator-5554 (AOSP Android 9, API 28, x86, ARM translation) | Blank light screen; blank dark screen with `cmd uimode night yes`; process alive, no crash |
| Code review | Fresh opus reviewer, whole branch | Ready to merge: 0 Critical / 0 Important; 5 minors deferred (iOS launch screen white, `CFBundleLocalizations`, duplicated test fake, machine path in plan, task-file spec refs) |

**Known failures / outstanding:** iOS build + runtime not verified (needs a Mac; ZOD-FND-004's task file includes no macOS runner). Native x86_64 Android not exercised.

ZOD-TST-011, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| AC1: every Appendix B row individually asserted | `fvm dart run melos exec --scope=gann_core -- dart test test/accuracy` | 6 row tests, each asserting cells (placed, counted geometrically), angle per cell, blue/yellow/gray/unhighlighted, side, last number |
| AC2: 9×9 total as its own named test | same | `'9×9 square (rings 1–4): 16 blue, 16 yellow, 16 gray'`, center unhighlighted |
| T-GAN-2 beyond the table | same | Rings 7–30: 4 / 4 / 8 gray in even rings, 0 in odd |
| Mutation proof | ad-hoc mutants on `highlight_classification.dart`, each confirmed applied, restored, `git diff --exit-code` clean | H1 axis rule −8, H2 diagonal rule −8, H3 gray `4i` −3 (rings 2 and 6 coincide), H4 gray removed −5, H5 diagonal before axis −8, H6 gray before diagonal −8, H7 center highlighted −1 (of 8) — exactly as planned |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 |
| Code review | Fresh reviewer, whole branch | Ready to merge: 0 Critical / 0 Important. Comment fixes applied; its j-for-i probe survives T-GAN-2 by design (counts are rotation-invariant) and is caught by T-GAN-3, now documented in the suite header. 1 deferred |

**Deferred review minor (TST-011):** compute the 2…225 placed-count loop once instead of in each row test.

ZOD-TST-010, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| AC1: T-GAN-1 against explicit (x, y) for the first ~40 cells | `fvm dart run melos exec --scope=gann_core -- dart test test/accuracy` | All 169 cells of the 13×13 design grid; 2 at (−1, 0); unit steps and clockwise cross product over 61×61 (3690 same-ring pairs); ring entry/exit corners k = 1…30; inverse on the grid and round-trip over 61×61 |
| AC2: T-GAN-3 every Appendix C angle, positive and negative | same | 8 rows × 30 ray cells: angle literal, category, `isNot` the other two; "only" (geometric) over 61×61; 48 design literals; angles in [0, 360) |
| Mutation proof | ad-hoc mutants on `spiral.dart` / `highlight_classification.dart`, restored, `git diff --exit-code` clean | S1 mirrored x −10, S2 mirrored y −9, S3 no flip −11, S4 rotation −11, S5 moved cell −4, S6 i off by one −10, S7 j off by one −7, S8 segment −4, S9 remainder −1, C1 axis rule −6, C2 priority −6, C3 mirrored angle ("270 above") −7, C4 diagonal rule −1 (of 64) |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 |
| Code review | Fresh reviewer, whole branch | Ready to merge: 0 Critical / 0 Important. Its own probes beyond the 13×13 grid (mirror, mirrored angle, moved cell, outer-ring highlight) were all caught. 2 minors promoted (inverse round-trip proven by a ring-20 probe; consistency-check comment), 1 deferred |

**Deferred review minor (TST-010):** style consistency between the two suites (`_abs` vs `.abs()`, a shared geometric-ring helper).

ZOD-TST-013, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM; machine zone +02:00):

| Check | Command | Result |
|---|---|---|
| AC: single- and double-digit day/month (e.g. `4.1.24`, `14.11.24`) | `fvm dart run melos exec --scope=gann_core -- dart test test/accuracy` | Literals `4.1.24`, `14.11.24`, `4.11.24`, `14.1.24`; parse-back over all 731 dates of 2024/2026 at both ends of the day |
| T-FMT-1: two-digit year, no leading zero, period separator | same | `1.1.00`, `5.1.05`, `9.9.09`, `1.3.00`; years 1900–2100 (201); separator regex |
| Mutation proof | ad-hoc mutants on `cell_format.dart`, restored, `git diff --exit-code` clean | F1 padded day −12, F2 padded month −13, F3 4-digit year −18, F4 unpadded year −6, F5 swapped −13, F6 `/` −18, F7 century −18, F8 `toLocal()` −2 (all as planned) |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 |
| Code review | Fresh reviewer, whole branch | Ready to merge: 0 Critical / 0 Important. 3 minors promoted and fixed (per-time-of-day counts proven by dropping the 23:59 input → −2; value-comparison self-check; UTC-machine note) |

ZOD-TST-012, final run on 2026-11-12 (Flutter 3.50.0 / Dart 3.14.0 via FVM):

| Check | Command | Result |
|---|---|---|
| AC1: DST case — one-hour jump in date-and-time mode, dates mode unaffected | `fvm dart run melos exec --scope=gann_core -- dart test test/accuracy` | Israel and New York 2026: 05:00 / 03:00 literals; exactly one displayed jump in 169 cells; 1-hour steps show 01:00 twice / skip 02:00 (R-4); dates mode and date-and-time instants correct for every cell of 61×61 squares |
| AC2: leap year, Feb 29 without off-by-one | same | 2024/2000 include Feb 29, 2026/2100 don't; full chains 2023–2034 and 2096–2106; date-and-time and today across Feb 29, incl. 2100/2000 |
| T-GAN-4: anchor cell and today exact | same | Anchor date/instant literals (incl. 30.10 23:30 −04:00); today literals at local midnight and block edges (to the microsecond), travel, 30-min sweeps at all four transitions |
| Mutation proof | ad-hoc mutants on `cell_values.dart`, restored, `git diff --exit-code` clean | M1 −12, M2 −6, M3 −4, M4 −5, M5 −3, M6 −3, M7 −2, M8 −14, M9 −1 (of 27) |
| Workspace | `fvm dart run melos run lint` / `… run test` | Exit 0 |
| Code review | Fresh reviewer, whole branch | With fixes: 0 Critical, 1 Important (date-and-time only 169 of 3,721 cells) fixed; 3 minors promoted. Each proven by a probe mutant the old suite missed. 1 deferred |

**Deferred review minor (TST-012):** cap `_chainMismatches` output when many cells are wrong.

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

- **Current task branch:** `task/ZOD-UI-001-color-token-values` (from `main` @ `ae666da`)
- **Relevant commits:** FND-001 → `0303645` (PR #2), FND-002 → `331c7dc` (PR #3), FND-012 → `13ea8e6` (PR #4), EPH-001 → `a21e4ed` (PR #5), plan-reviewer → `83ee377` (PR #6), TST-002 → `a86e284` (PR #7), GAN-001 → `ef1ea48` (PR #8), GAN-002 → `1284889` (PR #9), GAN-003 → `8655a9d` (PR #10), TST-012 → `718edf1` (PR #11), TST-013 → `c5e442f` (PR #12), TST-010 → `3a447d5` (PR #13), TST-011 → `30ea9eb` (PR #14), FND-005 → `e4a8859` (PR #15), FND-013 → `ae666da` (PR #16), all merged. UI-001 branch: plan `ce39ba5`; `f5668e8` (values), Task 2 oracles, `3bf3533` (harness), close-out
- **Pull request:** PRs #2–#16 merged. UI-001: none yet
- **Unmerged task branches others depend on:** none
- **Uncommitted changes:** none
- **Preserve:** `.idea/` and `.qodo/` are local IDE folders. Never stage them. `.fvm/` is a local symlink (gitignored).
