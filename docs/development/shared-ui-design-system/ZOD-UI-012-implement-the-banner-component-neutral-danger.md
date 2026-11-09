# ZOD-UI-012 - Implement the banner component (neutral + danger)

## Metadata

- **ID:** ZOD-UI-012
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 2
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the inline banner used for range/ΔT warnings and storage-unavailable messages.

## Implementation Details

- Neutral banner: `accent-soft` fill, `accent-line` border — used for SQ-6 "today out of range" messages and ΔT/date-range warnings (R-2).
- Red/danger banner: used for unavailable storage (NFR-R1).

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Feedback" (banner rows); `design-reference/zodiann/components/components_dark.png`/`_light.png`.

## Acceptance Criteria

- [ ] Both banner variants match the component sheet.
- [ ] Banner text is sourced from localized strings, never hard-coded (L-8).

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- SQ-6
- R-2
- NFR-R1
- MASTER.md §10 "Feedback"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
