# ZOD-ASP-001 - Implement aspect detection between body pairs

## Metadata

- **ID:** ZOD-ASP-001
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the pairwise aspect check used by the wheel's chord lines and the (optional-extension) active-aspect list.

## Implementation Details

- For every pair of bodies excluding the node (node never takes part in aspects), compute `Δ = |wrap180(l₁ − l₂)|`.
- Check the five aspect rows in table order (conjunction, sextile, square, trine, opposition); an aspect exists when `|Δ − angle| ≤ orb`; the **first match in table order decides** (do not report multiple aspects for one pair).
- Orb values are configurable (default table below), read from `UserSettings` (wired once [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md) exists; until then, default to the fixed table).
- Color mapping: conjunction → amber; sextile, trine → turquoise; square, opposition → red (exact tokens resolved in [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md)'s `AspectColors`).

| Aspect | Angle | Default orb (±) |
|---|---|---|
| Conjunction | 0° | 8° |
| Sextile | 60° | 4° |
| Square | 90° | 6° |
| Trine | 120° | 6° |
| Opposition | 180° | 8° |

## Design Reference

No direct design reference applies to the detection logic; the resulting chord-line rendering is specified in `design-reference/zodiann/MASTER.md` §7.2 and built in [ZOD-WHL-007](../zodiac-wheel/ZOD-WHL-007-render-aspect-chords-on-the-inner-disc.md).

## Acceptance Criteria

- [ ] T-ASP-1 passes: every aspect-angle/orb boundary in the table is tested exactly at the orb and just outside it.
- [ ] The node never appears in any detected aspect pair.
- [ ] Exactly one aspect (or none) is ever reported per pair, per the "first match wins" rule.

## Dependencies

- [ZOD-EPH-005](../computation-engine/ZOD-EPH-005-implement-retrograde-detection-and-position-formatting.md) — Implement retrograde detection and position formatting
- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes

## Specification References

- "Aspects" table and rule
- WH-6
- T-ASP-1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
