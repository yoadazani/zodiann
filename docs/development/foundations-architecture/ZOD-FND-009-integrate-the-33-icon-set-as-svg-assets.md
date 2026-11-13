# ZOD-FND-009 - Integrate the 33-icon set as SVG assets

## Metadata

- **ID:** ZOD-FND-009
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Wire the existing icon set (already fully designed) into the app via `flutter_svg` (or a generated icon font), including the RTL-mirroring rule for directional icons.

## Implementation Details

- Register all 33 SVGs from `design-reference/zodiann/assets/icons/` as app assets.
- Build a thin `AppIcon` widget wrapper so icon usage is consistent (size tokens: 20 in controls, 16 in small buttons/fields, per MASTER.md §4).
- Implement the mirroring rule: `chevL`/`chevR` swap meaning (back/forward) under RTL; `wheel`, `grid`, `rotate`, `datewheel`, `target`, `anchor` never mirror (MASTER.md §11, §13).

## Design Reference

`design-reference/zodiann/assets/icons/*.svg` (all 33 icons, already finalized — 24px grid, 1.6px round stroke); `design-reference/zodiann/MASTER.md` §11 for the mirroring table and §4 for size tokens.

## Acceptance Criteria

- [ ] Every icon renders crisply at both 20px and 16px in light and dark.
- [ ] `chevL`/`chevR` visually swap sides when the app is switched to Hebrew.
- [ ] `wheel`, `grid`, `rotate`, `datewheel`, `target`, `anchor` remain unmirrored under RTL.

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- MASTER.md §11, §13
- L-4

## Notes

- **Buttons (ZOD-UI-004):** pass real icons through `ZodiannButton.icon`; the button lays them out in a 16 × 16 slot (`ZodiannSize.iconSmall`) and tints them with the label colour via `IconTheme`.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
