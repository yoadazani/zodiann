# ZOD-EXT-006 - Rotating outer rings on the Square of Nine

## Metadata

- **ID:** ZOD-EXT-006
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Add one or more rotatable outer rings around the square with a 0–360° scale; rotating a ring offsets the angle of every cell, updating highlights and cell-detail angles live.

## Implementation Details

The spec itself flags this as "an interpretation of the plan" needing approval before design or implementation — do not invent a visual treatment; D16 explicitly notes the mockups deliberately don't show this so as not to invent its look. The square's existing compass-label band ([ZOD-SQR-017](../gann-square/ZOD-SQR-017-build-the-compass-axis-labels-around-the-square.md)) is noted as "the natural place for a future ring scale" if/when this is approved.

## Design Reference

**Explicit design gap** — `design-reference/zodiann/DESIGN_DECISIONS.md` D16 states this is intentionally not mocked. Do not invent a visual design for this; request new design reference before implementing.

## Acceptance Criteria

- [ ] No implementation work starts before a design reference exists for this feature.
- [ ] Once designed, rotating a ring correctly offsets all affected cells' angle, highlight, and detail-panel output live.

## Dependencies

- [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) — Implement Gann highlight classification (blue/yellow/gray)
- [ZOD-SQR-017](../gann-square/ZOD-SQR-017-build-the-compass-axis-labels-around-the-square.md) — Build the compass axis labels around the square

## Specification References

- "Planned extensions to the square" (rotating rings)
- DESIGN_DECISIONS.md D16

## Notes

- This task touches an item flagged **needing approval** in `design-reference/zodiann/DESIGN_DECISIONS.md` — confirm the interpretation above with the product owner before implementing.
- This task has an **explicit design gap** — no design reference covers it yet. Do not invent a visual treatment; request design work before implementing (see Design Reference above).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
