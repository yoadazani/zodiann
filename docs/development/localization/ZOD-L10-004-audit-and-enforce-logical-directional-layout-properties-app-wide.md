# ZOD-L10-004 - Audit and enforce logical (directional) layout properties app-wide

## Metadata

- **ID:** ZOD-L10-004
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 4
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Ensure every layout in the app uses `EdgeInsetsDirectional`/`AlignmentDirectional` (or equivalent logical properties) rather than physical left/right, so RTL flips automatically.

## Implementation Details

- Code-review/lint pass across every screen built in `navigation/` through `settings-persistence/` specifically hunting for physical `EdgeInsets.only(left: ...)`-style usage that should be directional.
- The two explicit, deliberate exceptions (wheel drawing, square drawing) are excluded from this audit — they're handled by [ZOD-WHL-001](../zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md)/[ZOD-SQR-016](../gann-square/ZOD-SQR-016-enforce-ltr-always-rendering-of-the-square.md)'s explicit LTR-always wrapping, not by this general rule.

## Design Reference

No direct design reference applies to the rule itself; correctness is verified against every `_he_` vs `_en_` screenshot pair in `design-reference/zodiann/screens/` and `responsive/`.

## Acceptance Criteria

- [ ] No physical-direction layout property remains outside the two documented exceptions.
- [ ] Every screen's Hebrew rendering is a correct mirror of its English rendering (drawer side, panel order, table column order, text alignment, selected-row edge).

## Dependencies

- [ZOD-NAV-001](../navigation/ZOD-NAV-001-implement-the-sticky-top-bar.md) — Implement the sticky top bar
- [ZOD-NAV-002](../navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md) — Implement the side navigation drawer
- [ZOD-WHL-025](../zodiac-wheel/ZOD-WHL-025-implement-responsive-wheel-screen-layout-desktop-tablet-phone.md) — Implement responsive wheel-screen layout (desktop/tablet/phone)
- [ZOD-SQR-020](../gann-square/ZOD-SQR-020-implement-responsive-square-screen-layout-desktop-tablet-portrait.md) — Implement responsive square-screen layout (desktop/tablet-portrait/tablet-landscape/phone)
- [ZOD-SET-001](../settings-persistence/ZOD-SET-001-build-the-settings-screen-panel-layout.md) — Build the Settings screen panel layout
- [ZOD-DAT-001](../settings-persistence/ZOD-DAT-001-build-the-saved-squares-list-screen.md) — Build the Saved squares list screen

## Specification References

- L-5
- MASTER.md §13

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
