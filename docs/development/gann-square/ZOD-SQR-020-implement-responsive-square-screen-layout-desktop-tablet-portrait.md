# ZOD-SQR-020 - Implement responsive square-screen layout (desktop/tablet-portrait/tablet-landscape/phone)

## Metadata

- **ID:** ZOD-SQR-020
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Arrange the controls panel, square, and details panel per breakpoint, including the tablet-portrait interpretation flagged as needing approval.

## Implementation Details

- Desktop: grid `1fr | 360`, square on the start side, details panel floats sticky beside it.
- Tablet **landscape**: same desktop rule.
- Tablet **portrait**: details become a full-width strip *above* the square (number column 240px, then a 4-column detail grid) — per D14, this applies the phone rule in a wider strip because a 13×13 square plus a 360px side panel doesn't fit in 834px. **Flagged needing approval** as an interpretation of "wide screen" (SQ-16 only defines "wide screen: beside" / "phone: above").
- Phone: details above the square in a single column; square scrolls horizontally in its panel ([ZOD-SQR-015](../gann-square/ZOD-SQR-015-implement-the-squares-own-horizontal-scroll-container.md)).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_*_desktop_*`, `responsive/tablet/square-of-nine_*_tablet-landscape_*` and `_tablet_*` (portrait), `responsive/mobile/square-of-nine_*`; `design-reference/zodiann/DESIGN_DECISIONS.md` D14.

## Acceptance Criteria

- [ ] Each breakpoint's layout matches its corresponding screenshot.
- [ ] Tablet-portrait specifically matches D14's "phone rule in a wider strip" interpretation, flagged in any design review as pending explicit approval.

## Dependencies

- [ZOD-SQR-010](../gann-square/ZOD-SQR-010-implement-cell-tap-to-select-and-details-panel-wiring.md) — Implement cell tap-to-select and details-panel wiring
- [ZOD-SQR-012](../gann-square/ZOD-SQR-012-build-cell-details-core-fields.md) — Build cell details: core fields
- [ZOD-SQR-013](../gann-square/ZOD-SQR-013-build-cell-details-date-mode-fields.md) — Build cell details: date-mode fields
- [ZOD-SQR-015](../gann-square/ZOD-SQR-015-implement-the-squares-own-horizontal-scroll-container.md) — Implement the square's own horizontal-scroll container

## Specification References

- SQ-16
- DESIGN_DECISIONS.md D14
- MASTER.md §8.1

## Notes

- This task touches an item flagged **needing approval** in `design-reference/zodiann/DESIGN_DECISIONS.md` — confirm the interpretation above with the product owner before implementing.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
