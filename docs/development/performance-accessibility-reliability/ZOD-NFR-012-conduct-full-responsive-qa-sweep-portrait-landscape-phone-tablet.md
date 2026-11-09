# ZOD-NFR-012 - Conduct full responsive QA sweep (portrait/landscape, phone/tablet)

## Metadata

- **ID:** ZOD-NFR-012
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Verify every screen across every orientation/breakpoint combination against the design reference, as a dedicated sweep distinct from the per-screen responsive tasks.

## Implementation Details

- Walk every screen (`navigation/` through `about/`) at phone portrait, phone landscape, tablet portrait, tablet landscape, and desktop widths.
- Confirm the square's horizontal-scroll-in-its-own-frame rule ([ZOD-SQR-015](../gann-square/ZOD-SQR-015-implement-the-squares-own-horizontal-scroll-container.md)) and tables-never-break-page-width rule hold everywhere, not just the screens that explicitly mocked them.

## Design Reference

Full inventory of `design-reference/zodiann/screens/`, `responsive/mobile/`, `responsive/tablet/`.

## Acceptance Criteria

- [ ] NFR-C2 passes across every screen/orientation/breakpoint combination.
- [ ] No table or panel ever forces page-level horizontal scroll.

## Dependencies

- [ZOD-WHL-025](../zodiac-wheel/ZOD-WHL-025-implement-responsive-wheel-screen-layout-desktop-tablet-phone.md) — Implement responsive wheel-screen layout (desktop/tablet/phone)
- [ZOD-SQR-020](../gann-square/ZOD-SQR-020-implement-responsive-square-screen-layout-desktop-tablet-portrait.md) — Implement responsive square-screen layout (desktop/tablet-portrait/tablet-landscape/phone)
- [ZOD-SET-001](../settings-persistence/ZOD-SET-001-build-the-settings-screen-panel-layout.md) — Build the Settings screen panel layout
- [ZOD-DAT-001](../settings-persistence/ZOD-DAT-001-build-the-saved-squares-list-screen.md) — Build the Saved squares list screen
- [ZOD-ABT-001](../about/ZOD-ABT-001-build-the-about-screen-hero.md) — Build the About screen hero

## Specification References

- NFR-C2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
