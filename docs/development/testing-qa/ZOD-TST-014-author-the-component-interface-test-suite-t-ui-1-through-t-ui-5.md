# ZOD-TST-014 - Author the component/interface test suite (T-UI-1 through T-UI-5)

## Metadata

- **ID:** ZOD-TST-014
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 2–3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Dedicated widget-level tests for the five named interface scenarios, consolidating what's already an acceptance criterion on individual feature tasks into one named, trackable suite.

## Implementation Details

- T-UI-1 (owned jointly with [ZOD-NAV-003](../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md)): drawer navigation, relaunch-returns-to-last-screen, deep link.
- T-UI-2 (owned jointly with [ZOD-WHL-010](../zodiac-wheel/ZOD-WHL-010-implement-wheel-rotation-via-drag-rotate-wheel-mode.md)/011): wheel drag in both modes.
- T-UI-3 (owned jointly with [ZOD-SQR-001](../gann-square/ZOD-SQR-001-build-the-mode-switcher-with-state-preservation.md)/003): anchor/size entry redraws and preserves values.
- T-UI-4 (owned jointly with [ZOD-SQR-010](../gann-square/ZOD-SQR-010-implement-cell-tap-to-select-and-details-panel-wiring.md)): cell tap opens correct details in numbers mode.
- T-UI-5 (owned jointly with [ZOD-XLS-010](../excel-export/ZOD-XLS-010-build-the-export-status-ui-disabled-button-toast-states.md)): export offers save, saved file opens with three sheets.

## Design Reference

No direct design reference applies — this task tracks test coverage, not new UI.

## Acceptance Criteria

- [ ] All five T-UI scenarios exist as named, independently runnable widget tests.
- [ ] Each is wired into CI (ZOD-FND-004) as part of the required suite, not a manual-only check.

## Dependencies

- [ZOD-NAV-003](../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md) — Wire drawer navigation to `go_router` routes
- [ZOD-WHL-010](../zodiac-wheel/ZOD-WHL-010-implement-wheel-rotation-via-drag-rotate-wheel-mode.md) — Implement wheel rotation via drag (rotate-wheel mode)
- [ZOD-WHL-011](../zodiac-wheel/ZOD-WHL-011-implement-change-date-drag-mode.md) — Implement change-date drag mode
- [ZOD-SQR-001](../gann-square/ZOD-SQR-001-build-the-mode-switcher-with-state-preservation.md) — Build the mode switcher with state preservation
- [ZOD-SQR-003](../gann-square/ZOD-SQR-003-build-the-square-size-selector-presets-custom.md) — Build the square-size selector (presets + custom)
- [ZOD-SQR-010](../gann-square/ZOD-SQR-010-implement-cell-tap-to-select-and-details-panel-wiring.md) — Implement cell tap-to-select and details-panel wiring
- [ZOD-XLS-010](../excel-export/ZOD-XLS-010-build-the-export-status-ui-disabled-button-toast-states.md) — Build the export status UI (disabled button + toast states)

## Specification References

- T-UI-1
- T-UI-2
- T-UI-3
- T-UI-4
- T-UI-5

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
