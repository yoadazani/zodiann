# ZOD-TST-016 - Conduct manual acceptance testing with the user

## Metadata

- **ID:** ZOD-TST-016
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 3–4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Run the three named manual acceptance scenarios with the actual product owner/user before considering the app release-ready, per "Acceptance tests with the user."

## Implementation Details

- Scenario 1: the crossing table matches a trusted ephemeris on 5 random crossings across 4 different bodies.
- Scenario 2: a dates-mode square anchored 4.1.22 shows today in the correct cell, checked across each of the three modes.
- Scenario 3: the Excel file opens correctly in Excel and a second editing app (e.g., LibreOffice or Google Sheets), formulas included, with no warnings/errors.
- This is a people-process task, not a code task — schedule it explicitly, don't assume automated tests substitute for it.

## Design Reference

No direct design reference applies — this validates the already-built product against the user's own judgment, not against a mockup.

## Acceptance Criteria

- [ ] All three scenarios are run with the actual user/product owner and explicitly signed off.
- [ ] Any failure found here is filed as a bug against the relevant ZOD task, not silently worked around.

## Dependencies

- [ZOD-WHL-021](../zodiac-wheel/ZOD-WHL-021-build-the-degree-crossings-results-table-list-and-moon-exclusion-rule.md) — Build the degree-crossings results table/list and Moon-exclusion rule
- [ZOD-SQR-009](../gann-square/ZOD-SQR-009-implement-the-today-cell-computation-and-live-update.md) — Implement the "today" cell computation and live update
- [ZOD-XLS-010](../excel-export/ZOD-XLS-010-build-the-export-status-ui-disabled-button-toast-states.md) — Build the export status UI (disabled button + toast states)

## Specification References

- "Acceptance tests with the user"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
