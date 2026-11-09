# ZOD-L10-010 - Implement the English date-order setting and Hebrew's fixed format

## Metadata

- **ID:** ZOD-L10-010
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Apply the date-format rule across every date display in the app: Hebrew always `d.m.yyyy` (fields) / `d.m.yy` (cells); English follows the user's day/month/year vs. month/day/year setting.

## Implementation Details

- Centralize date formatting through one utility that reads the current language + (for English) the date-order setting from [ZOD-SET-002](../settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md), used by every screen that shows a date (wheel's time field, square's anchor/cells, saved-squares meta, About's build date).

## Design Reference

`design-reference/zodiann/MASTER.md` §13 "Date formats" row.

## Acceptance Criteria

- [ ] Every date shown in the app (not just the square) respects this one centralized formatting rule.
- [ ] T-FMT-1 continues to pass for the square's `d.m.yy` cell format specifically.

## Dependencies

- [ZOD-SET-002](../settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md) — Build the Language and region panel
- [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) — Implement Gann date/number mapping per mode

## Specification References

- L-12
- MASTER.md §13

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
