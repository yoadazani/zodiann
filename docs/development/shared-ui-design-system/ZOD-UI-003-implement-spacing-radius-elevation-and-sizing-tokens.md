# ZOD-UI-003 - Implement spacing, radius, elevation, and sizing tokens

## Metadata

- **ID:** ZOD-UI-003
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Done
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

- [x] All spacing/radius/elevation/sizing constants are defined once and referenced everywhere (no magic numbers in feature code).
- [x] A measured screenshot of a built panel matches the specified padding/gap values within 1px.

## Dependencies

- [ZOD-FND-013](../foundations-architecture/ZOD-FND-013-establish-the-design-token-theme-skeleton-dark-light-colorscheme.md) — Establish the design-token theme skeleton (dark + light `ColorScheme`)

## Specification References

- MASTER.md §4
- ARCH-8

## Notes

- **Light outline — product-owner decision (2026-11-13):** the 1 px `line` outline applies to floating layers in **both** themes, not only dark (the "(dark)" above reads too narrowly). MASTER gives the outline to floating layers as a class and replaces only the shadow for light; `kit.css:72` draws it in light too. The reference draws it as a ring *outside* the box (`0 0 0 1px`), so consumers paint `ZodiannElevation.floatingOutline` outside (see its doc comment).
- **MASTER over kit.css for the shadows:** kit.css has `rgba(0,0,0,.6)` / `rgba(11,12,14,.16)`; MASTER's `.55` / `rgba(21,25,31,.18)` are used, as in UI-001/UI-002.
- **CSS blur → Flutter:** CSS blur = 2σ and Flutter maps `blurRadius` r to σ = r × 0.57735 + 0.5, so `ZodiannElevation.blurFromCss` converts (64 → 54.5596, 56 → 47.6314). The test pins σ (32 / 28).
- **Border-box measurement:** panel padding is counted inside the 1 px border, and the head height (56 / 52) includes its 1 px rule (`kit.css`: `box-sizing: border-box`).
- **Mobile reference mismatch:** `settings_mobile_he_dark.png` shows a phone panel gap of 20 and head of 56, because `_source/settings.html` never applies the phone values. MASTER's 16 / 52 win; the reference test checks only the phone gutter and padding. Phone is < 700 (MASTER §6), not `max-width: 700px`.
- **Criterion 1 mechanism:** the constants live only in `packages/shared_ui/lib/src/theme/tokens/` (`ZodiannSpace`, `ZodiannRadius`, `ZodiannSize`, `ZodiannBreakpoints`), plus `ZodiannLayout` and `ZodiannElevation`. `test/architecture/no_magic_dimensions_test.dart` flags numeric layout literals in `apps/*/lib` and `packages/*/lib` outside `tokens/`. Its documented gaps (in `dimension_literals.dart`) include `Container(width/height)`, `Divider`, flex factors, `Offset(...)` and default parameter values.
- **Surface tint:** no change in UI-003. Material 3 defaults set a transparent tint everywhere except `AppBar`, which falls back to `colorScheme.surfaceTint` (the accent); handed to ZOD-NAV-001 in its Notes.
- **Criterion 2 evidence:** `packages/shared_ui/test/theme/panel_spacing_test.dart` measures a token-built panel pixel by pixel at 1440 and 390 (exact), and `reference_layout_test.dart` measures the same distances in the settings reference PNGs (within 1 px).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
