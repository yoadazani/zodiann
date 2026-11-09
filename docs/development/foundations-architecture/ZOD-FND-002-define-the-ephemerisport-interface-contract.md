# ZOD-FND-002 - Define the `EphemerisPort` interface contract

## Metadata

- **ID:** ZOD-FND-002
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Define the single abstract interface that every position source (Swiss Ephemeris, astronomy-engine) must implement, so a source can be swapped by dependency injection without touching the rest of the app (ARCH-4).

## Implementation Details

- Define `Body` enum: `sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto, node` (exact data-model enum from the spec).
- Define a method returning, for a given `Body` and UTC `DateTime`: tropical ecliptic longitude (0–360, excluding 360) and the instantaneous longitude speed (degrees/day), from which retrograde is derived (negative speed).
- Define error/result types for "date outside the data files' covered range" (R-2) so callers can show a clear message instead of a silently wrong result.
- Document that implementations must return **apparent, geocentric, ecliptic-of-date** positions with **no extra precession correction** (NFR-A1) — this is the contract every adapter must honor.
- Define a separate method (or a formula-backed default implementation) for the mean ascending node: `Ω = 125.04452 − 1934.136261·T` degrees, T = Julian centuries since 2000-01-01 12:00 UTC.

## Design Reference

No direct design reference applies — this is a pure-Dart interface in `packages/astro_core`.

## Acceptance Criteria

- [ ] Interface compiles with zero Flutter/UI dependencies.
- [ ] Node formula is implemented as specified and covered by T-EPH-2 (ZOD-TST-002).
- [ ] Interface exposes both apparent-position output and speed, sufficient for retrograde and crossing-solver consumers.
- [ ] Interface documents the "out of data-file range" failure mode.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace

## Specification References

- "Planet position"
- "Architecture rules" ARCH-4
- NFR-A1
- R-2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
