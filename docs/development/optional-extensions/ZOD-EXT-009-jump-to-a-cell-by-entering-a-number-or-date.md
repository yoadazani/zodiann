# ZOD-EXT-009 - Jump to a cell by entering a number or date

## Metadata

- **ID:** ZOD-EXT-009
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Add a search/jump control that selects and scrolls to the cell matching a user-entered number (numbers mode) or date (date modes), independent of the anchor.

## Implementation Details

Inverse of [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md)'s forward mapping — given a target value, solve for its `n`/`k` and delegate to [ZOD-SQR-010](../gann-square/ZOD-SQR-010-implement-cell-tap-to-select-and-details-panel-wiring.md)'s selection + scroll behavior.

## Design Reference

No direct design reference applies — not shown in any mockup.

## Acceptance Criteria

- [ ] Entering a valid number/date selects and scrolls to the correct cell.
- [ ] An out-of-range entry (not present in the current square size) shows a clear message rather than crashing.

## Dependencies

- [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) — Implement Gann date/number mapping per mode
- [ZOD-SQR-010](../gann-square/ZOD-SQR-010-implement-cell-tap-to-select-and-details-panel-wiring.md) — Implement cell tap-to-select and details-panel wiring

## Specification References

- "Planned extensions to the square" (entering a number or date and jumping to the matching cell)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
