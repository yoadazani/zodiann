# ZOD-NFR-015 - Audit invalid-input handling app-wide

## Metadata

- **ID:** ZOD-NFR-015
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Systematic sweep confirming every user-editable field in the app (not just the ones already covered per-task) rejects invalid input with a clear message and never crashes.

## Implementation Details

- Specifically target: wheel date/time field, square anchor field, square custom-size field, settings numeric fields (orbs, step hours), saved-square name field, backup-import file parsing.
- Each must show a clear, actionable message (reusing [ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md)'s error state) rather than throwing an unhandled exception.

## Design Reference

No direct design reference applies — verifies the already-built input error state ([ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md)) is actually wired everywhere it's needed.

## Acceptance Criteria

- [ ] NFR-R2 passes: every listed field rejects at least one deliberately invalid input with a clear message and no crash.

## Dependencies

- [ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) — Implement the input/field component
- [ZOD-WHL-014](../zodiac-wheel/ZOD-WHL-014-build-the-time-panel-date-time-field-and-now-button.md) — Build the Time panel: date/time field and Now button
- [ZOD-SQR-002](../gann-square/ZOD-SQR-002-build-the-anchor-field-and-anchor-to-today-now-shortcut.md) — Build the anchor field and "Anchor to today/now" shortcut
- [ZOD-SQR-003](../gann-square/ZOD-SQR-003-build-the-square-size-selector-presets-custom.md) — Build the square-size selector (presets + custom)
- [ZOD-SET-008](../settings-persistence/ZOD-SET-008-implement-reliability-behavior-for-invalid-settings-input.md) — Implement reliability behavior for invalid settings input
- [ZOD-DAT-008](../settings-persistence/ZOD-DAT-008-implement-backup-export-import-single-json-file.md) — Implement backup export/import (single JSON file)

## Specification References

- NFR-R2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
