# ZOD-EXT-008 - User-defined highlight angles and colors

## Metadata

- **ID:** ZOD-EXT-008
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Let users define additional highlight rules (arbitrary angle sets or "multiple of X°" rules) beyond the three defaults, each with its own color and priority — the data model (`HighlightRule`/`HighlightMatch`) already supports this; only the UI to author them is missing.

## Implementation Details

`HighlightMatch`'s `AnglesMatch`/`MultipleOfMatch` sealed-class design ([ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md)) was built specifically to support this extension without a data-model change — implementation is UI-only (a rule editor) plus wiring new rules into [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md)'s priority-ordered classification.

## Design Reference

No direct design reference applies — not shown in any mockup; follow the existing component patterns ([ZOD-UI-005](../shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) inputs, [ZOD-UI-009](../shared-ui-design-system/ZOD-UI-009-implement-the-tag-component-highlight-tags-mode-tags-today-center.md) tags) rather than inventing new control types.

## Acceptance Criteria

- [ ] A user-authored rule correctly overrides/coexists with the three defaults per its priority value.
- [ ] No data-model change is required (validates the forward-compatible design from ZOD-FND-012).

## Dependencies

- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes
- [ZOD-GAN-002](../computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) — Implement Gann highlight classification (blue/yellow/gray)

## Specification References

- "Planned extensions to the square" (user-defined highlighted angles)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
