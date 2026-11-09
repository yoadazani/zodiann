# ZOD-SQR-013 - Build cell details: date-mode fields

## Metadata

- **ID:** ZOD-SQR-013
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Add the date-block fields that appear only in dates and date-and-time modes.

## Implementation Details

- Full weekday date (plus time in hour mode) on a `bg-raised` block, e.g., "Monday, 31 August 2026."
- Below it, distance from the anchor: "138 days after the anchor" (dates mode) or "204 hours after the anchor" (hour mode).
- Hebrew compass phrases (if localizing direction text) take the adjective form, e.g., "צפונית למרכז" (north of center) — not a literal word-for-word translation (L10N cross-reference).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` ("Monday, 31 August 2026" / "138 days after the anchor" block); `design-reference/zodiann/MASTER.md` §8.3 "Date block".

## Acceptance Criteria

- [ ] Date block appears only in dates/date-and-time modes, never numbers mode.
- [ ] "N days/hours after the anchor" value matches ZOD-GAN-003's distance computation exactly.

## Dependencies

- [ZOD-SQR-012](../gann-square/ZOD-SQR-012-build-cell-details-core-fields.md) — Build cell details: core fields
- [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) — Implement Gann date/number mapping per mode

## Specification References

- SQ-18
- MASTER.md §8.3
- MASTER.md §13 (Hebrew compass phrase form)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
