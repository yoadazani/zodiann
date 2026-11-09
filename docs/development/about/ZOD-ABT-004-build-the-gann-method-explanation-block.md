# ZOD-ABT-004 - Build the Gann method explanation block

## Metadata

- **ID:** ZOD-ABT-004
- **Category:** [About & Sources](../README.md#about) (`about/`)
- **Phase:** Phase 4
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the formula-set display explaining the spiral/angle/highlight rules in plain language plus the literal formula block.

## Implementation Details

- Prose explanation ("1 sits in the center, 2 to its left, and the spiral continues clockwise...") plus the literal `k`, `j`, `i`, `θ` formula block and the Blue/Yellow/Gray swatch-labeled conditions, left-to-right regardless of app language (geometric/mathematical content, consistent with the wheel/square's never-mirror rule).

## Design Reference

`design-reference/zodiann/screens/05-about-sources_desktop_en_dark.png` "Gann method" panel (exact formula block and swatch layout).

## Acceptance Criteria

- [ ] Formula block matches the spec's "Gann spiral" formulas exactly.
- [ ] Formula block itself stays LTR in the Hebrew build (consistent with the square never mirroring), while surrounding prose is translated and correctly directional.

## Dependencies

- [ZOD-ABT-001](../about/ZOD-ABT-001-build-the-about-screen-hero.md) — Build the About screen hero
- [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — Implement the Gann spiral position formulas (k, j, i, θ)
- [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) — Implement Gann highlight classification (blue/yellow/gray)

## Specification References

- "Gann spiral" formula block
- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "About & Sources" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
