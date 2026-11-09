# ZOD-XLS-002 - Implement the Gann spiral "Helper" sheet (hidden)

## Metadata

- **ID:** ZOD-XLS-002
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 3
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Generate the hidden helper sheet holding, for every cell, its constant `k` plus formulas for ring, index, angle, and highlight type — the geometric foundation every other sheet's live formulas reference.

## Implementation Details

- One row per cell (up to 3,721), columns: `k` (a stored constant, computed once at export time from [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — not a formula, since it's a property of position, not of the anchor), then live formulas for ring `r`, index `i`, angle, Blue/Yellow/Gray, exactly as given in "The formulas" table: `r = IF(k=0, 0, ROUNDUP((SQRT(k+1)-1)/2, 0))`, `i = IF(r=0, 0, MOD(k-(2r-1)^2-(r-1), 8r))`, `angle = IF(r=0, 0, 45*i/r)`, `Blue = AND(r>0, MOD(i, 2r)=0)`, `Yellow = AND(r>0, NOT(Blue), MOD(i, r)=0)`, `Gray = AND(r>0, NOT(Blue), NOT(Yellow), MOD(2i, r)=0)`.
- Only basic functions (addition, multiplication, SQRT, MOD, ROUNDUP, IF, AND, NOT) — no dynamic arrays, no custom functions, no macros (EX-16).
- Sheet is hidden from normal view but still computes.

## Design Reference

No direct design reference applies — this sheet is never shown to the user; its existence and structure are specified in Appendix E "Building the Excel file".

## Acceptance Criteria

- [ ] Helper sheet formulas evaluate correctly in Excel, LibreOffice, and Google Sheets (verified via the ZOD-XLS-001 spike harness).
- [ ] T-EX-4 passes for a 9×9 square: recalculated highlight types total 16 blue, 16 yellow, 16 gray.
- [ ] Every formula uses only the EX-16-allowed function set.

## Dependencies

- [ZOD-XLS-001](../excel-export/ZOD-XLS-001-spike-ooxml-xlsx-generation-via-raw-archive-xml.md) — Spike: OOXML (xlsx) generation via raw archive + XML
- [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — Implement the Gann spiral position formulas (k, j, i, θ)
- [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) — Implement Gann highlight classification (blue/yellow/gray)

## Specification References

- EX-9
- EX-14
- EX-16
- Appendix E
- "The formulas" table

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
