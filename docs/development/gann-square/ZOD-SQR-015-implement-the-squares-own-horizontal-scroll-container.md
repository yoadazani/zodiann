# ZOD-SQR-015 - Implement the square's own horizontal-scroll container

## Metadata

- **ID:** ZOD-SQR-015
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

When the square is wider than the available width, it scrolls horizontally inside its own panel — the page itself must never scroll sideways.

## Implementation Details

- Scrollable container wraps only the square canvas, independent of the page's vertical scroll.
- Phone: show a "Swipe the square sideways" hint per D14/MASTER.md §8.1.
- Scroll origin starts at the left edge even in the Hebrew interface (ties to [ZOD-SQR-016](../gann-square/ZOD-SQR-016-enforce-ltr-always-rendering-of-the-square.md)'s LTR-always rule).

## Design Reference

`design-reference/zodiann/responsive/mobile/square-of-nine_*` (visible horizontal-scroll affordance/hint); `design-reference/zodiann/MASTER.md` §8.1 "Phone" bullet.

## Acceptance Criteria

- [ ] The page body never scrolls horizontally at any breakpoint (NFR-C2).
- [ ] On phone, the square scrolls sideways within its panel, with the swipe hint shown.
- [ ] Scroll starts at the left edge in both Hebrew and English builds.

## Dependencies

- [ZOD-SQR-014](../gann-square/ZOD-SQR-014-implement-responsive-cell-size-rules.md) — Implement responsive cell-size rules

## Specification References

- SQ-20
- SQ-21
- NFR-C2
- MASTER.md §8.1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
