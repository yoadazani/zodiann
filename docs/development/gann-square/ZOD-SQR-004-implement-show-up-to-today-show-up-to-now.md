# ZOD-SQR-004 - Implement "Show up to today" / "Show up to now"

## Metadata

- **ID:** ZOD-SQR-004
- **Category:** [Gann Square of Nine](../README.md#gann-square) (`gann-square/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the button that computes today's cell, sizes the square to contain it, selects it, and scrolls to it — with its two failure messages.

## Implementation Details

- Label is "Show up to today" in dates mode, "Show up to now" in date-and-time mode.
- Computes today's/now's cell number from the anchor ([ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md)'s "cell of today"), picks the smallest valid square size that contains that cell, selects it, and scrolls the square view to center it.
- If the anchor is after today/now: show a message instead of resizing (SQ-6).
- If today/now is further than 3,721 cells away: size stops at the maximum (61×61) and a message is shown (SQ-6).
- Hidden entirely in numbers mode (no "today" concept applies — consistent with [ZOD-SQR-002](../gann-square/ZOD-SQR-002-build-the-anchor-field-and-anchor-to-today-now-shortcut.md)/D15).

## Design Reference

`design-reference/zodiann/screens/02-square-of-nine_dates_desktop_en_dark.png` "Show up to today" button (accent outline); `design-reference/zodiann/MASTER.md` §10 "Feedback" for the neutral-banner message treatment (reused from [ZOD-UI-012](../shared-ui-design-system/ZOD-UI-012-implement-the-banner-component-neutral-danger.md)).

## Acceptance Criteria

- [ ] With a past anchor, tapping the button resizes, selects, and scrolls to today's cell.
- [ ] With a future anchor, a message is shown and no resize happens.
- [ ] With today more than 3,721 cells away, size caps at 61×61 and a message explains the cap.

## Dependencies

- [ZOD-SQR-002](../gann-square/ZOD-SQR-002-build-the-anchor-field-and-anchor-to-today-now-shortcut.md) — Build the anchor field and "Anchor to today/now" shortcut
- [ZOD-SQR-003](../gann-square/ZOD-SQR-003-build-the-square-size-selector-presets-custom.md) — Build the square-size selector (presets + custom)
- [ZOD-GAN-003](../computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) — Implement Gann date/number mapping per mode
- [ZOD-UI-012](../shared-ui-design-system/ZOD-UI-012-implement-the-banner-component-neutral-danger.md) — Implement the banner component (neutral + danger)

## Specification References

- SQ-6

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Gann Square of Nine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
