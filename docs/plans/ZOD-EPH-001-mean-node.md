# ZOD-EPH-001 — Mean Ascending Lunar Node Formula Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Revision 2, approved and implemented (2026-11-12) · **Branch:** `task/ZOD-EPH-001-mean-node` · **Written:** 2026-11-12

## Revision 2 — clarifications

| # | Review point | Resolution |
|---|---|---|
| 1 | Adapter `coveredRange` vs `Body.node` | **Intended contract:** `Body.node` bypasses `coveredRange`. The node is an analytical formula, independent of the source's data files. This is already in the FND-002 `EphemerisPort.position` doc ("for any `utc`… not bounded by `coveredRange`"). EPH-001 restates it on the mixin. The test adapter's node branch runs **before** its range check, and the 1900 test stays because it pins this behaviour. Adapters (EPH-002/003/004) must order their branches the same way; the mixin doc says so. |
| 2 | Public formula constants | Kept as package API: a single source for the coefficients in production. **ZOD-TST-002 must keep its own independent reference coefficients and never derive expected values from these constants.** Its mutation proof alters each production constant and must see the independent test fail. This is already in the TST-002 task file. |
| 3 | Accuracy wording | Every doc comment (`mean_node.dart` and the existing `meanAscendingNode` doc in `ephemeris_port.dart`) describes "< 0.01° from the full formula over 200 years around 2000" as the **spec's expected accuracy bound, pending independent verification by ZOD-TST-002**, not as a verified result. |

**Goal:** Implement the mean ascending node formula **once** in `astro_core`, as a pure function plus a mixin that every `EphemerisPort` adapter reuses, and add the fixed "mean ℞" flag for the node.

**Architecture:** Three small public pieces in `packages/astro_core/lib/src/ephemeris/`:
- **`normalizeDegrees`:** a reusable angle normalizer that handles Dart's `x % 360 == 360.0` edge. Adapters (EPH-002/004) need the same normalization.
- **`meanAscendingNodeAt`:** the single formula implementation.
- **`MeanAscendingNodeFormula`:** a mixin that provides `EphemerisPort.meanAscendingNode`.

The node's constant retrograde state is a fixed flag on `Body`, which EPH-005 will read rather than derive from speed.

**Tech Stack:** Dart 3.14, no new dependencies.

**Spec:**
- `docs/development/computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md` (amended 2026-11-12)
- `EphemerisPort.meanAscendingNode` contract (`packages/astro_core/lib/src/ephemeris/ephemeris_port.dart`)
- `assets/zodiann-specification.md` → "Planet position" (node formula, "mean ℞")

## Global Constraints

- Pure Dart in `astro_core` (ARCH-2). No new dependencies. Follow `docs/PROGRESS.md` → Architecture Conventions.
- The formula exactly as specified: `Ω = 125.04452 − 1934.136261·T` degrees.
  - `T = (JD − 2451545.0) / 36525`.
  - `JD` is the Julian Day of the **UTC instant**, with **no ΔT/TT conversion**.
  - The result is normalized to [0, 360).
  - Speed is the constant `−1934.136261 / 36525` = `−0.0529537648459959` °/day.
- The formula exists **once**. The mixin is declared `mixin MeanAscendingNodeFormula implements EphemerisPort`, never with `on`.
- Non-UTC input → `ArgumentError` (FND-002 contract).
- Out of scope:
  - T-EPH-2 and the Meeus 0.01° bound (→ ZOD-TST-002).
  - Retrograde detection and formatting for other bodies (→ ZOD-EPH-005).
  - Adapters (→ EPH-002/003/004).
  - The true node (→ EXT-002).

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| Normalizer | Public `double normalizeDegrees(double degrees)` in `angles.dart`, exported. Maps `x % 360 == 360.0` → `0.0`; `ArgumentError` for non-finite input | The required "negative-angle normalization incl. the 360.0 edge" test can't be reached through the formula's public API on real dates, so the normalizer must be testable directly. Adapters need the same safe normalization |
| T computation | `utc.difference(DateTime.utc(2000, 1, 1, 12)).inMicroseconds / (36525 * Duration.microsecondsPerDay)` | Equals `(JD_UTC − 2451545) / 36525` exactly, at microsecond resolution, without floating-point JD offsets |
| "Fixed flag" for mean ℞ | `bool get hasConstantMeanRetrograde => this == Body.node;` on `Body` | The task asks for a fixed flag rather than a computed one. EPH-005 reads it to show "℞ Mean" for the node instead of deriving it from speed. It lives on `Body` because it's a property of the body, not of any particular source |
| Mixin scope | The mixin provides only `meanAscendingNode`. Adapters still write their one-line `position(Body.node, …)` branch | That's what the EPH-001 task file and the FND-002 contract specify. A mixin can't intercept `position` without becoming a base class |

