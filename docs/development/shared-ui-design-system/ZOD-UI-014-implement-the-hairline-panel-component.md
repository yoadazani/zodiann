# ZOD-UI-014 - Implement the hairline panel component

## Metadata

- **ID:** ZOD-UI-014
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done
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

- [x] Panel padding/radius/border matches the token values exactly. (Pixel tests in both themes at 1440 and 390, the UI-003 spacing test on the real widget, and a comparison with the settings reference; see Completion notes.)
- [x] No drop shadow renders in the dark theme except on floating layers (drawer/dialog/toast), per MASTER.md §4 "Elevation".

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §1, §4

## Notes

- **Layout tokens (ZOD-UI-003):** take gutter, panel gap, panel padding and head height from `ZodiannLayout.of(context)`, and the corner from `ZodiannRadius.panel`. Measure as the CSS border-box does: padding sits inside the 1 px border, and the head height includes its 1 px rule (see `packages/shared_ui/test/support/token_panel_harness.dart`).
- **Mobile reference mismatch:** `settings_mobile_he_dark.png` shows a phone panel gap of 20 and a head of 56, because `_source/settings.html` never applies the phone values. MASTER §4's 16 / 52 apply.

- **Buttons in panels (ZOD-UI-004):** focus-ring contract for panel heads, bodies and scrolled content: the button paints its complete focus ring, 4 px beyond the drawn box, whenever no ancestor clips it, and it cannot override an ancestor's clip. Keep at least 4 px of clear, unclipped space around each button wherever the ring can appear; if the layout must clip, adjust its padding so keyboard focus stays visible.


## Completion notes

- **Delivered:** `ZodiannPanel` and `ZodiannPanelHead` (`packages/shared_ui/lib/src/widgets/zodiann_panel.dart`), the `ZodiannSize.hairline` token, and the UI-003 token harness switched to the real widget. Plan: [`docs/plans/ZOD-UI-014-hairline-panel.md`](../../plans/ZOD-UI-014-hairline-panel.md). Owner-approved defaults: no clip unless asked (focus rings stay visible), string `title` / `meta` plus free `leading` / `end`, titles wrap.
- **Criterion 2** holds by construction (no elevation input) and by pixels: a 32 px ring around the panel is all page colour in both themes, and the same scan fails on a panel inside a floating-layer shadow.
- **Not covered:** the panel's content (tables, forms, segmented control) belongs to later tasks; a panel with a head is not for `IntrinsicHeight`.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
