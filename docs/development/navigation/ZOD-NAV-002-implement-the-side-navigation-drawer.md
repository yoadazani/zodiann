# ZOD-NAV-002 - Implement the side navigation drawer

## Metadata

- **ID:** ZOD-NAV-002
- **Category:** [Navigation & App Shell](../README.md#navigation) (`navigation/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the drawer that opens from the hamburger: header, grouped item list, footer, and all open/close interactions.

## Implementation Details

- Opens from the start side at `min(320, 86%)` width, `surface` background, `scrim` backdrop.
- Closes via: tapping the backdrop, the close button, swipe-aside, or the Android back button (NAV-2).
- Header: 76px high, app logo (40px) + "Zodiann" wordmark (20/600, −0.01em) + a close button at the end.
- Items grouped "Analysis" (Wheel, Square) and "Library and app" (Saved, Settings, About); each item shows an icon, name (14/500), description (12, `text-2`) — exact copy from the mockup.
- Active item: `accent-soft` fill, `text` icon/name at full strength, 3px `accent` bar on the start edge, and the accessibility "selected" state (NAV-3).
- Footer: version string + "All data stays on this device".
- On phone the drawer extends to the screen edge and hides content behind it; on large screens it remains an openable (never permanent) drawer with identical behavior (NAV-7).

## Design Reference

`design-reference/zodiann/screens/00-navigation-drawer_desktop_en_dark.png` and `00-navigation-drawer_desktop_he_dark.png` (exact item copy, grouping, active-state styling); `design-reference/zodiann/responsive/mobile/navigation-drawer_mobile_en_dark.png` and `_he_dark.png` for the phone treatment; `design-reference/zodiann/MASTER.md` §5 "Drawer" and `DESIGN_DECISIONS.md` D17 for the grouping rationale.

## Acceptance Criteria

- [ ] Drawer matches `00-navigation-drawer_*` pixel-for-pixel in both languages and both themes.
- [ ] All four close interactions work (backdrop tap, close button, swipe, Android back).
- [ ] Drawer is never rendered as a permanent/always-visible panel at any breakpoint (NAV-7).
- [ ] Active item shows the accessibility "selected" state, verified with a screen reader.

## Dependencies

- [ZOD-NAV-001](../navigation/ZOD-NAV-001-implement-the-sticky-top-bar.md) — Implement the sticky top bar
- [ZOD-FND-008](../foundations-architecture/ZOD-FND-008-package-and-integrate-the-app-icon-logo-asset-set.md) — Package and integrate the app icon / logo asset set
- [ZOD-UI-009](../shared-ui-design-system/ZOD-UI-009-implement-the-tag-component-highlight-tags-mode-tags-today-center.md) — Implement the tag component (highlight tags, mode tags, Today/Center outline tags)

## Specification References

- NAV-2
- NAV-3
- NAV-7
- MASTER.md §5
- DESIGN_DECISIONS.md D17

## Notes

- **Floating layer (ZOD-UI-003):** use `ZodiannElevation.floating` (the theme extension) for the shadow, plus `floatingOutline` (1 px `line`) painted *outside* the box, e.g. as `BoxShadow(color: side.color, spreadRadius: side.width)` after `floating`. The outline applies in both themes (product-owner decision, 2026-11-13).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Navigation & App Shell" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
