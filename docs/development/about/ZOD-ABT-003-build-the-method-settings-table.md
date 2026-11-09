# ZOD-ABT-003 - Build the Method settings table

## Metadata

- **ID:** ZOD-ABT-003
- **Category:** [About & Sources](../README.md#about) (`about/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the table documenting the fixed computation parameters (viewpoint, position type, reference frame, node, time, date range, retrograde rule).

## Implementation Details

- Rows exactly mirror "Computation settings that must be fixed and documented": Viewpoint (Geocentric), Position type (Apparent), Reference frame (Ecliptic and equinox of date, tropical, no extra precession), Lunar node (Mean), Time (local → UTC → terrestrial time via ΔT), Date range (per packaged files, pulls the value decided in [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md)), Retrograde (by sign of speed).
- Where the spec leaves a value open (e.g., exact date range), show the spec's own non-invented phrasing ("the coverage of the packaged data files") per D22's explicit no-invented-specifics rule, until [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md)'s decision is finalized and can replace it with a concrete range.

## Design Reference

`design-reference/zodiann/screens/05-about-sources_desktop_en_dark.png` "Method settings" table; `design-reference/zodiann/DESIGN_DECISIONS.md` D22.

## Acceptance Criteria

- [ ] Table content matches the spec's computation-settings table exactly, including the currently-active ephemeris source/node-type reflecting live settings (per the spec's "the active type is shown clearly in the table and in the export" note).
- [ ] No invented specific value appears where the spec/design intentionally left one open (D22).

## Dependencies

- [ZOD-ABT-001](../about/ZOD-ABT-001-build-the-about-screen-hero.md) — Build the About screen hero
- [ZOD-FND-011](../foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md) — Decide and document the ephemeris data-file coverage range
- [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md) — Build the "Wheel and computation" panel

## Specification References

- "Computation settings that must be fixed and documented"
- DESIGN_DECISIONS.md D22

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "About & Sources" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
