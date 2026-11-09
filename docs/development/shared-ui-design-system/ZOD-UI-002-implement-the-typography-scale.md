# ZOD-UI-002 - Implement the typography scale

## Metadata

- **ID:** ZOD-UI-002
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the `TextTheme`/text-style set for every role in the type scale, with the correct family, weight, size, line-height, and tracking.

## Implementation Details

- Implement all roles from MASTER.md §3's table: Hero wordmark, Display readout, Section title, Wordmark (drawer), Screen title, Panel title, Body, Small, Label, Micro, Glyphs — each with its exact size/line-height/weight/tracking and phone-size variant where specified.
- Apply `FontFeature.tabularFigures()` to every style used for degree/date/number columns.
- Append U+FE0E (text presentation selector) to every astrological glyph string so no platform substitutes an emoji rendering.
- Font family resolution: IBM Plex Sans for Latin, IBM Plex Sans Hebrew for Hebrew (which also covers Latin, so it's the whole UI family in Hebrew mode).
- Enforce sentence case everywhere (no all-caps, no letter-spaced eyebrows) as a convention, not a per-string choice.

## Design Reference

`design-reference/zodiann/MASTER.md` §3 "Typography" (complete role table). Cross-check rendered output against `design-reference/zodiann/components/components_dark.png` "Typography" section, which shows each role in both English and Hebrew side by side.

## Acceptance Criteria

- [ ] Every role in the table renders at the correct size/weight/tracking in a test harness.
- [ ] Tabular figures are verified on a changing-digit-width test (e.g., cycling 0–9 in one column causes no horizontal jitter).
- [ ] No astrological glyph renders as a color emoji on any tested platform/font configuration.

## Dependencies

- [ZOD-FND-007](../foundations-architecture/ZOD-FND-007-bundle-offline-fonts-and-verify-no-network-dependency.md) — Bundle offline fonts and verify no network dependency
- [ZOD-FND-013](../foundations-architecture/ZOD-FND-013-establish-the-design-token-theme-skeleton-dark-light-colorscheme.md) — Establish the design-token theme skeleton (dark + light `ColorScheme`)

## Specification References

- MASTER.md §3
- L-13
- L-14

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
