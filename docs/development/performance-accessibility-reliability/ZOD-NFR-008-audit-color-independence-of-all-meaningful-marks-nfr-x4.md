# ZOD-NFR-008 - Audit color-independence of all meaningful marks (NFR-X4)

## Metadata

- **ID:** ZOD-NFR-008
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Systematic audit (not just the individual component tasks' own acceptance criteria) that no meaningful state in the app is conveyed by color alone.

## Implementation Details

- Run the whole app through a color-blindness simulator (protanopia/deuteranopia/tritanopia) and confirm every previously-color-coded distinction (square highlights, aspect chords, body identity, retrograde) remains distinguishable via its non-color mark (+ /×, glyph, ℞ text).

## Design Reference

No direct design reference applies — verifies the already-built non-color marks from [ZOD-SQR-007](../gann-square/ZOD-SQR-007-render-non-color-highlight-marks-and.md), [ZOD-WHL-004](../zodiac-wheel/ZOD-WHL-004-render-body-markers-glyph-degree-label-connector-true-position-dot.md), [ZOD-WHL-006](../zodiac-wheel/ZOD-WHL-006-render-the-retrograde-indicator.md), [ZOD-UI-009](../shared-ui-design-system/ZOD-UI-009-implement-the-tag-component-highlight-tags-mode-tags-today-center.md).

## Acceptance Criteria

- [ ] NFR-X4 passes under simulated color-blindness for every previously color-coded element in the app.

## Dependencies

- [ZOD-SQR-007](../gann-square/ZOD-SQR-007-render-non-color-highlight-marks-and.md) — Render non-color highlight marks (+ and ×)
- [ZOD-WHL-004](../zodiac-wheel/ZOD-WHL-004-render-body-markers-glyph-degree-label-connector-true-position-dot.md) — Render body markers (glyph, degree label, connector, true-position dot)
- [ZOD-WHL-006](../zodiac-wheel/ZOD-WHL-006-render-the-retrograde-indicator.md) — Render the retrograde indicator (℞)
- [ZOD-WHL-007](../zodiac-wheel/ZOD-WHL-007-render-aspect-chords-on-the-inner-disc.md) — Render aspect chords on the inner disc
- [ZOD-UI-009](../shared-ui-design-system/ZOD-UI-009-implement-the-tag-component-highlight-tags-mode-tags-today-center.md) — Implement the tag component (highlight tags, mode tags, Today/Center outline tags)

## Specification References

- NFR-X4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
