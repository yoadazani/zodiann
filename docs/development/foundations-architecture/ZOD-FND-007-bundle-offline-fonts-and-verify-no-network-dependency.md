# ZOD-FND-007 - Bundle offline fonts and verify no network dependency

## Metadata

- **ID:** ZOD-FND-007
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Ship IBM Plex Sans, IBM Plex Sans Hebrew, and the Noto Sans Symbols families as app assets (TTF/OTF, not the mockup's woff2) so the app works fully offline (DATA-7) and matches the design system's typography.

## Implementation Details

- Source TTF/OTF builds of the families referenced in `design-reference/zodiann/assets/fonts/` (the shipped woff2 files there are for the mockups only, per MASTER.md §3).
- Register them in `pubspec.yaml` with the correct weights (300/400/500/600).
- Verify the app does not request network permission (DATA-7) and that no package declares a runtime fetch of fonts/scripts.

## Design Reference

`design-reference/zodiann/assets/fonts/` (font family and weight list), `design-reference/zodiann/MASTER.md` §3 for the exact family/weight-per-role table. No visual design is invented here — this task only sources production-grade font files equivalent to the mockup fonts.

## Acceptance Criteria

- [ ] All four weight variants of both families render correctly offline (airplane-mode test).
- [ ] Noto Sans Symbols / Symbols 2 cover all glyphs listed in MASTER.md §3's Glyphs row (♈–♓, ☉☽☿♀♂♃♄♅♆♇☊, ℞, aspect glyphs).
- [ ] No network permission is declared in the Android manifest or iOS entitlements.

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- DATA-7
- MASTER.md §3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
