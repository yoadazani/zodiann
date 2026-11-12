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

- 2026-11-12 (product-owner decision): this task owns the dedicated T-GAN-4 verification of the mapping implemented in [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md), whose criterion was amended to point here. As with ZOD-TST-002:
  - expected dates come from an independent source (literal dates), never from production helpers;
  - add a mutation proof.
- 2026-11-12 (product-owner decision): date-and-time cells are shown in the **device's local time zone** (absolute 4-hour steps, with a visible one-hour jump at DST). Dates mode uses calendar-day arithmetic on the anchor's own date. Use an injected fake zone with a known DST transition, so the suite doesn't depend on the test machine's zone. See GAN-003's Notes.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
