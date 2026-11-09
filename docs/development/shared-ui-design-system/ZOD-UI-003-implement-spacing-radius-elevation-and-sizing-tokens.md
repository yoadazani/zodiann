# ZOD-UI-003 - Implement spacing, radius, elevation, and sizing tokens

## Metadata

- **ID:** ZOD-UI-003
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Centralize the spacing scale, radius scale, elevation treatment, and standard control heights as reusable constants/extensions.

## Implementation Details

- Spacing scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, with documented gutter/gap/padding values per breakpoint (24/16 gutter, 20/16 panel gap, 20/16 panel padding, 56/52 panel head height).
- Radius scale: 3 (cell frame, legend swatches), 6 (tags, segment thumbs), 8 (buttons, inputs), 12 (panels), 16 (dialogs), pill (chips) — square cells themselves get no radius.
- Elevation: dark theme lightens surfaces instead of shadows; floating layers (drawer, dialog, toast) get `0 24 64 rgba(0,0,0,.55)` + 1px `line` outline (dark) or `0 24 56 rgba(21,25,31,.18)` (light).
- Control heights: buttons/inputs 40 (small 32), segment thumbs 32 in a 3px track, table rows 44, hamburger/icon buttons 46×46 (small icon buttons 36), play button 48 circle, switch 40×24, orb stepper 36.
- Icon sizes: 20 in controls, 16 in small buttons/fields.

## Design Reference

`design-reference/zodiann/MASTER.md` §4 "Spacing, radius, elevation, sizing" (complete token tables).

## Acceptance Criteria

- [ ] All spacing/radius/elevation/sizing constants are defined once and referenced everywhere (no magic numbers in feature code).
- [ ] A measured screenshot of a built panel matches the specified padding/gap values within 1px.

## Dependencies

- [ZOD-FND-013](../foundations-architecture/ZOD-FND-013-establish-the-design-token-theme-skeleton-dark-light-colorscheme.md) — Establish the design-token theme skeleton (dark + light `ColorScheme`)

## Specification References

- MASTER.md §4
- ARCH-8

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
