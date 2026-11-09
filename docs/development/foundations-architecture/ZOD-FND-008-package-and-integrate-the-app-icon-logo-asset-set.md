# ZOD-FND-008 - Package and integrate the app icon / logo asset set

## Metadata

- **ID:** ZOD-FND-008
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Wire the existing logo artwork (already fully designed — not to be redesigned) as the launcher icon and the three in-app variants.

## Implementation Details

- Launcher icon: `design-reference/zodiann/assets/zodiann-logo.svg` (the tiled mark, corner radius 22%), rendered per-platform at the required launcher sizes.
- In-app dark-surface mark: `assets/zodiann-logo-on-dark.svg` (tile removed).
- In-app light-surface mark: `assets/zodiann-logo-on-light.svg` (deepened gradient `#be598e #826cc3 #1ba5ba`, empty cells at 6% black instead of 6% white).
- Never render the logo below 40px (hairlines blur at small raster sizes per MASTER.md §11).
- Use the PNG renders at 1024px as a high-resolution fallback where SVG isn't practical.

## Design Reference

`design-reference/zodiann/assets/zodiann-logo*.svg` and matching `.png` files; `design-reference/zodiann/MASTER.md` §11 "Iconography and assets" for sizing and placement rules; `design-reference/zodiann/DESIGN_DECISIONS.md` D5a for the rationale. This asset is fully specified — no design work remains, only integration.

## Acceptance Criteria

- [ ] Launcher icon renders correctly at all required iOS/Android sizes.
- [ ] Drawer header (40px), About hero (132px) use the correct dark/light variant automatically with theme.
- [ ] No instance of the logo renders below 40px anywhere in the app.

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- MASTER.md §11
- DESIGN_DECISIONS.md D5a

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
