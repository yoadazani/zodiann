# ZOD-WHL-005 - Implement the body display-spread (collision avoidance) algorithm

## Metadata

- **ID:** ZOD-WHL-005
- **Category:** [Zodiac Wheel](../README.md#zodiac-wheel) (`zodiac-wheel/`)
- **Phase:** Phase 2
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

When two or more bodies are closer than the spread threshold, push their **displayed** glyph discs apart while keeping the true position marked on the scale and inner circle (WH-4).

## Implementation Details

- Desktop threshold: bodies closer than 11° are pushed apart. Compact (phone/tablet) threshold: 16°, per `DESIGN_DECISIONS.md` D6, because a phone needs more room — flagged there as **needing approval** since WH-4 only specifies 11°.
- True position must remain exactly marked on the degree scale and the inner-circle dot ([ZOD-WHL-004](../zodiac-wheel/ZOD-WHL-004-render-body-markers-glyph-degree-label-connector-true-position-dot.md)) regardless of how far the display spreads the glyph.
- Algorithm must handle clusters of 3+ close bodies (visible in the reference screenshot: Moon/Sun/Mercury/Venus cluster near Scorpio).

## Design Reference

`design-reference/zodiann/screens/01-zodiac-wheel_desktop_en_dark.png` (the 4-body cluster near the top of the wheel shows the spread result); `design-reference/zodiann/DESIGN_DECISIONS.md` D6 — **flag to the product owner**: the 16° compact threshold is a documented deviation from WH-4's literal 11°, needs approval before this ships as-is.

## Acceptance Criteria

- [ ] A cluster of 4 bodies within a few degrees of each other spreads into distinct, non-overlapping discs, matching the reference screenshot's cluster layout approach.
- [ ] True position (scale tick + inner dot) never moves, only the displayed disc and its connector.
- [ ] Compact threshold (16°) is implemented as a named, documented constant distinct from desktop's 11°, pending D6 approval.

## Dependencies

- [ZOD-WHL-004](../zodiac-wheel/ZOD-WHL-004-render-body-markers-glyph-degree-label-connector-true-position-dot.md) — Render body markers (glyph, degree label, connector, true-position dot)

## Specification References

- WH-4
- DESIGN_DECISIONS.md D6

## Notes

- This task touches an item flagged **needing approval** in `design-reference/zodiann/DESIGN_DECISIONS.md` — confirm the interpretation above with the product owner before implementing.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Zodiac Wheel" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
