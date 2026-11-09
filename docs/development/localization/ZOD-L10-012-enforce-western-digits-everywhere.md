# ZOD-L10-012 - Enforce Western digits everywhere

## Metadata

- **ID:** ZOD-L10-012
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 4
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Confirm no numeric display ever substitutes non-Western digit glyphs (e.g., Eastern Arabic numerals that some locale formatters default to), in either language.

## Implementation Details

- Explicitly pin the `intl` number/date formatters to Western digits regardless of locale defaults.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A spot-check of every numeric display in the Hebrew build shows only 0–9 Western digits.

## Dependencies

- ZOD-L10-001

## Specification References

- L-14

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
