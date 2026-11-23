# ZOD-UI-010 - Implement the table component (header, rows, hover, selected)

## Metadata

- **ID:** ZOD-UI-010
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done
- **Scope:** MVP

## Description

Build the shared table shell used by the positions table and the degree-crossings table.

## Implementation Details

- Header: 12/500 in `text-3`, sentence case.
- Rows: 44px high with a `line-soft` divider.
- Hover: `surface-2` fill. Selected: `accent-soft` fill with a 3px `accent` edge on the start side (logical "start," flips under RTL).

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Tables"; `design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (Positions table showing the selected Sun row with its start-edge accent bar) and the Hebrew variant to confirm the edge flips correctly.

## Acceptance Criteria

- [x] Header, row, hover, and selected states match the screenshots in both themes. (`table_sheet_test.dart`: the component sheet's four rows in Graphite and Porcelain read as runs of colour down a column, plus the 2x compact capture; see Completion notes.)
- [x] The selected-row accent edge renders on the correct logical side in both LTR and RTL. (Geometry in `table_test.dart` for both directions; pixels against the English and Hebrew desktop screens in `table_sheet_test.dart`.)

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Tables"
- L-4

## Notes

_No additional notes._

## Completion notes

- **Delivered:** `ZodiannTable`, `ZodiannTableHeader` and `ZodiannTableRow` with `ZodiannTableColumn`, `ZodiannTableAlign` and `ZodiannTableDensity` (`packages/shared_ui/lib/src/widgets/zodiann_table.dart`, `zodiann_table_column.dart`) and three size tokens (`ZodiannSize.tableHeaderPadding`, `tableCompactPadding`, `tableSelectedBar`). Columns are **declared** (flex or fixed), so a row is an independent widget: an 11-row table is `ZodiannTable`, a long list composes `ZodiannTableHeader` and `ZodiannTableRow`s (with `columns` and `isLast`) in a `ListView.builder` (ZOD-WHL-021).
- **Owner-approved defaults (2026-11-23):** O1 declared columns; O2 hover only on tappable rows, selected wins over hover; O3 compact density built now and chosen by the caller; O4 the table never clips and a panel holding one passes `Clip.antiAlias`; O5 the About screen's wrapping tables are out of scope.
- **Measured against the designer's pixels** (plan, "Measured facts"): row pitch 44 with a 1 px `line-soft` divider as its last pixel row; fills and bar stop above the divider; the **last row is 43** high; the header is 37 px plus its rule (the sheets snap it to 36 to 38); the bar is 3 px, inside the panel border, on the start edge (right in the Hebrew screen).
- **Decisions and rulings, in `docs/PROGRESS.md`:** table semantics roles only inside `ZodiannTable` (Flutter 3.50 asserts a `row` without a `table` parent, so a lazy list has no table semantics and WHL-021 owns an alternative); hover with `MouseRegion`; a row stays 44 up to about 2.1x text and grows beyond (the kit has no vertical padding); long plain text ellipsizes on one line (kit `nowrap`); cells keep their state when the selection changes (keyed content).
- **Notes for later tasks:** the kit's compact range is `max-width: 1100px` (inclusive) while `ZodiannBreakpoint` treats 1100 as desktop (WHL-024); a table needs a bounded width and does not work inside intrinsic-sizing parents such as an `AlertDialog` body.
- **Not covered:** the About screen's wrapping, top-aligned table; sorting, a sticky header and column resize; a device check and a screen-reader check of the announcement (no device or reader was used); the positions table's cell content and phone column drop (WHL-018) and the crossings two-line phone list (WHL-021).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
