# ZOD-L10-008 - Implement ICU plural rules for countable UI text

## Metadata

- **ID:** ZOD-L10-008
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Use the `intl` package's ICU plural support for every countable phrase ("3 cells," "43 crossings," "7 of 100 saved"), instead of string concatenation.

## Implementation Details

- Audit every count-bearing string across the app (crossings counter, saved-squares counter, cell-count display) and route them through ICU plural messages in the ARB files.

## Design Reference

No direct design reference applies to the mechanism; the specific counting strings to localize are visible throughout `design-reference/zodiann/screens/` (e.g., "43 crossings," "289 cells, 17 × 17," "7 of 100 saved").

## Acceptance Criteria

- [ ] Every countable string uses ICU plural rules, verified correct for 0/1/2/many in both Hebrew (which has distinct dual/plural forms) and English.
- [ ] No countable string is built via raw `'$n cells'`-style concatenation.

## Dependencies

- ZOD-L10-001

## Specification References

- L-10

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