## File Structure

```
packages/astro_core/lib/
  astro_core.dart                         + export angles.dart, mean_node.dart
  src/ephemeris/angles.dart               normalizeDegrees
  src/ephemeris/mean_node.dart            meanAscendingNodeAt + mixin MeanAscendingNodeFormula
  src/ephemeris/body.dart                 + hasConstantMeanRetrograde
packages/astro_core/test/ephemeris/
  angles_test.dart
  mean_node_test.dart
  body_test.dart                          + flag test
```

## Reference values (hand-checked, for the tests)

| UTC instant | T | raw Ω (°) | normalized Ω (°) |
|---|---|---|---|
| 2000-01-01 12:00 | 0 | 125.04452 | **125.04452** |
| 1900-01-01 00:00 | −36524.5 / 36525 = −0.9999863107460644 | 2059.1543041175773 | **259.15430411757734** |
| 2100-01-01 00:00 | +0.9999863107460644 | −1809.0652641175773 | **350.93473588242273** |
| 2026-11-12 00:00 | 0.2686242299794661 | −394.51134378648874 | **325.48865621351126** |

Hand-check for 1900: 1934.136261 × 0.99998631 ≈ 1934.1098; adding 125.0445 gives 2059.1543; subtracting 5 × 360 leaves 259.1543. The 2100 and 2026 rows exercise negative raw values.

## Review Focus

1. **The `x % 360 == 360.0` edge:** `normalizeDegrees(-1e-15)` must return `0.0`, not `360.0`, which `EclipticPosition` would reject with an exception. Pinned in Task 1.
2. **Negative raw Ω** (every date after about 2006) must normalize correctly, not just stay non-negative. Pinned in Task 2 (2026 and 2100).
3. **Local-time input** must throw, never be silently treated as UTC. Pinned in Task 2.
4. **A ΔT/TT conversion added "for accuracy"** would contradict the contract. The epoch test (exactly 125.04452 at 12:00 UTC) and the dated reference values pin `T` to UTC. Pinned in Task 2.
5. **The node reported as direct:** speed is negative on every date, and the fixed flag is true only for the node. Pinned in Task 2 (a sweep from 1800 to 2400) and Task 1 (the flag).
6. **An adapter checking `coveredRange` before the node branch** would wrongly fail the node outside the data range. Pinned in Task 2: the node succeeds at 1900 while the Moon is out of range.

---

### Task 1: `normalizeDegrees` and the fixed mean-℞ flag (TDD)

**Files:** Create `astro_core/lib/src/ephemeris/angles.dart`; modify `body.dart` and `astro_core.dart`; test `astro_core/test/ephemeris/angles_test.dart` and `body_test.dart`.

**Interfaces (produced):**
- `double normalizeDegrees(double degrees)` returns a value in [0, 360), with `-0.0` → `0.0`. It throws `ArgumentError` for NaN or ±∞.
- `extension`-free getter on the enum: `bool get hasConstantMeanRetrograde` (true only for `Body.node`).

