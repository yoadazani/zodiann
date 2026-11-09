# ZOD-ABT-005 - Build the "Not advice" notice

## Metadata

- **ID:** ZOD-ABT-005
- **Category:** [About & Sources](../README.md#about) (`about/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the fixed disclaimer addressing R-5 (users mistaking a result for financial/astrological advice).

## Implementation Details

- Fixed copy, warning-icon treatment: "Zodiann computes positions and geometry. It does not interpret them, and nothing in the app or its exports is a recommendation to buy or sell."
- Cross-reference with the Excel export: the spec implies this disclaimer concept should also appear in exports (R-5's mitigation says "a fixed disclaimer on the About page **and in the export**") — verify [ZOD-XLS-006](../excel-export/ZOD-XLS-006-implement-the-details-sheet.md) (Details sheet) or [ZOD-XLS-017](../excel-export/ZOD-XLS-017-document-the-excel-exports-known-limits.md) includes equivalent wording; if it currently doesn't, file that gap against those tasks.

## Design Reference

`design-reference/zodiann/screens/05-about-sources_desktop_en_dark.png` "Not advice" notice block (exact copy and warning-icon treatment).

## Acceptance Criteria

- [ ] Notice text matches the reference screenshot's copy and tone.
- [ ] The equivalent disclaimer is confirmed present somewhere in the Excel export (Details sheet), closing the loop on R-5's full mitigation — not just the About page.

## Dependencies

- [ZOD-ABT-001](../about/ZOD-ABT-001-build-the-about-screen-hero.md) — Build the About screen hero
- [ZOD-XLS-006](../excel-export/ZOD-XLS-006-implement-the-details-sheet.md) — Implement the "Details" sheet

## Specification References

- R-5
- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "About & Sources" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
