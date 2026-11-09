# ZOD-L10-007 - Implement stable, language-independent entity keys

## Metadata

- **ID:** ZOD-L10-007
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Ensure every sign, body, aspect, and direction is identified internally by a stable key, never by its translated display name, and that storage/computation never touches translated strings.

## Implementation Details

- Core data model (`Body` enum, sign indices 0–11, aspect enum) is already key-based by construction ([ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md)); this task audits every UI layer to confirm no code path compares or stores a translated string instead of the key.
- Hebrew names follow each language's own tradition (not transliteration) per D20, e.g., טלה (Aries), נוגה (Venus), ראש הדרקון (the lunar node) — translation content itself, not the key architecture.

## Design Reference

No direct design reference applies to the architecture; `design-reference/zodiann/screens/*_he_*` show the target Hebrew terminology to translate to (per D20's "each language's tradition" rule) — e.g., the About/Settings/Wheel screens in Hebrew.

## Acceptance Criteria

- [ ] No stored or computed value (settings, saved squares, crossing results) ever contains a translated display string instead of a key.
- [ ] Hebrew sign/body/node names match traditional Hebrew astrological/astronomical terminology (D20), not transliteration.

## Dependencies

- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes
- ZOD-L10-001

## Specification References

- L-9
- D20

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