- [ ] **Step 1: Write the failing tests**
  - `angles_test.dart`, `group('normalizeDegrees')`:
    - `'maps -1e-15 to 0.0 (the x % 360 == 360.0 edge)'`: expect `0.0`, and `isNegative` is false.
    - `'normalizes negatives'`: `-10` → `350.0`, `-370` → `350.0`, `-394.51134378648874` → `325.48865621351126` (within `1e-9`).
    - `'normalizes values at or above 360'`: `360` → `0.0`, `725` → `5.0`, `2059.1543041175773` → `259.15430411757734` (within `1e-9`).
    - `'keeps values already in range'`: `0` → `0.0`, `359.5` → `359.5`, `-0.0` → `0.0` (not negative).
    - `'rejects non-finite input'`: `nan`, `infinity`, `negativeInfinity` → `throwsArgumentError`.
  - `body_test.dart`: `'only the node has the constant mean-retrograde flag'`, i.e. `Body.values.where((b) => b.hasConstantMeanRetrograde)` equals `[Body.node]`.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=astro_core -- dart test test/ephemeris`. Expected: compilation FAIL (`normalizeDegrees` and `hasConstantMeanRetrograde` undefined).
- [ ] **Step 3:** Implement. `normalizeDegrees`: `final r = degrees % 360; return (r == 360 || r == 0) ? 0.0 : r;` plus the finiteness check. The getter has a doc comment saying it's the fixed "℞ Mean" state (spec "Planet position"), consumed by EPH-005 instead of the speed sign.
- [ ] **Step 4:** Same command. Expected: PASS.
- [ ] **Step 5:** Commit `feat(ZOD-EPH-001): add normalizeDegrees and the node's fixed mean-retrograde flag`.

### Task 2: `meanAscendingNodeAt` and `MeanAscendingNodeFormula` (TDD)

**Files:** Create `astro_core/lib/src/ephemeris/mean_node.dart`; modify `astro_core.dart`; test `astro_core/test/ephemeris/mean_node_test.dart`.

**Interfaces:**
- Consumes `normalizeDegrees` (Task 1), `EclipticPosition`, and `EphemerisPort` (FND-002).
- Produces:
  - `EclipticPosition meanAscendingNodeAt(DateTime utc)`
  - `mixin MeanAscendingNodeFormula implements EphemerisPort { @override EclipticPosition meanAscendingNode(DateTime utc) => meanAscendingNodeAt(utc); }`
  - `const double meanNodeEpochLongitude = 125.04452;`
  - `const double meanNodeDegreesPerCentury = 1934.136261;`
  - `const double meanNodeSpeedDegreesPerDay = -meanNodeDegreesPerCentury / 36525;`

  The constants are public package API and the single production source of the coefficients, so TST-002's mutation proof has one obvious place to alter each one. TST-002 must **not** use them for its expected values (see Revision 2, point 2).
  - The mixin's doc comment states that `Body.node` is answered by the formula for **any** UTC instant, regardless of `coveredRange`. It tells implementers to put the node branch in `position` **before** the covered-range check.

