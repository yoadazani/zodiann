# ZOD-SET-008 - Implement reliability behavior for invalid settings input

## Metadata

- **ID:** ZOD-SET-008
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Ensure every settings input (orb steppers, step-hours field, custom values) rejects invalid input with a clear message rather than crashing (NFR-R2).

## Implementation Details

- Bound-check every numeric settings field against its documented valid range.
- Reuse the input-component error state ([ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md)) for inline messages.

## Design Reference

No direct design reference applies beyond the already-specified input error state ([ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md)).

## Acceptance Criteria

- [ ] An out-of-range value in any settings numeric field shows an inline error and does not corrupt the stored setting.

## Dependencies

- [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md) — Build the "Wheel and computation" panel
- [ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) — Implement the input/field component

## Specification References

- NFR-R2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
