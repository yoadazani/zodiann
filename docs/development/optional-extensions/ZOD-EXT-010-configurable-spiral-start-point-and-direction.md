# ZOD-EXT-010 - Configurable spiral start point and direction

## Metadata

- **ID:** ZOD-EXT-010
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Expose `SpiralStart` (left/right/up/down) and `SpiralRotation` (cw/ccw) — already present in the `SquareConfig` data model — as a user-facing setting, rather than the current fixed "left, clockwise" behavior.

## Implementation Details

The data model already carries these fields ([ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md)); [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md)'s math currently assumes the fixed left/clockwise case implied by D-4's proposed default — generalizing it to the other seven start/direction combinations is the actual implementation work, not just a settings-UI addition.

## Design Reference

No direct design reference applies — not shown in any mockup; the fixed spiral direction is deliberately what's mocked everywhere per D-4's default.

## Acceptance Criteria

- [ ] All eight start/direction combinations produce a geometrically correct, self-consistent spiral (verified with an equivalent of T-GAN-1 per combination).
- [ ] The default (left, clockwise) remains pixel-identical to the current MVP behavior when this setting is left at its default.

## Dependencies

- [ZOD-GAN-001](../computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) — Implement the Gann spiral position formulas (k, j, i, θ)
- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes

## Specification References

- "Planned extensions to the square" (spiral direction setting)
- D-4
- SQ-8

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