- [ ] **Step 1: Write the failing tests** (`group('meanAscendingNodeAt')`, tolerance `1e-9` degrees unless stated)
  - `'is exactly 125.04452 at the reference epoch'`: `meanAscendingNodeAt(DateTime.utc(2000, 1, 1, 12)).longitude == 125.04452` (exact equality).
  - `'matches hand-computed values before and after the epoch'`: 1900-01-01 → `259.15430411757734`, 2100-01-01 → `350.93473588242273`, 2026-11-12 → `325.48865621351126`.
  - `'normalizes negative raw values into [0, 360)'`: for 2026-11-12 and 2100-01-01 (raw −394.5 and −1809.1), the longitude is in [0, 360) and equals the values above.
  - `'has the constant negative speed −1934.136261 / 36525 °/day on every date'`: exact equality to `-1934.136261 / 36525` for 1800, 2000-01-01 12:00 and 2400.
  - `'uses the spec coefficients'`:
    - `meanNodeEpochLongitude == 125.04452`, `meanNodeDegreesPerCentury == 1934.136261`.
    - One day after the epoch, the longitude equals `normalizeDegrees(125.04452 - 1934.136261 / 36525)`.
  - `'is never reported as direct'`: for every year from 1800 to 2400, `speed < 0`, and `Body.node.hasConstantMeanRetrograde` is true.
  - `'rejects non-UTC input'`: `meanAscendingNodeAt(DateTime(2026, 11, 12))` → `throwsArgumentError`.

  `group('MeanAscendingNodeFormula')`:
  - `'an adapter mixing it in returns the shared formula'`. The test file declares `final class _Adapter with MeanAscendingNodeFormula implements EphemerisPort`, with `coveredRange` 2000–2100. Its `position` checks `body == Body.node` **first** and returns `EphemerisSuccess(meanAscendingNode(utc))`. Only after that does it apply the range check (`OutOfCoveredRange`), and otherwise it returns a fixed value. Expect `adapter.meanAscendingNode(t) == meanAscendingNodeAt(t)`.
  - `'node bypasses coveredRange because the formula is source-independent'`:
    - `adapter.position(Body.node, DateTime.utc(1900))`, which is outside 2000–2100, is `EphemerisSuccess` with `meanAscendingNodeAt(DateTime.utc(1900))`.
    - In the same test, `adapter.position(Body.moon, DateTime.utc(1900))` is `OutOfCoveredRange`, to show the bypass applies only to the node.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=astro_core -- dart test test/ephemeris/mean_node_test.dart`. Expected: compilation FAIL.
- [ ] **Step 3:** Implement per Interfaces.
  - Check `utc.isUtc` (else `ArgumentError`).
  - `T` per the decision table.
  - `EclipticPosition(longitude: normalizeDegrees(meanNodeEpochLongitude - meanNodeDegreesPerCentury * t), speed: meanNodeSpeedDegreesPerDay)`.
  - Doc comments cover:
    - the formula, and T from UTC with no ΔT
    - a formula-based point, not an apparent position
    - **accuracy:** "the spec states an expected deviation of less than 0.01° from the full formula over 200 years around 2000; this bound is pending independent verification by T-EPH-2 (ZOD-TST-002)"
  - In `ephemeris_port.dart`, reword the existing `meanAscendingNode` bullet ("deviates … by less than 0.01°") the same way, as an expected bound pending ZOD-TST-002. The symbol names it already references stay.
- [ ] **Step 4:** Same command. Expected: PASS. Then run `fvm dart run melos run lint` and `fvm dart run melos run test`; both exit 0.
- [ ] **Step 5:** Commit `feat(ZOD-EPH-001): implement the mean ascending node formula and shared mixin`.

### Task 3: Close out (zodiann-development workflow)

- [ ] **Step 1:** Whole-branch review (`requesting-code-review`), then resolve any important findings.
- [ ] **Step 2:** Re-run lint and test (`verification-before-completion`).
- [ ] **Step 3:** Set `Status: Done` in the task file and `TASKS.md`, tick the acceptance criteria, and update `docs/PROGRESS.md` (conventions: `normalizeDegrees` for all longitude normalization; next task).
- [ ] **Step 4:** Commit, push, open a PR, then record the PR link.

## Acceptance Criteria → Evidence

| AC (as amended 2026-11-12) | Proven by |
|---|---|
| Output matches the formula to floating-point precision on a spot-checked date | Epoch exact-equality test; 1900 / 2100 / 2026 reference values (1e-9°) |
| Production formula implemented and covered by its own unit tests; T-EPH-2 tracked by TST-002 | Task 1–2 suites covering all six required test areas (epoch, before/after, normalization incl. the 360.0 edge, constant negative speed, non-UTC rejection, coefficients) |
| The node is never reported as "direct" | Speed < 0 for 1800–2400, and the `hasConstantMeanRetrograde` flag (true only for the node) |

## Risks

- **`hasConstantMeanRetrograde` is consumed later.** EPH-005 must use it. Its task file already defers the node's retrograde state to EPH-001, and the flag's doc comment names EPH-005.
- **Mutation proof lives in TST-002.** The public coefficient constants give it one place to alter each value.
