# ZOD-NFR-002 - Measure and tune wheel drag frame rate

## Metadata

- **ID:** ZOD-NFR-002
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Profile and, if necessary, optimize wheel-rotation drag performance with all 11 bodies and aspect chords visible, on a mid-range device.

## Implementation Details

- Use Flutter DevTools' frame-rendering profiler during a sustained drag gesture with the maximum visual load (all bodies + all possible aspect chords shown).
- If frame drops are found, optimize the `CustomPainter` (e.g., avoid unnecessary `shouldRepaint` triggers, cache static ring geometry).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] NFR-P1 passes: frame rate measured on a mid-range device shows no visible jumps during a full-load drag.

## Dependencies

- [ZOD-WHL-010](../zodiac-wheel/ZOD-WHL-010-implement-wheel-rotation-via-drag-rotate-wheel-mode.md) — Implement wheel rotation via drag (rotate-wheel mode)
- [ZOD-WHL-004](../zodiac-wheel/ZOD-WHL-004-render-body-markers-glyph-degree-label-connector-true-position-dot.md) — Render body markers (glyph, degree label, connector, true-position dot)
- [ZOD-WHL-007](../zodiac-wheel/ZOD-WHL-007-render-aspect-chords-on-the-inner-disc.md) — Render aspect chords on the inner disc

## Specification References

- NFR-P1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
