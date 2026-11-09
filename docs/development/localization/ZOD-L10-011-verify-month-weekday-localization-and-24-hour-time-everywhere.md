# ZOD-L10-011 - Verify month/weekday localization and 24-hour time everywhere

## Metadata

- **ID:** ZOD-L10-011
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 4
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Confirm month and weekday names are always shown in the active language, and times are always 24-hour format regardless of language.

## Implementation Details

- Use `intl`'s locale-aware month/weekday formatting rather than a hand-maintained lookup table.
- Audit every time display for a stray 12-hour/AM-PM format slipping in from a platform default.

## Design Reference

No direct design reference applies to the mechanism; visible correct output in `design-reference/zodiann/screens/02-square-of-nine_dates_desktop_he_dark.png`'s cell-details date block.

## Acceptance Criteria

- [ ] Month/weekday names are correctly localized in both languages everywhere they appear.
- [ ] No 12-hour time format appears anywhere in the app.

## Dependencies

- ZOD-L10-010

## Specification References

- L-13

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
