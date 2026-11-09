# ZOD-XLS-001 - Spike: OOXML (xlsx) generation via raw archive + XML

## Metadata

- **ID:** ZOD-XLS-001
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

De-risk R-8 before building the real exporter: prove a hand-built OOXML file with a defined name, a live formula, and conditional formatting opens correctly in Excel, LibreOffice, and Google Sheets.

## Implementation Details

- Use the `archive` (ZIP) package plus hand-written XML parts (`[Content_Types].xml`, `workbook.xml`, `sheet1.xml`, `styles.xml`) to build a minimal file with: one defined name, one formula cell referencing it, one conditional-formatting rule.
- Open the result in real Excel, LibreOffice Calc, and Google Sheets (via upload) and confirm no repair prompt, no formula error, and correct conditional formatting.
- Document the minimal working XML skeleton for [ZOD-XLS-002](../excel-export/ZOD-XLS-002-implement-the-gann-spiral-helper-sheet-hidden.md) onward to build from.

## Design Reference

No direct design reference applies — file-format spike.

## Acceptance Criteria

- [ ] The spike file opens with no warnings/repair prompts in all three target apps.
- [ ] The formula and conditional formatting both evaluate correctly after opening.
- [ ] A reusable XML-building utility/template exists for the rest of `excel-export/`.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace

## Specification References

- R-8
- EX-16

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
