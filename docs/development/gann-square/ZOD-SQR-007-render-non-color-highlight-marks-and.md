# ZOD-SQR-007 - Render non-color highlight marks (+ and ×)

## Metadata

- **ID:** ZOD-SQR-007
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Draw the small corner glyph that lets highlights be distinguished without relying on color alone (NFR-X4).

## Implementation Details

- 9px glyph in the cell's top-end corner (logical "end," flips under RTL cell-content orientation — though the square itself never mirrors, per SQ-21/[ZOD-SQR-016](../gann-square/ZOD-SQR-016-enforce-ltr-always-rendering-of-the-square.md), so confirm this corner is consistently the same physical corner in both languages) at 70% opacity.
- `+` marks an axis cell (blue), `×` marks a diagonal cell (yellow); an eighth (gray) carries no glyph, relying on its distinct lighter neutral fill instead.

## Design Reference

`design-reference/zodiann/components/components_dark.png` "Square of Nine cells" (visible + and × marks on sample cells); `design-reference/zodiann/DESIGN_DECISIONS.md` D10 for the rationale (marks echo the meaning: + is the cross of the axes, × the diagonals).

## Acceptance Criteria

- [ ] Every blue cell shows a + mark; every yellow cell shows a ×; gray cells show neither.
- [ ] Marks remain legible (70% opacity, correct contrast) in both themes (NFR-X5).
- [ ] Since the square never mirrors (SQ-21), the mark's corner position is identical in Hebrew and English builds.

## Dependencies

- [ZOD-SQR-006](../gann-square/ZOD-SQR-006-render-highlight-fills-blue-yellow-gray-on-the-square-canvas.md) — Render highlight fills (blue/yellow/gray) on the square canvas

## Specification References

- NFR-X4
- DESIGN_DECISIONS.md D10
- SQ-21

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
