# ZOD-XLS-012 - Enforce Excel formula-compatibility constraints

## Metadata

- **ID:** ZOD-XLS-012
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Codify and enforce, as a reviewable constraint across all of `excel-export/`, that only basic cross-compatible functions are ever used in generated formulas.

## Implementation Details

- Maintain an explicit allow-list (addition, multiplication, SQRT, MOD, ROUNDUP/ROUNDDOWN, IF, AND, NOT, INT, NOW) used by every formula-writing code path in [ZOD-XLS-002](../excel-export/ZOD-XLS-002-implement-the-gann-spiral-helper-sheet-hidden.md) through 006.
- No dynamic array functions, no custom/user-defined functions, no macros (EX-16) — add a lint/review check over the generated XML that flags any function outside the allow-list.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] An automated check over the generated workbook's formula strings confirms every function used is on the allow-list.
- [ ] T-EX-5's cross-app compatibility (Excel/LibreOffice/Google Sheets) continues to pass.

## Dependencies

- [ZOD-XLS-002](../excel-export/ZOD-XLS-002-implement-the-gann-spiral-helper-sheet-hidden.md) through [ZOD-XLS-006](../excel-export/ZOD-XLS-006-implement-the-details-sheet.md)

## Specification References

- EX-16

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
