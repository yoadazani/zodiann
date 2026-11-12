# ZOD-TST-013 - Author the date-format test (T-FMT-1)

## Metadata

- **ID:** ZOD-TST-013
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Verify the `d.m.yy`-no-leading-zero format across the full range of single/double-digit day and month combinations.

## Implementation Details

- Parameterize across day 1–31 and month 1–12 (not just one spot-check date), asserting no leading zero ever appears and the separator is a literal period.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] Both single-digit and double-digit day/month combinations are tested (e.g., `4.1.24` and `14.11.24`).

## Dependencies

- [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) — Implement Gann date/number mapping per mode

## Specification References

- T-FMT-1

## Notes

- 2026-11-12 (product-owner decision): this task owns the dedicated T-FMT-1 verification of the date format implemented in [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md), whose criterion was amended to point here. As with ZOD-TST-002:
  - expected strings are literals, never produced by production helpers;
  - add a mutation proof (for example a padded day or month must fail).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
