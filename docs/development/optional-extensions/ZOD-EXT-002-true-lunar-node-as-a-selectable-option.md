# ZOD-EXT-002 - True lunar node as a selectable option

## Metadata

- **ID:** ZOD-EXT-002
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Implement the full (non-mean) true-node formula/ephemeris lookup as an alternative to [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md)'s mean-node approximation, selectable via [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md)'s existing Mean/True toggle.

## Implementation Details

Requires sourcing true-node data from the ephemeris (not a closed-form formula like the mean node); the difference between mean and true can reach ~1.5°, so this is a genuinely different computation path, not a display toggle.

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Lunar node" Mean/True toggle (control already mocked; True is currently non-functional).

## Acceptance Criteria

- [ ] Selecting "True" produces a genuinely different (and correctly computed) node position, not the mean-node value relabeled.

## Dependencies

- [ZOD-EPH-001](../computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md) — Implement the mean ascending lunar node formula
- [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md) — Build the "Wheel and computation" panel

## Specification References

- "Planned extensions to the wheel"
- D-3
- "Ascending node" row in "Computation settings that must be fixed and documented"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
