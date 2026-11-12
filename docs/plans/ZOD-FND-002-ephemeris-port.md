# ZOD-FND-002 — `EphemerisPort` Interface Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Awaiting approval · **Branch:** `task/ZOD-FND-002-ephemeris-port` · **Written:** 2026-11-12

**Goal:** Define, in pure Dart, the single contract that every position source implements, so sources can be swapped by one injection (ARCH-4) and no caller can silently use an out-of-range result (R-2).

**Architecture:** A small set of immutable value types plus one `abstract interface class` in `packages/astro_core/lib/src/ephemeris/`. Out-of-range is a **sealed result type**, not an exception, so Dart's exhaustive `switch` forces every caller to handle it. The interface is **synchronous**: adapters wrap synchronous FFI calls, and the crossing solver calls it thousands of times. Heavy callers move off the UI thread with `Isolate.run` (ARCH-1), and that's the caller's job, not the port's. The mean-node method is declared and its formula documented, **not implemented** (product-owner decision, see the task file's Notes).

**Tech Stack:** Dart 3.14 (sealed classes, `final`/`interface` class modifiers, exhaustive switch). No new dependencies.

**Spec:**
- `docs/development/foundations-architecture/ZOD-FND-002-define-the-ephemerisport-interface-contract.md` (updated 2026-11-12)
- `assets/zodiann-specification.md`: "Planet position", "Computation settings that must be fixed and documented", CRS-A1, the `Body` enum in "Data model and user settings", NFR-A1, R-2, ARCH-1/2/4

## Global Constraints

- Pure Dart in `packages/astro_core` (ARCH-2). No Flutter, no `dart:ui`. The workspace ARCH-2 guard must stay green.
- Follow `docs/PROGRESS.md` → Architecture Conventions. Run Melos as `fvm dart run melos …`.
- No new dependencies.
- `Body` is exactly the spec's enum, in this order: `sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto, node`.
- Longitude is degrees in **[0, 360)**: 360 is never valid (T-CRS-3 boundary). Speed is **degrees per day**.
- Out of scope:
  - Mean-node formula implementation (→ ZOD-EPH-001) and T-EPH-2 (→ ZOD-TST-002).
  - Retrograde detection and position formatting (→ ZOD-EPH-005).
  - JSON for `Body` (→ ZOD-FND-012).
  - Any adapter (→ ZOD-EPH-002/003/004).
  - DI wiring (→ ZOD-FND-005).
  - ΔT-forecast warning (→ ZOD-EPH-002 / ZOD-NFR-017). It can be added later as an optional field on `EphemerisSuccess` without breaking adapters.

## File Structure

```
packages/astro_core/lib/
  astro_core.dart                        exports the five files below
  src/ephemeris/
    body.dart                            enum Body
    ecliptic_position.dart               EclipticPosition value type (validated)
    utc_range.dart                       UtcRange value type (validated, inclusive)
    ephemeris_result.dart                sealed EphemerisResult / EphemerisSuccess / EphemerisFailure / OutOfCoveredRange
    ephemeris_port.dart                  abstract interface class EphemerisPort + full contract docs
packages/astro_core/test/ephemeris/
  body_test.dart
  ecliptic_position_test.dart
  utc_range_test.dart
  ephemeris_port_contract_test.dart      fake adapter proving the contract is implementable and consumable
```

## Review Focus

1. **Longitude at exactly 360, negative, `NaN` or ±∞** must be rejected at construction. **`-0.0`** is stored as `0.0`. Pinned in Task 1 (`EclipticPosition`).
2. **A local-time `DateTime`** passed where UTC is required must throw `ArgumentError`, not be silently treated as UTC. The spec converts local → UTC before computing. Pinned in Task 1 (`UtcRange`) and documented on every port method.
3. **An out-of-range result being ignored.** It must be impossible to read a position without first handling `OutOfCoveredRange`. Pinned in Task 2 by an exhaustive `switch` with no default branch, so it fails to compile if a case is missing.
4. **`UtcRange` boundaries.** The first and last covered instants are *inside*. A range whose end is before its start is rejected. A single-instant range (`start == end`) is allowed. Pinned in Task 1.
5. **Speed sign.** A negative speed must be representable, because retrograde depends on it. A `NaN` speed is rejected. Pinned in Task 1, and Task 2 shows retrograde is derivable from the result.

---

### Task 1: Value types — `Body`, `EclipticPosition`, `UtcRange` (TDD)

**Files:**
- Create: `packages/astro_core/lib/src/ephemeris/{body,ecliptic_position,utc_range}.dart`
- Modify: `packages/astro_core/lib/astro_core.dart` (add exports)
- Test: `packages/astro_core/test/ephemeris/{body,ecliptic_position,utc_range}_test.dart`

**Interfaces (produced, used by Task 2 and by EPH-001/002/004/005, CRS-*, FND-012):**
- `enum Body { sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto, node }`
- `final class EclipticPosition`: `EclipticPosition({required double longitude, required double speed})`, fields `final double longitude` (degrees, [0, 360)) and `final double speed` (degrees/day). Throws `ArgumentError` if longitude isn't finite or is outside [0, 360), or if speed isn't finite. `-0.0` longitude is stored as `0.0`. Value equality, `hashCode`, `toString`.
- `final class UtcRange`: `UtcRange(DateTime start, DateTime end)`, fields `start`, `end`. Throws `ArgumentError` if either isn't `isUtc` or if `end.isBefore(start)`. `bool contains(DateTime utc)` is inclusive at both ends and throws `ArgumentError` if `!utc.isUtc`. Value equality, `hashCode`, `toString`.

- [ ] **Step 1: Write the failing tests**

`body_test.dart`:
- `'Body has exactly the spec values in spec order'`: `expect(Body.values.map((b) => b.name), ['sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune', 'pluto', 'node'])`.

`ecliptic_position_test.dart`, `group('EclipticPosition')`:
- `'accepts the range boundaries 0 and just below 360'`: longitudes `0.0` and `359.99999999` construct; fields read back unchanged.
- `'rejects 360 and above'`: `360.0` and `360.5` → `throwsArgumentError`.
- `'rejects negative longitudes'`: `-0.0001` → `throwsArgumentError`.
- `'stores -0.0 as 0.0'`: `EclipticPosition(longitude: -0.0, speed: 1).longitude.isNegative` is `false`.
- `'rejects non-finite longitude'`: `double.nan`, `double.infinity` → `throwsArgumentError`.
- `'accepts negative speed (retrograde) and rejects non-finite speed'`: speed `-0.5` constructs; `double.nan` and `double.negativeInfinity` → `throwsArgumentError`.
- `'has value equality'`: equal fields → `==` and equal `hashCode`; a different speed → not equal.

`utc_range_test.dart`, `group('UtcRange')`, with `final a = DateTime.utc(1800, 1, 1)` and `final b = DateTime.utc(2400, 1, 1)`:
- `'contains its start and end (inclusive)'`: `UtcRange(a, b).contains(a)` and `.contains(b)` are both `true`.
- `'excludes instants outside'`: one microsecond before `a` and one after `b` → `false`.
- `'allows a single-instant range'`: `UtcRange(a, a).contains(a)` is `true`.
- `'rejects end before start'`: `UtcRange(b, a)` → `throwsArgumentError`.
- `'rejects non-UTC bounds'`: `UtcRange(DateTime(1800), b)` and `UtcRange(a, DateTime(2400))` → `throwsArgumentError`.
- `'contains rejects a non-UTC instant'`: `UtcRange(a, b).contains(DateTime(2000))` → `throwsArgumentError`.
- `'has value equality'`.

- [ ] **Step 2: Run the tests and verify they fail**

Run: `fvm dart run melos exec --scope=astro_core "dart test test/ephemeris"`
Expected: compilation FAIL (`Body`, `EclipticPosition` and `UtcRange` aren't defined).

- [ ] **Step 3: Implement the three types per the Interfaces block, and export them from `astro_core.dart`**

Each type carries a doc comment that cites its spec rule ("Planet position" range, R-2 for `UtcRange`).

- [ ] **Step 4: Run the tests and verify they pass**

Same command. Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/astro_core
git commit -m "feat(ZOD-FND-002): add Body, EclipticPosition and UtcRange value types"
```

### Task 2: Result types and the `EphemerisPort` contract (TDD)

**Files:**
- Create: `packages/astro_core/lib/src/ephemeris/{ephemeris_result,ephemeris_port}.dart`
- Modify: `packages/astro_core/lib/astro_core.dart`
- Test: `packages/astro_core/test/ephemeris/ephemeris_port_contract_test.dart`

**Interfaces:**
- Consumes: Task 1 types.
- Produces:
  - `sealed class EphemerisResult`
  - `final class EphemerisSuccess extends EphemerisResult { EphemerisSuccess(this.position); final EclipticPosition position; }`
  - `sealed class EphemerisFailure extends EphemerisResult`, sealed so future failure kinds stay exhaustively handled.
  - `final class OutOfCoveredRange extends EphemerisFailure { OutOfCoveredRange({required this.requested, required this.covered}); final DateTime requested; final UtcRange covered; }`
  - Value equality and `toString` on the two final classes.
  - `abstract interface class EphemerisPort` with:
    - `UtcRange get coveredRange;`
    - `EphemerisResult position(Body body, DateTime utc);`
    - `EclipticPosition meanAscendingNode(DateTime utc);`

**Contract to document on `EphemerisPort`** (doc comments; this text *is* the deliverable for AC 3 and 4 and the node AC):
- Class-level, per "Planet position", "Computation settings" and NFR-A1: positions are **apparent** (light time, aberration, light deflection, nutation), **geocentric**, on the **true ecliptic and equinox of date** (tropical), and implementations **must not apply any extra precession correction** (NFR-A1, mandatory regression test, ZOD-TST-004). Swapping implementations is a single injection (ARCH-4). Calls are synchronous; callers run long scans in an isolate (ARCH-1).
- `coveredRange`: the inclusive UTC range in which the source guarantees its stated accuracy. The UI uses it to limit date input (R-2).
- `position`:
  - `utc` must be UTC (`isUtc`), otherwise `ArgumentError`. Local time is converted by the caller.
  - Returns `EphemerisSuccess` with longitude in [0, 360) and speed in degrees/day **taken directly from the source, never by finite-differencing two positions** (CRS-A1). Retrograde is `speed < 0`, except the node (ZOD-EPH-005).
  - For any body other than `Body.node`, a `utc` outside `coveredRange` returns `OutOfCoveredRange` and **never** an approximate position (R-2).
  - For `Body.node`, it returns `EphemerisSuccess(meanAscendingNode(utc))` for any `utc`, because the node is formula-based and not bounded by `coveredRange`.
- `meanAscendingNode`:
  - `utc` must be UTC, otherwise `ArgumentError`.
  - Formula contract: `Ω = 125.04452 − 1934.136261·T` degrees, `T = (JD_UT − 2451545.0) / 36525` (Julian centuries since 2000-01-01 12:00 UTC), normalized to [0, 360). Speed is the constant `−1934.136261 / 36525` degrees/day.
  - It's a linear approximation, within 0.01° of the full formula over 200 years around 2000.
  - Implemented by ZOD-EPH-001 and verified by T-EPH-2 (ZOD-TST-002). Not implemented in this task.

- [ ] **Step 1: Write the failing contract test**

In the test file, define `_FakePort implements EphemerisPort`: covered range 2000–2100 UTC; returns a fixed `EclipticPosition` per body, with Mars at speed `-0.3`; `meanAscendingNode` returns `EclipticPosition(longitude: 125.0, speed: -0.0529539)`. Also define the helper `String describe(EphemerisResult r) => switch (r) { EphemerisSuccess(:final position) => 'ok ${position.longitude}', OutOfCoveredRange(:final requested) => 'out $requested' };` with **no default branch**, so the test stops compiling if a result kind is added without being handled.

`group('EphemerisPort contract')`:
- `'can be implemented and injected as the interface type'`: `final EphemerisPort port = _FakePort();`, then `expect(port.position(Body.sun, DateTime.utc(2026, 11, 12)), isA<EphemerisSuccess>())`.
- `'exposes speed so retrograde is derivable'`: Mars result `(… as EphemerisSuccess).position.speed < 0` is `true`.
- `'reports out-of-range as a typed failure carrying the request and covered range'`: a request in 1900 gives `OutOfCoveredRange` with `requested == DateTime.utc(1900)` and `covered == port.coveredRange`.
- `'results are consumable by an exhaustive switch'`: `describe` of a success and of a failure returns `'ok …'` and `'out …'`.
- `'node goes through the declared mean-node method'`: `port.position(Body.node, DateTime.utc(1900))` is `EphemerisSuccess` whose position equals `port.meanAscendingNode(DateTime.utc(1900))`, even outside `coveredRange`.

The fake implements the documented contract. These tests prove the interface is implementable and consumable as designed. Behavioural conformance of real adapters belongs to EPH-002/004.

- [ ] **Step 2: Run the test and verify it fails**

Run: `fvm dart run melos exec --scope=astro_core "dart test test/ephemeris/ephemeris_port_contract_test.dart"`
Expected: compilation FAIL (`EphemerisPort`, `EphemerisResult` etc. aren't defined).

- [ ] **Step 3: Implement `ephemeris_result.dart` and `ephemeris_port.dart` per Interfaces, with the contract docs above. Export them from `astro_core.dart`.**

- [ ] **Step 4: Run the test and verify it passes**

Same command. Expected: PASS.

- [ ] **Step 5: Full workspace gates**

Run: `fvm dart run melos run lint` and `fvm dart run melos run test`.
Expected: both exit 0. The test run includes the ARCH-2 guard (still green: `astro_core` has no dependencies) and all `astro_core` tests.

- [ ] **Step 6: Commit**

```bash
git add packages/astro_core
git commit -m "feat(ZOD-FND-002): define EphemerisPort contract and sealed result types"
```

### Task 3: Close out (zodiann-development workflow)

- [ ] **Step 1:** Whole-branch review (`requesting-code-review`), then resolve any important findings.
- [ ] **Step 2:** Re-run `fvm dart run melos run lint` and `… run test` (`verification-before-completion`) and record the results.
- [ ] **Step 3:**
  - Set `Status: Done` in the FND-002 task file and its `TASKS.md` row, and tick its acceptance criteria.
  - Commit the task-file updates already made on this branch: FND-002 criterion and description, EPH-001 implementation notes, FND-012 `Body` note.
  - Update `docs/PROGRESS.md`.
- [ ] **Step 4:** Commit, push, open a PR into `main`, then record the PR link in a follow-up commit.

## Acceptance Criteria → Evidence

| AC (FND-002, as updated 2026-11-12) | Proven by |
|---|---|
| Interface compiles with zero Flutter/UI dependencies | Workspace ARCH-2 guard (`astro_core` closure + import scan) in `melos run test`; `melos run lint` |
| Mean-node method signature declared and formula contract documented | `EphemerisPort.meanAscendingNode` + its doc comment; node test in Task 2 |
| Exposes apparent position and speed, sufficient for retrograde and crossing-solver consumers | `EclipticPosition.longitude`/`speed`; Task 2 "speed so retrograde is derivable"; contract docs (CRS-A1) |
| Documents the "out of data-file range" failure mode | `OutOfCoveredRange` + `coveredRange` + `position` docs; Task 2 out-of-range and exhaustive-switch tests |

## Decisions to confirm

- **`Body` is defined here.** FND-012 adds its JSON. Task files were updated accordingly.
- **Sealed result instead of exceptions** for out-of-range. Exhaustiveness makes R-2's "never silently wrong" a compile-time guarantee.
- **Synchronous interface.** Isolates are the caller's concern (ARCH-1).
- **`position(Body.node, …)` delegates to `meanAscendingNode`** and is never out-of-range, so consumers can iterate all 11 bodies uniformly.
- **`UtcRange` is our own type**, because Flutter's `DateTimeRange` would break ARCH-2.

## Risks

- **Interface changes later.** Adapters (EPH-002/004) may need extra outputs, such as a ΔT-forecast flag. `EphemerisSuccess` can gain optional fields, and `EphemerisFailure` is sealed, so new failure kinds are compile-checked across consumers.
- **Coverage range isn't known yet.** The actual `coveredRange` values come from ZOD-FND-011. The contract doesn't hardcode any.
