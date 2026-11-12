# ZOD-DAT-009 - Persist anchor dates with time-zone offset

## Metadata

- **ID:** ZOD-DAT-009
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 3
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Store every saved anchor with its time-zone offset at save time, so a square opens with exactly the same dates even after travel or a DST change.

## Implementation Details

- `SquareConfig.anchor` stores the offset alongside the moment (per the `DateTime?` field's documented "with time zone offset" requirement in the data model). Since ZOD-FND-012 (2026-11-12), the anchor is an `OffsetDateTime` (UTC instant + offset minutes, JSON as ISO-8601 with offset), so this task persists that value and verifies the behaviour below. It does not need to change the class.
- Verify this specifically across a DST boundary and a simulated time-zone change.

## Design Reference

No direct design reference applies — data-integrity requirement.

## Acceptance Criteria

- [ ] A square saved before a DST transition, reopened after it, still shows the exact same anchor date/time it was saved with.
- [ ] Reopening on a device in a different time zone than where it was saved still shows the original anchor moment correctly.

## Dependencies

- [ZOD-DAT-002](../settings-persistence/ZOD-DAT-002-implement-save-current-square-flow.md) — Implement "Save current square" flow
- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes

## Specification References

- DATA-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
