# ZOD-EXT-003 - Additional bodies (Chiron, Lilith)

## Metadata

- **ID:** ZOD-EXT-003
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Add further bodies beyond the ten-plus-node set, pending verification of an ephemeris source that covers them.

## Implementation Details

Requires checking the ephemeris source's coverage for these bodies before any implementation work (explicit spec caveat); extends the `Body` enum ([ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md)), the wheel's body rendering (`zodiac-wheel/`), positions table, and settings body-chips list.

## Design Reference

No direct design reference applies — not shown in any mockup; would need new body glyph/color tokens added to `BodyColors` ([ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md)) following the existing token pattern, not a new visual language.

## Acceptance Criteria

- [ ] Ephemeris coverage is verified before implementation starts.
- [ ] New bodies integrate through the existing `Body` enum/token pattern, not a parallel one.

## Dependencies

- [ZOD-EPH-002](../computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) — Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)
- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes

## Specification References

- "Planned extensions to the wheel"
- D-3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
