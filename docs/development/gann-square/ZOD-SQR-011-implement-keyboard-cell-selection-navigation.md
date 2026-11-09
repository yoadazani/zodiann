# ZOD-SQR-011 - Implement keyboard cell-selection navigation

## Metadata

- **ID:** ZOD-SQR-011
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

With an external keyboard, arrow keys move the selected cell one step in each board direction, stopping at the edge.

## Implementation Details

- Up/Down/Left/Right move the selection by one cell on the physical board grid (not by spiral order), clamped at the square's edge.
- Must work on the square, which is always LTR-rendered ([ZOD-SQR-016](../gann-square/ZOD-SQR-016-enforce-ltr-always-rendering-of-the-square.md)) regardless of app language — confirm arrow-key directions map to the same physical cells in both RTL and LTR app modes (since the square itself never flips).

## Design Reference

No direct design reference applies — behavioral/accessibility interaction on the already-designed grid.

## Acceptance Criteria

- [ ] Each arrow key moves selection exactly one cell in the corresponding board direction.
- [ ] Selection cannot move past the square's edge.
- [ ] Arrow-key mapping is identical in Hebrew and English builds (square never mirrors).

## Dependencies

- [ZOD-SQR-010](../gann-square/ZOD-SQR-010-implement-cell-tap-to-select-and-details-panel-wiring.md) — Implement cell tap-to-select and details-panel wiring

## Specification References

- SQ-19
- NFR-X2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
