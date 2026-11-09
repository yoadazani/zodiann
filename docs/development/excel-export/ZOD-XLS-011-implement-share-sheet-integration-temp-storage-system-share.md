# ZOD-XLS-011 - Implement share-sheet integration (temp storage + system share)

## Metadata

- **ID:** ZOD-XLS-011
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Write the generated file to app temporary storage and hand it to the OS share sheet, treating a dismissed sheet as a normal (non-error) outcome.

## Implementation Details

- Use the platform share intent (save, Excel, mail, etc.) with the temp file.
- Closing the share sheet without choosing an action must **not** surface as an error state (EX-7's explicit carve-out).

## Design Reference

No direct design reference applies — this is OS-level integration; the triggering UI is [ZOD-XLS-010](../excel-export/ZOD-XLS-010-build-the-export-status-ui-disabled-button-toast-states.md).

## Acceptance Criteria

- [ ] Exported file opens correctly in a third-party app chosen from the share sheet.
- [ ] Dismissing the share sheet without choosing returns the UI to its idle (not error) state.

## Dependencies

- [ZOD-XLS-010](../excel-export/ZOD-XLS-010-build-the-export-status-ui-disabled-button-toast-states.md) — Build the export status UI (disabled button + toast states)

## Specification References

- EX-7

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
