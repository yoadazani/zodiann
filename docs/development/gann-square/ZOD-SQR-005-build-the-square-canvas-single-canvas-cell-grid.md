# ZOD-SQR-005 - Build the square canvas (single-canvas cell grid)

## Metadata

- **ID:** ZOD-SQR-005
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Render the full spiral grid — up to 3,721 cells — as one `CustomPainter`/`RepaintBoundary`, not individual widgets per cell (ARCH-5).

## Implementation Details

- 1px `cell-line` gaps between cells, 1px `line` outer border; cell content centered at 11.5px (micro type role from [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md)).
- Content per mode (reuses [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md)'s formatting): Numbers → `1,771` (thousands separator); Dates → `4.1.22`; Date and time → date over `HH:MM` at 86% size / 78% opacity.
- Must render the maximum 61×61 (3,721 cells) grid without frame-rate degradation (verified in [ZOD-NFR-005](../performance-accessibility-reliability/ZOD-NFR-005-validate-61-61-square-rendering-performance-nfr-p4.md)/NFR-P4).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` (full 17×17 grid, exact cell content formatting); `design-reference/zodiann/MASTER.md` §8.2 "Content" row and §8.1 ARCH-5 note ("the mockup draws it with cells, but the look is what counts").

## Acceptance Criteria

- [ ] A 61×61 square renders as a single painter (verified via widget-tree inspection, not 3,721 widgets).
- [ ] Cell content matches the exact format strings per mode.
- [ ] T-UI-4's rendering portion passes: numbers-mode cells show the correct number.

## Dependencies

- [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) (shared single-canvas pattern)
- [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — Implement the Gann spiral position formulas (k, j, i, θ)
- [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) — Implement Gann date/number mapping per mode
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale

## Specification References

- ARCH-5
- SQ-20 (content)
- T-UI-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
