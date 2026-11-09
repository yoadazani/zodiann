# ZOD-SQR-006 - Render highlight fills (blue/yellow/gray) on the square canvas

## Metadata

- **ID:** ZOD-SQR-006
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Apply the angle-based highlight fill to every cell, using `SquareColors` tokens, with weight-500 text on highlighted cells.

## Implementation Details

- Consume [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md)'s classification per cell; apply `axis-fill`/`diag-fill`/`eighth-fill` with their matching `-ink` text color.
- Unhighlighted cells use `cell-fill`/`cell-ink`.
- Verify the 9×9 totals (16/16/16) render visually identically to the component sheet's mini 9×9 reference.

## Design Reference

`design-reference/zodiann/components/components_dark.png` "Square of Nine cells" mini 9×9 grid (ground truth for the highlight pattern); `design-reference/zodiann/screens/02-square-of-nine_numbers_desktop_en_dark.png` for the full-size result; `design-reference/zodiann/MASTER.md` §2.2 token table.

## Acceptance Criteria

- [ ] A rendered 9×9 square visually matches the component sheet's reference grid exactly.
- [ ] Highlighted-cell text uses the `-ink` token (sufficient contrast against its fill, NFR-X5).

## Dependencies

- [ZOD-SQR-005](../gann-square/ZOD-SQR-005-build-the-square-canvas-single-canvas-cell-grid.md) — Build the square canvas (single-canvas cell grid)
- [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) — Implement Gann highlight classification (blue/yellow/gray)
- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)

## Specification References

- SQ-12 to SQ-15
- MASTER.md §2.2
- NFR-X5

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
