# ZOD-SQR-017 - Build the compass axis labels around the square

## Metadata

- **ID:** ZOD-SQR-017
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the four edge labels ("90° N" top, "270° S" bottom, "0° W" start, "180° E" end) that put Appendix C's directions directly on the square.

## Implementation Details

- 24px band outside the square on each edge; degree number in `axis` token, direction letter in `text-3`.
- Start/end edges' labels are rotated (per the mockup) and sit on the square's fixed left/right sides (since the square never mirrors — "start"/"end" here means the square's own fixed west/east, not RTL-logical start/end).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` (visible "90° N" top, "270° S" bottom, "0° W" rotated left, "180° E" rotated right); `design-reference/zodiann/MASTER.md` §8.2 "Axis labels"; `design-reference/zodiann/DESIGN_DECISIONS.md` D13 for the rationale (also demonstrates the square doesn't mirror in Hebrew).

## Acceptance Criteria

- [ ] All four labels render at the correct edges with correct rotation, matching the reference screenshot.
- [ ] Labels remain on the same physical edges in both Hebrew and English builds.

## Dependencies

- [ZOD-SQR-016](../gann-square/ZOD-SQR-016-enforce-ltr-always-rendering-of-the-square.md) — Enforce LTR-always rendering of the square
- [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) — Implement Gann highlight classification (blue/yellow/gray)

## Specification References

- Appendix C
- DESIGN_DECISIONS.md D13
- MASTER.md §8.2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
