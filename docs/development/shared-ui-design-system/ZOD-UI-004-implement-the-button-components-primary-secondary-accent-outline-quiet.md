# ZOD-UI-004 - Implement the button components (primary, secondary, accent-outline, quiet, danger) and their states

## Metadata

- **ID:** ZOD-UI-004
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the five button variants and their five interaction states exactly as specified.

## Implementation Details

- Primary: `accent` fill, `on-accent` text, weight 600. Secondary: `surface-2` + `line` border (default look). Accent outline: used for time/anchor shortcuts (Now, Show up to today, Anchor to…). Quiet: Cancel. Danger: outline by default, solid inside a confirmation dialog.
- States: hover lightens +12%; focus shows a 2px `focus` ring offset 2; pressed moves 1px down and darkens 6%; disabled is 42% opacity.
- Enforce "at most one primary per region" as a usage convention (documented, reviewed in PRs — not a runtime check).
- 40px height (32 small variant).

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Buttons"; every state is captured in `design-reference/zodiann/components/components_dark.png` and `components_light.png` under "Buttons" (default/hover/press/disabled columns for each variant, plus icon-only variants like the small primary and hamburger).

## Acceptance Criteria

- [ ] All five variants × five states render pixel-matching the component sheet in both themes.
- [ ] Keyboard focus ring is visible and matches the `focus` token.
- [ ] Disabled buttons are non-interactive (no hover/press feedback, 42% opacity).

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Buttons"
- NFR-X5

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
