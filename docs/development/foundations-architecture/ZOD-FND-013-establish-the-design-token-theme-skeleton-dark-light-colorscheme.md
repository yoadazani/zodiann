# ZOD-FND-013 - Establish the design-token theme skeleton (dark + light `ColorScheme`)

## Metadata

- **ID:** ZOD-FND-013
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done
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

- [x] Both themes compile and can be toggled at runtime with no visual regression (blank screen is fine at this stage). Evidence: `packages/shared_ui/test/theme/zodiann_theme_test.dart`; `apps/astro_mobile/test/theme_switch_test.dart` (device default, set dark/light/system without restart, mid-animation `lerp`); the 13 FND-005 tests unchanged; emulator-5554 light (unchanged from FND-005) and dark screenshots.
- [x] No component file in the codebase contains a raw hex color literal (enforced by lint or review). Enforced automatically: `test/architecture/no_color_literals_test.dart` (runs in `melos run test`; only `packages/shared_ui/lib/src/theme/tokens/` may hold literals).

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- ARCH-7
- MASTER.md §2

## Notes

Plan: `docs/plans/ZOD-FND-013-theme-token-skeleton.md`.

- **Product-owner decision (2026-11-13):** token values are placeholders derived from Material's default `ColorScheme` (no literals); ZOD-UI-001 fills MASTER.md §2's exact values. `signTintOpacity` already carries MASTER's 0.10 / 0.09.
- **Where things live:** the theme is in `packages/shared_ui` (feature packages can import it). Values live only in `packages/shared_ui/lib/src/theme/tokens/`.
- **`themeModeProvider`** (`apps/astro_mobile/lib/src/theme/`) is an app-level placeholder, not a contract for feature packages; ZOD-SET-003 / SET-007 decide where the picker's provider contract lives and persist the choice.
- **Flutter 3.50:** import `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
