# ZOD-XLS-013 - Implement degree-crossing table export (xlsx/csv)

## Metadata

- **ID:** ZOD-XLS-013
- **Category:** [Excel Export](../README.md#excel-export) (`excel-export/`)
- **Phase:** Phase 2
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Export the wheel's degree-crossing results — all matching rows, not just the first 2,500 shown on screen — to xlsx or CSV.

## Implementation Details

- Same columns as the on-screen table ([ZOD-WHL-021](../zodiac-wheel/ZOD-WHL-021-build-the-degree-crossings-results-table-list-and-moon-exclusion-rule.md)): local date/time, body, sign, degree, motion.
- Must run the full (uncapped) query against [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md), bypassing the 2,500-row UI display cap, since the export's whole purpose is to give the complete result set.
- Export button sits in the "Degree crossings" panel head (already visible in the wheel mockup).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` "Export" button in the Degree crossings panel head.

## Acceptance Criteria

- [ ] Export contains every crossing in the filtered range, not capped at 2,500.
- [ ] Columns match the on-screen table exactly.

## Dependencies

- [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md) — Implement the degree-crossing query API (range, body filter, product limits)
- [ZOD-XLS-001](../excel-export/ZOD-XLS-001-spike-ooxml-xlsx-generation-via-raw-archive-xml.md) — Spike: OOXML (xlsx) generation via raw archive + XML

## Specification References

- "Other formats" table (Degree table row)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Excel Export" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
