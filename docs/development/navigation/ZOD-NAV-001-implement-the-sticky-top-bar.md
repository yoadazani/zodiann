# ZOD-NAV-001 - Implement the sticky top bar

## Metadata

- **ID:** ZOD-NAV-001
- **Category:** [Navigation & App Shell](../README.md#navigation) (`navigation/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
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

- [ ] Hamburger button is ≥46×46 logical pixels (NAV-1).
- [ ] Bar mirrors correctly in Hebrew (hamburger moves to the right, title/subtitle and actions reorder).
- [ ] On phone, square-screen actions collapse to the two icon buttons shown in `responsive/mobile/square-of-nine_*`.

## Dependencies

- [ZOD-FND-014](../foundations-architecture/ZOD-FND-014-set-up-go-router-navigation-scaffold.md) — Set up `go_router` navigation scaffold
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens
- [ZOD-UI-004](../shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md) — Implement the button components (primary, secondary, accent-outline, quiet, danger) and their states
- [ZOD-FND-009](../foundations-architecture/ZOD-FND-009-integrate-the-33-icon-set-as-svg-assets.md) — Integrate the 33-icon set as SVG assets

## Specification References

- NAV-1
- MASTER.md §5

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Navigation & App Shell" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
