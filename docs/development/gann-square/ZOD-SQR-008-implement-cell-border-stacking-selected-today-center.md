# ZOD-SQR-008 - Implement cell border stacking (selected, today, center)

## Metadata

- **ID:** ZOD-SQR-008
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the exact inset-from-outside-in border stacking for every combination of selected/today/center state.

## Implementation Details

- Stacking order, outside in: Selected → Today → Center (D12).
- Selected: 2px `sel-outer` + 2px `sel-inner`. Selected + Today: 2px `sel-outer` + 2px `today`. Today alone: 2px `today`. Center alone: 2px `center` (amber). Center that is also today: double turquoise border, 2px + 2px gap + 2px (SQ-7's explicit double-border rule).
- Light theme's selection treatment per D11: keep the white `sel-outer` line and add a 2px ink outline outside it (because a pure white border is invisible on the light theme's white cells) — **flagged as needing approval**; if the product owner wants selection to stay strictly white in light theme, the square's background behind it needs to change instead.

## Design Reference

`design-reference/zodiann/MASTER.md` §8.2 "Borders" (complete stacking table); `design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` (visible selected cell `31.8.26` with white border, today cell `9.11.26` with turquoise border); `design-reference/zodiann/DESIGN_DECISIONS.md` D11, D12.

## Acceptance Criteria

- [ ] All five border combinations render pixel-for-pixel matching MASTER.md §8.2 in the dark theme.
- [ ] Light-theme selection uses the white+ink double treatment per D11 pending approval.
- [ ] A center cell that is also today shows the double-turquoise treatment, matching SQ-7 exactly.

## Dependencies

- [ZOD-SQR-005](../gann-square/ZOD-SQR-005-build-the-square-canvas-single-canvas-cell-grid.md) — Build the square canvas (single-canvas cell grid)
- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)

## Specification References

- SQ-7
- DESIGN_DECISIONS.md D11
- D12

## Notes

- This task touches an item flagged **needing approval** in `design-reference/zodiann/DESIGN_DECISIONS.md` — confirm the interpretation above with the product owner before implementing.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
