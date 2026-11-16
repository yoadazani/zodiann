# ZOD-NAV-001 - Implement the sticky top bar

## Metadata

- **ID:** ZOD-NAV-001
- **Category:** [Navigation & App Shell](../README.md#navigation) (`navigation/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done
- **Scope:** MVP

## Description

Build the top bar every screen sits under: hamburger, title/subtitle, and screen-specific actions.

## Implementation Details

- Sticky, 64px high (phone 60), `bg` at 88% opacity with a 10px blur and a `line-soft` bottom rule.
- Order from the start side: hamburger (46×46, NAV-1), then title (18/600) over subtitle (12, `text-2`), then screen actions at the end.
- Screen actions: Square screen shows **Save** (secondary) + **Export to Excel** (primary) on desktop/tablet, collapsing to two icon buttons (download, bookmark) on phone.
- The whole bar mirrors under RTL using logical (`Directional`) layout, not manual left/right swapping.

## Design Reference

`design-reference/zodiann/MASTER.md` §5 "Shell and navigation"; visible at the top of every screen in `design-reference/zodiann/screens/*` and `responsive/mobile/*` — compare the EN/HE pairs to confirm correct mirroring.

## Acceptance Criteria

- [x] Hamburger button is ≥46×46 logical pixels (NAV-1).
- [x] Bar mirrors correctly in Hebrew (hamburger moves to the right, title/subtitle and actions reorder).
- [x] On phone, square-screen actions collapse to the two icon buttons shown in `responsive/mobile/square-of-nine_*`.

## Dependencies

- [ZOD-FND-014](../foundations-architecture/ZOD-FND-014-set-up-go-router-navigation-scaffold.md) — Set up `go_router` navigation scaffold
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens
- [ZOD-UI-004](../shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md) — Implement the button components (primary, secondary, accent-outline, quiet, danger) and their states
- [ZOD-FND-009](../foundations-architecture/ZOD-FND-009-integrate-the-33-icon-set-as-svg-assets.md) — Integrate the 33-icon set as SVG assets

## Specification References

- NAV-1
- MASTER.md §5

## Notes

- **Surface tint (ZOD-UI-003):** if the top bar builds on `AppBar`, set `surfaceTintColor: Colors.transparent` (or an `appBarTheme`). `AppBar` is the one Material 3 component whose scrolled-under state falls back to `colorScheme.surfaceTint`, which is the accent in both Zodiann themes.

- **Icon buttons (ZOD-UI-004):** follow the button state model: `ZodiannStates` (hover brightness 1.12 over 150 ms, pressed 0.94 + 1 px down, disabled 0.42), the keyboard-only 2 px `focus` ring at offset 2 (`ZodiannFocusRingPainter` pattern) and a ≥ 44 × 44 hit target.
- **From ZOD-FND-014:**
  - **Active screen:** comes from the router's location → `AppRoute`.
  - **Drawer items:** iterate `AppRoute.values` (table order).
  - **Contract:** if the bar or drawer is built in `shared_ui`, decide here where the feature-accessible route contract lives. `shared_ui` and the feature packages never import the app layer.
- **Implementation (2026-11-16, product-owner decisions of 2026-11-15):**
  - **Architecture:** `ZodiannTopBar` in `shared_ui` is route-independent, so the route-contract decision passes to NAV-002 or DAT-005. The app's `AppShell` (one go_router `ShellRoute` over all five routes) maps routes to titles, subtitles and actions. The body extends behind the bar.
  - **Shared behaviour:** `ZodiannPressable` holds UI-004's interaction layer, extracted unchanged, and both `ZodiannButton` and the new 46 × 46 `ZodiannIconButton` (plain / boxed) use it.
  - **Option B:** the hamburger (→ NAV-002), Save (→ the saved-squares task) and Export (→ the Excel task) are visible but disabled.
  - **Subtitle weight 400**, as kit.css and the mockups draw it. MASTER §3's Label role lists 500 for subtitles; MASTER is not edited.
  - **Hover on a transparent icon button:** UI-004's `brightness(1.12)` only lifts the icon, which is barely visible on dark `text`. This follows "UI-004's behaviour exactly"; kit.css's `.icon-btn:hover` `surface-2` background is not used.
  - **Also:**
    - bar text clamps at 1.5 ×;
    - phone end padding is 8 with actions and 16 without;
    - the bar keeps its controls clear of side safe-area insets (a landscape notch).
  - **Plan:** [`docs/plans/ZOD-NAV-001-sticky-top-bar.md`](../../plans/ZOD-NAV-001-sticky-top-bar.md).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Navigation & App Shell" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
