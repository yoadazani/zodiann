# ZOD-SET-007 - Implement `UserSettings` persistence wiring

## Metadata

- **ID:** ZOD-SET-007
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Connect every control built in [ZOD-SET-002](../settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md) through 006 to the `UserSettings` storage wrapper ([ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md)), so every change survives app restart.

## Implementation Details

- Each setting row writes through immediately (no separate "Save" step for settings — matches the mockup's direct-manipulation controls).
- Verify every field in the `UserSettings` entity (theme, time zone, aspect orbs, visible bodies, node type, ephemeris source, zodiac system, square defaults) round-trips through storage.

## Design Reference

No direct design reference applies — this is the persistence wiring behind the already-built [ZOD-SET-002](../settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md)–006 screens.

## Acceptance Criteria

- [ ] Every settings row persists across a full app restart.
- [ ] `UserSettings` JSON round-trip (ZOD-FND-012) covers every field exercised by the Settings screen.

## Dependencies

- [ZOD-SET-002](../settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md) through [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md)
- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1
- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes

## Specification References

- DATA-1
- DATA-2
- "UserSettings" row in the data model table

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
