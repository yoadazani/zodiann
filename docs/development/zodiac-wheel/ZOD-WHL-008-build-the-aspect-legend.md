# ZOD-WHL-008 - Build the aspect legend

## Metadata

- **ID:** ZOD-WHL-008
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the small legend explaining the three chord colors, positioned beside the readout on desktop and below it on phone.

## Implementation Details

- Three rows: Conjunction (amber line swatch), Sextile/Trine (turquoise), Square/Opposition (red) — exact labels from the mockup.
- Responsive placement per MASTER.md §7.1 (beside readout on desktop, below on phone).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (legend beside the "Under the pointer" readout, bottom-right of the wheel panel); `design-reference/zodiann/DESIGN_DECISIONS.md` D7 for rationale (keeps chords readable without opening About).

## Acceptance Criteria

- [ ] Legend matches the reference screenshot's three rows, colors, and copy.
- [ ] Responsive placement (beside on desktop, below on phone) matches `responsive/mobile/zodiac-wheel_mobile_*`.

## Dependencies

- [ZOD-WHL-007](../zodiac-wheel/ZOD-WHL-007-render-aspect-chords-on-the-inner-disc.md) — Render aspect chords on the inner disc
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- WH-6
- DESIGN_DECISIONS.md D7
- MASTER.md §7.1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
