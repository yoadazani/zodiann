# ZOD-NFR-009 - Audit WCAG AA text contrast in both themes (NFR-X5)

## Metadata

- **ID:** ZOD-NFR-009
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Systematically verify every text/background token combination meets WCAG AA contrast, in both dark and light themes.

## Implementation Details

- Automated contrast-ratio check across every token pairing defined in [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) (e.g., `text-3` on `bg` must be ≥4.5:1, per MASTER.md §2.1's own documented minimum).
- Include highlighted-cell `-ink`-on-`-fill` pairs from `SquareColors`.

## Design Reference

`design-reference/zodiann/MASTER.md` §2.1 ("text-3 ... faint metadata (≥ 4.5:1 on bg)") and §14 "Accessibility floor".

## Acceptance Criteria

- [ ] NFR-X5 passes for every token pair actually used for text-on-background in the app, in both themes.

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)

## Specification References

- NFR-X5
- MASTER.md §2.1, §14

## Notes

- **Solid danger button (ZOD-UI-004, product-owner decision D2, 2026-11-13):** `ZodiannButtonVariant.dangerSolid` keeps the design's white label (`ZodiannStates.onDangerSolid`) on `danger`. That is 3.37:1 in the dark theme (fails AA for 14 px text) and 4.53:1 in light. `test/widgets/button_colors_test.dart` pins the shortfall; this audit decides the fix.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
