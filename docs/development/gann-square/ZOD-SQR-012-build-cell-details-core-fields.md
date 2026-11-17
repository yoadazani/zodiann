# ZOD-SQR-012 - Build cell details: core fields

## Metadata

- **ID:** ZOD-SQR-012
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the details-panel rows common to all modes.

## Implementation Details

- Head: "Cell" label + number in display type (44/300); highlight tag with its mark (Axis +, Diagonal ×, Eighth, No highlight, Center); Today outline tag when applicable.
- Rows (13px, label `text-2`, value 500 at the end): Squared (`139² = 19,321`), Square root to 4 decimal places (`√139 = 11.7898`), Ring + cell count (`6 (48 cells)`), Angle (`90°`), Direction (axis/diagonal/"between the axes and the diagonals," with compass qualifier e.g. "Axis, north"), Offset from center (e.g., "6 up" / "3 left, 2 up"), Multiple of 45°/22.5° (Yes/No each).
- Highlight-line sentence in a `bg-raised` box with a 3px accent bar in the highlight's color, e.g., "Blue: on the 90° axis, north of the center."

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` "Cell 139" details panel (every row listed above is visible with exact values); `design-reference/zodiann/MASTER.md` §8.3 "Cell details".

## Acceptance Criteria

- [ ] All rows match the reference screenshot's exact values for the same cell/anchor/size.
- [ ] Square root is shown to exactly 4 decimal digits.
- [ ] Direction string correctly distinguishes axis / diagonal / "between the axes and the diagonals."

## Dependencies

- [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — Implement the Gann spiral position formulas (k, j, i, θ)
- [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) — Implement Gann highlight classification (blue/yellow/gray)
- [ZOD-UI-009](../shared-ui-design-system/ZOD-UI-009-implement-the-tag-component-highlight-tags-mode-tags-today-center.md) — Implement the tag component (highlight tags, mode tags, Today/Center outline tags)
- [ZOD-UI-014](../shared-ui-design-system/ZOD-UI-014-implement-the-hairline-panel-component.md) — Implement the hairline panel component

## Specification References

- SQ-17
- MASTER.md §8.3

## Notes

- **From ZOD-L10-007 (2026-11-14):** the "Direction" row uses `CompassDirection.atAngle(cell.angle)` (`gann_core`) plus `ZodiannLocalizations.directionName` for "Axis, west" / "ציר, מערב". The third case, "between the axes and the diagonals", has no direction: `atAngle` returns null, and the screen uses its own key (kit.js `dirBetween`). Build the phrase with an ICU placeholder, not concatenation. The Hebrew highlight-line sentence ("… צפונית למרכז") needs the adjective form, which `directionName` doesn't provide. Add screen keys (an ICU `select` on `direction.name`).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*

- **From ZOD-UI-009 (2026-11-17):** use `ZodiannTag(variant:, label:)`. Map the cell's highlight (axis / diagonal / eighth / none / center) to `ZodiannTagVariant` and show `ZodiannTag(variant: today)` when it applies. The `+` / `×` mark is bound to the axis and diagonal variants (NFR-X4), so never draw it yourself. The six vocabulary strings (`tagAxis` … `tagCenter`, en / he in `kit.js`) are ARB keys owned here, with parity tests. A tag fills the width of a stretch `Column` and the height of a horizontal `ListView`: wrap it in `Align` or `UnconstrainedBox` where that matters. Give it a non-empty label.
