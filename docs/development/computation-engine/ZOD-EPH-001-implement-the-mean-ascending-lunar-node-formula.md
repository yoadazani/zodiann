# ZOD-EPH-001 - Implement the mean ascending lunar node formula

## Metadata

- **ID:** ZOD-EPH-001
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the closed-form mean node longitude, the one body position in the app that is not ephemeris-sourced.

## Implementation Details

- Implement the mean-node method declared on `EphemerisPort` in [ZOD-FND-002](../foundations-architecture/ZOD-FND-002-define-the-ephemerisport-interface-contract.md), following the contract documented there. Implement it **once**, in `packages/astro_core/lib/src/ephemeris/mean_node.dart`, exported from `astro_core`:
  - `EclipticPosition meanAscendingNodeAt(DateTime utc)`: the pure formula function.
  - `mixin MeanAscendingNodeFormula implements EphemerisPort`: provides `meanAscendingNode(utc) => meanAscendingNodeAt(utc)`.
  - Every adapter (ZOD-EPH-002/003/004) declares `… with MeanAscendingNodeFormula implements EphemerisPort` and answers `position(Body.node, utc)` with `EphemerisSuccess(meanAscendingNode(utc))`. No adapter re-implements the formula.
- `Ω = 125.04452 − 1934.136261·T` degrees, where `T` = Julian centuries since 2000-01-01 12:00 UTC.
- Normalize result into [0, 360).
- Return the constant daily speed `−1934.136261 / 36525` degrees/day alongside the longitude.
- Retrograde for the node is **defined as constant** (always shown "℞ Mean"), not derived from a speed sign — implement this as a fixed flag, not a computed one.
- Document the known ~0.01° deviation from the full formula over 200 years around 2000.

## Design Reference

No direct design reference applies — pure computation.

## Acceptance Criteria

- [ ] Output matches the formula to floating-point precision on a spot-checked date.
- [ ] T-EPH-2 passes (exact formula match within the defined accuracy range).
- [ ] The node is never reported as "direct" — always the constant mean-℞ state.

## Dependencies

- [ZOD-FND-002](../foundations-architecture/ZOD-FND-002-define-the-ephemerisport-interface-contract.md) — Define the `EphemerisPort` interface contract
- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes

## Specification References

- "Planet position" (node formula)
- T-EPH-2

## Notes

- 2026-11-12 (product-owner decision): this task owns the node formula implementation, including [0, 360) normalization and the constant daily speed. ZOD-FND-002 only declares the method and documents the contract. T-EPH-2 coverage is ZOD-TST-002.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
