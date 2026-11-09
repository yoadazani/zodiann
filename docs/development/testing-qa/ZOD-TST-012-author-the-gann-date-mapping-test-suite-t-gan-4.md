# ZOD-TST-012 - Author the Gann date-mapping test suite (T-GAN-4)

## Metadata

- **ID:** ZOD-TST-012
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Verify date mapping including a DST boundary and a leap year, per T-GAN-4's explicit edge cases.

## Implementation Details

- Construct a dates-mode square with an anchor chosen so the square spans a known DST transition in at least one real time zone, and assert no cell is skipped/duplicated incorrectly and today's-cell marking stays correct across it.
- Construct a second case spanning Feb 29 of a leap year, asserting the date sequence is correct.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] DST-boundary case passes with the documented (accepted, not "fixed") one-hour-jump behavior for date-and-time mode (R-4's accepted tradeoff), and with dates-mode calendar-day arithmetic unaffected by DST.
- [ ] Leap-year case correctly includes Feb 29 without an off-by-one.

## Dependencies

- [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) — Implement Gann date/number mapping per mode

## Specification References

- T-GAN-4
- R-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
