# ZOD-WHL-020 - Build the degree-crossings filter row

## Metadata

- **ID:** ZOD-WHL-020
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the filter controls for the degree table: body, date range (up to 3,660 days), sign, and degree-within-sign.

## Implementation Details

- Fields: Body (default "All except the Moon"), From, To (date range capped at 3,660 days — enforced here as a UI-level validation in addition to the core cap in [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md)), Sign ("Any sign" default), Degree (0–29, default 0°).
- Default state on load: all planets (Moon excluded), today through one year ahead.
- Desktop: one row (Body 1.3fr, From, To, Sign, Degree .7fr per MASTER.md's fr-unit layout). Tablet/phone: two columns.

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` "Degree crossings" filter row (Body/From/To/Sign/Degree); `design-reference/zodiann/MASTER.md` §7.3 "Degree crossings" bullet for the exact fr-unit column layout and the tablet/phone two-column fallback.

## Acceptance Criteria

- [ ] Default filter state matches the spec exactly (all except Moon, today → +1 year).
- [ ] Selecting a date range beyond 3,660 days is rejected or clamped with a clear message (NFR-R2).
- [ ] Layout matches the fr-unit proportions on desktop and the two-column form on tablet/phone.

## Dependencies

- [ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) — Implement the input/field component
- [ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) — Implement the segmented control component
- [ZOD-CRS-004](../computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md) — Implement the degree-crossing query API (range, body filter, product limits)

## Specification References

- WH-16
- MASTER.md §7.3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
