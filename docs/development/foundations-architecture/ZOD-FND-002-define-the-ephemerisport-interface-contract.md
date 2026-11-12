# ZOD-FND-002 - Define the `EphemerisPort` interface contract

## Metadata

- **ID:** ZOD-FND-002
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done
- **Scope:** MVP

## Description

Define the single abstract interface that every position source (Swiss Ephemeris, astronomy-engine) must implement, so a source can be swapped by dependency injection without touching the rest of the app (ARCH-4).

## Implementation Details

- Define `Body` enum: `sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto, node` (exact data-model enum from the spec).
- Define a method returning, for a given `Body` and UTC `DateTime`: tropical ecliptic longitude (0–360, excluding 360) and the instantaneous longitude speed (degrees/day), from which retrograde is derived (negative speed).
- Define error/result types for "date outside the data files' covered range" (R-2) so callers can show a clear message instead of a silently wrong result.
- Document that implementations must return **apparent, geocentric, ecliptic-of-date** positions with **no extra precession correction** (NFR-A1) — this is the contract every adapter must honor.
- Declare a separate method for the mean ascending node and document its formula as part of the interface contract: `Ω = 125.04452 − 1934.136261·T` degrees, T = Julian centuries since 2000-01-01 12:00 UTC, normalized to [0, 360), with the constant daily speed `−1934.136261 / 36525` degrees/day. **Declaration and contract documentation only.** The formula is implemented in [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md) and verified by T-EPH-2 in [ZOD-TST-002](../testing-qa/ZOD-TST-002-author-the-mean-node-formula-exactness-test-t-eph-2.md).

## Design Reference

No direct design reference applies — this is a pure-Dart interface in `packages/astro_core`.

## Acceptance Criteria

- [x] Interface compiles with zero Flutter/UI dependencies.
- [x] The mean-node method signature is declared, and its formula contract (coefficients, T definition, [0, 360) normalization, constant daily speed) is documented on the interface. Implementation and T-EPH-2 coverage are tracked by ZOD-EPH-001 and ZOD-TST-002.
- [x] Interface exposes both apparent-position output and speed, sufficient for retrograde and crossing-solver consumers.
- [x] Interface documents the "out of data-file range" failure mode.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace

## Specification References

- "Planet position"
- "Architecture rules" ARCH-4
- NFR-A1
- R-2

## Notes

- 2026-11-12 (product-owner decision): the node acceptance criterion originally read "Node formula is implemented as specified and covered by T-EPH-2 (ZOD-TST-002)". That created a cycle (FND-002 → TST-002 → EPH-001 → FND-002), so it was changed to cover the declaration and contract only. This task does not depend on EPH-001 or TST-002 to be marked Done.
- This task defines the `Body` enum. [ZOD-FND-012](ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) adds its JSON serialization.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
