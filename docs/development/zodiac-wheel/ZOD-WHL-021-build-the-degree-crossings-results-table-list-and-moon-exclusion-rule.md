# ZOD-WHL-021 - Build the degree-crossings results table/list and Moon-exclusion rule

## Metadata

- **ID:** ZOD-WHL-021
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Render the filtered, sorted crossing results, with the "Moon excluded from All" rule enforced end-to-end (not just at the core query level).

## Implementation Details

- Desktop/tablet-landscape: table with columns Local date and time (date + two spaces + time in `text-3`), Body, Sign, Degree, Motion.
- Phone/tablet-portrait: two-line list row — body glyph | date/time over "Body → Sign" | sign glyph, degree, ℞ — per D9's explicit column-count rationale (5 columns don't fit a phone, NFR-C2).
- Rows sorted by time; up to 2,500 shown; a counter shows the true total (e.g., "43 crossings") even when capped.
- A retrograde body crossing the same degree multiple times produces one row per crossing, each separately marked (WH-18).
- The Moon never appears when "All" is selected (WH-20) — selecting the Moon explicitly is the only way to see its rows.
- List fades out at the bottom edge of its scroll area (visual treatment from the mockup).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (full crossings table, "43 crossings" counter); `design-reference/zodiann/responsive/mobile/zodiac-wheel_mobile_*` for the two-line list variant; `design-reference/zodiann/MASTER.md` §7.3 "Degree crossings" and `DESIGN_DECISIONS.md` D9.

## Acceptance Criteria

- [ ] Rows are sorted by time, capped at 2,500, with an accurate true-total counter.
- [ ] A known retrograde triple-crossing produces three distinct, individually-marked rows.
- [ ] "All" selection never includes the Moon; explicit Moon selection does include it.
- [ ] Phone/tablet-portrait renders the two-line list, not the 5-column table (NFR-C2).

## Dependencies

- [ZOD-WHL-020](../zodiac-wheel/ZOD-WHL-020-build-the-degree-crossings-filter-row.md) — Build the degree-crossings filter row
- [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md) — Implement the degree-crossing query API (range, body filter, product limits)
- [ZOD-UI-010](../shared-ui-design-system/ZOD-UI-010-implement-the-table-component-header-rows-hover-selected.md) — Implement the table component (header, rows, hover, selected)

## Specification References

- WH-16
- WH-17
- WH-18
- WH-20
- NFR-C2
- DESIGN_DECISIONS.md D9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
