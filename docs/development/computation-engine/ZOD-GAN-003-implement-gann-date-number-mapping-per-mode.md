# ZOD-GAN-003 - Implement Gann date/number mapping per mode

## Metadata

- **ID:** ZOD-GAN-003
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Map a cell's spiral position `k` (steps from center) to its displayed value in each of the three modes, and compute "today's" cell.

## Implementation Details

- Numbers mode: `value(n) = n` (center = 1).
- Dates mode: `date(n) = anchor + (n−1)` calendar days, computed via local date arithmetic (year, month, day + n−1) so DST does not shift the date (not via absolute-time addition).
- Date-and-time mode: `moment(n) = anchor + 4·(n−1)` hours in **absolute time** (so a DST transition does shift the displayed local hour by one — this is the documented, accepted behavior per the spec, flagged as needing a final decision in §6).
- "Cell of today": dates mode = calendar days between anchor and today, +1; hour mode = whole 4-hour blocks elapsed since anchor (floored), +1.
- Display format: `d.m.yy` (no leading zero) for dates; `HH:MM` 24-hour for time.

## Design Reference

No direct design reference applies to the math; the resulting cell content format is `design-reference/zodiann/MASTER.md` §8.2 ("Content" row: `4.1.22`, date-over-`HH:MM`), verified visually against `design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` and `02-square-of-nine_datetime_desktop_he_dark.png`.

## Acceptance Criteria

- [ ] T-GAN-4 passes: anchor cell shows the anchor date exactly; today's cell is correctly identified across a DST boundary and in a leap year.
- [ ] T-FMT-1 passes: date format is `d.m.yy` with no leading zero (e.g., `4.1.24`), verified for both single- and double-digit day/month.
- [ ] A 4-hour-step date-and-time square crossing a DST change shows the documented one-hour jump, not a silently "corrected" time.

## Dependencies

- [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — Implement the Gann spiral position formulas (k, j, i, θ)

## Specification References

- "Dates" (full section)
- SQ-2 to SQ-7
- T-GAN-4
- T-FMT-1
- "time zone is the device's..." planning constraint

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
