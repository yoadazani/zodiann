# ZOD-EXT-007 - Show planet positions on the Square of Nine

## Metadata

- **ID:** ZOD-EXT-007
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Overlay live planet positions on the square's cells and allow moving between the wheel and square screens with shared context (UC9).

## Implementation Details

Requires mapping a body's current ecliptic longitude (or the date/time it's at a given degree) onto the square's number/date/time domain — a genuinely new cross-instrument computation, not just a UI overlay. D16 flags this alongside the rotating rings as deliberately unmocked.

## Design Reference

**Explicit design gap** — not shown in any mockup (D16). Do not invent a visual treatment; request design reference before implementation.

## Acceptance Criteria

- [ ] No implementation starts before a design reference exists.
- [ ] Once designed, the mapping between a body's position and its square cell is mathematically well-defined and tested.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)
- [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) — Implement Gann date/number mapping per mode

## Specification References

- UC9
- "Planned extensions to the square"
- DESIGN_DECISIONS.md D16

## Notes

- This task has an **explicit design gap** — no design reference covers it yet. Do not invent a visual treatment; request design work before implementing (see Design Reference above).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
