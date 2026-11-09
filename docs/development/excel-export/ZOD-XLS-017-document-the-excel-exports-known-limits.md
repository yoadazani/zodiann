# ZOD-XLS-017 - Document the Excel export's known limits

## Metadata

- **ID:** ZOD-XLS-017
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Surface the three documented file limits to the user at the right moments, rather than letting them discover them as silent bugs.

## Implementation Details

- Changing size/mode requires re-exporting (no in-file way to do it) — reflect this in the Details sheet and/or export-time copy.
- The file has no time zone; a DST jump in date-and-time mode isn't modeled in the file, so it may show a different hour than the app on days when the clock jumps — document in the Details sheet.
- An anchor date before 1900 is not supported in Excel — validate at export time and show a clear message rather than producing a broken file.

## Design Reference

No direct design reference applies — this is a messaging/validation task layered on [ZOD-XLS-006](../excel-export/ZOD-XLS-006-implement-the-details-sheet.md) and [ZOD-XLS-010](../excel-export/ZOD-XLS-010-build-the-export-status-ui-disabled-button-toast-states.md)'s toast system.

## Acceptance Criteria

- [ ] Attempting to export with an anchor before 1900 is rejected with a clear message before file generation starts.
- [ ] The Details sheet documents the no-timezone and re-export-required limits in plain language.

## Dependencies

- [ZOD-XLS-006](../excel-export/ZOD-XLS-006-implement-the-details-sheet.md) — Implement the "Details" sheet
- [ZOD-XLS-010](../excel-export/ZOD-XLS-010-build-the-export-status-ui-disabled-button-toast-states.md) — Build the export status UI (disabled button + toast states)

## Specification References

- "Limits that will remain in the file"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
