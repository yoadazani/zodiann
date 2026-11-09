# ZOD-FND-013 - Establish the design-token theme skeleton (dark + light `ColorScheme`)

## Metadata

- **ID:** ZOD-FND-013
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Create the Flutter theming scaffold (`ColorScheme` + `ThemeExtension`s) that every component in `shared-ui-design-system/` plugs its colors into. This task creates the *structure*; [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) fills in the actual token values.

## Implementation Details

- Define empty/typed `ThemeExtension` classes: `ZodiannSurfaces`, `SquareColors`, `ZodiacColors`, `AspectColors`, `BodyColors`, exactly as MASTER.md §2 groups them.
- Wire both a dark (`Graphite`) and light (`Porcelain`) `ThemeData`, switchable at runtime, with no hard-coded colors permitted in any component (ARCH-7).
- Add a lint/CI check (or code-review checklist item) that flags raw hex colors outside the theme files.

## Design Reference

`design-reference/zodiann/MASTER.md` §2 "Colour tokens" defines the full token taxonomy (structure only here — values filled in [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md)).

## Acceptance Criteria

- [ ] Both themes compile and can be toggled at runtime with no visual regression (blank screen is fine at this stage).
- [ ] No component file in the codebase contains a raw hex color literal (enforced by lint or review).

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- ARCH-7
- MASTER.md §2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
