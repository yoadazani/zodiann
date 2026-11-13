# ZOD-UI-014 - Implement the hairline panel component

## Metadata

- **ID:** ZOD-UI-014
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the base panel shell (border + radius + padding + optional 56/52px head) that every screen's content sections sit inside, per the "hairlines over boxes" design direction.

## Implementation Details

- 1px border rules, 12px radius, no shadows in dark theme.
- Panel padding 20 (desktop/tablet) / 16 (phone); panel head height 56 (phone 52).
- Panels are never stacked as identical cards — content density and hierarchy come from spacing and hairlines, not elevation.

## Design Reference

`design-reference/zodiann/MASTER.md` §1 "Concept" ("Hairlines over boxes") and §4 "Spacing, radius, elevation, sizing"; visible throughout every screen in `design-reference/zodiann/screens/`.

## Acceptance Criteria

- [ ] Panel padding/radius/border matches the token values exactly.
- [ ] No drop shadow renders in the dark theme except on floating layers (drawer/dialog/toast), per MASTER.md §4 "Elevation".

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §1, §4

## Notes

- **Layout tokens (ZOD-UI-003):** take gutter, panel gap, panel padding and head height from `ZodiannLayout.of(context)`, and the corner from `ZodiannRadius.panel`. Measure as the CSS border-box does: padding sits inside the 1 px border, and the head height includes its 1 px rule (see `packages/shared_ui/test/support/token_panel_harness.dart`).
- **Mobile reference mismatch:** `settings_mobile_he_dark.png` shows a phone panel gap of 20 and a head of 56, because `_source/settings.html` never applies the phone values. MASTER §4's 16 / 52 apply.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
