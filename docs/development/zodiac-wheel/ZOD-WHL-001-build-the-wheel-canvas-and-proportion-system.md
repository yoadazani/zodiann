# ZOD-WHL-001 - Build the wheel canvas and proportion system

## Metadata

- **ID:** ZOD-WHL-001
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Create the `CustomPainter` foundation every other wheel-drawing task paints onto: a single canvas sized to the available space, with every subsequent ring/marker positioned as a fraction of outer radius `R`.

## Implementation Details

- Single `CustomPainter` on a `RepaintBoundary` (ARCH-5), not per-element widgets.
- Implement the desktop vs. compact (phone/tablet) proportion tables from MASTER.md §7.2 as a parameterized scale object (outer halo 1.02R, sign band 0.987R–0.833R desktop / 0.80R compact, etc.) so later tasks just read from it.
- Wrap the painter (and any text drawn on the canvas) in `Directionality(textDirection: TextDirection.ltr)` so the wheel never mirrors under RTL (L-6).
- Longitude increases counterclockwise — bake this orientation convention into the proportion system's angle-to-pixel conversion once, for every later task to reuse.

## Design Reference

`design-reference/zodiann/MASTER.md` §7.2 "The wheel drawing" (complete radius-fraction table for desktop and compact). This task only builds the scaffold; visual content is added by [ZOD-WHL-002](../zodiac-wheel/ZOD-WHL-002-render-the-zodiac-sign-ring.md) through 009.

## Acceptance Criteria

- [ ] A test harness renders the empty proportion grid (rings only, no content) matching the radius fractions in the table at both desktop and compact sizes.
- [ ] The painter never mirrors when the app's text direction is RTL.
- [ ] Rendering uses one `CustomPainter`/`RepaintBoundary`, verified by inspecting the widget tree (no per-degree-tick or per-body widget).

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)
- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)

## Specification References

- ARCH-5
- ARCH-8
- L-6
- MASTER.md §7.2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
