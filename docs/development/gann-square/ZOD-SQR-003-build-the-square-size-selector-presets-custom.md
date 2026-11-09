# ZOD-SQR-003 - Build the square-size selector (presets + custom)

## Metadata

- **ID:** ZOD-SQR-003
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the size control: four presets plus a custom cell-count entry, with the actual rounded-up cell count displayed.

## Implementation Details

- Presets: 9×9, 13×13, 17×17, 21×21, Custom (segmented control).
- Custom: numeric entry for cell count, 9–3,721, rounded up to the next odd-sided full square (max 61×61); the "Cells" field is disabled unless Custom is selected.
- Below a rule, display the actual count and dimensions, e.g., "289 cells, 17 × 17" (SQ-10's display requirement).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` "Size" segmented control + "Cells" field + the "289 cells, 17 × 17" line below the rule.

## Acceptance Criteria

- [ ] Selecting a preset sets the exact size; Custom unlocks the Cells field.
- [ ] Entering 290 in Custom rounds up to the next odd-sided square (19×19 = 361) and displays "361 cells, 19 × 19".
- [ ] Entering a value above 3,721 is clamped/rejected with a clear message (NFR-R2), capping at 61×61.

## Dependencies

- [ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) — Implement the input/field component
- [ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) — Implement the segmented control component
- [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — Implement the Gann spiral position formulas (k, j, i, θ)

## Specification References

- SQ-10
- NFR-R2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
