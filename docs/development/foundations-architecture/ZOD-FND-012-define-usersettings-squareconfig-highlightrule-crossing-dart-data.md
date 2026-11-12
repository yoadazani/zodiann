# ZOD-FND-012 - Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes

## Metadata

- **ID:** ZOD-FND-012
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done
- **Scope:** MVP

## Description

Implement the four core immutable data classes from the spec's data model, with JSON (de)serialization, as the shared contract between computation, storage, and UI.

## Implementation Details

- Implement exactly the `SquareMode`, `SpiralStart`, `SpiralRotation`, `SquareConfig`, `HighlightMatch`/`AnglesMatch`/`MultipleOfMatch`, `HighlightRule` and `Crossing` types as specified (code block in "Data model and user settings"), and add JSON to the existing `Body` enum (defined by ZOD-FND-002). `UserSettings` is **not** part of this task (deferred to [ZOD-SET-007](../settings-persistence/ZOD-SET-007-implement-usersettings-persistence-wiring.md)).
- Model `SquareConfig.anchor` as a pure-Dart `OffsetDateTime` (UTC instant + offset in minutes, serialized as ISO-8601 with offset), so the offset required by DATA-4 is held and serialized. Dart's `DateTime` can't hold an arbitrary offset.
- Add `fromJson`/`toJson` for every persisted class (used by DATA-1 storage and DATA-3 backup export). `Crossing` deliberately has none, because it is never persisted (see Notes and the "Crossing has no storage/persistence code path" criterion).
- `Crossing` is explicitly **not** persisted — ensure no storage code path attempts to save it (it's derived/recomputed only).
- Document the default highlight rules (Axes/Diagonals/Eighths, priorities 1/2/3) as the default `List<HighlightRule>` a new `SquareConfig` gets.

## Design Reference

No direct design reference applies — this is a pure data-model task in `packages/astro_core`/`packages/gann_core`.

## Acceptance Criteria

- [x] `SquareConfig`, `HighlightRule` (with `HighlightMatch`) and `Crossing` compile, and the persisted types round-trip through JSON without data loss, including the anchor's time-zone offset. (`UserSettings` is deferred to ZOD-SET-007.)
- [x] `Crossing` has no storage/persistence code path.
- [x] A new `SquareConfig` defaults to the three default highlight rules in the documented priority order.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace

## Specification References

- "Data model and user settings" (full code block)
- "Default highlight rules"

## Notes

- `Body` is defined in `packages/astro_core` by [ZOD-FND-002](ZOD-FND-002-define-the-ephemerisport-interface-contract.md). This task adds its `fromJson`/`toJson` and must not redefine it.
- 2026-11-12 (product-owner decisions):
  - **`UserSettings` is deferred to [ZOD-SET-007](../settings-persistence/ZOD-SET-007-implement-usersettings-persistence-wiring.md).** The spec gives only a field list, several fields depend on open decisions (D-1, D-3, D-5/D19), and it mixes wheel and square types. The first acceptance criterion was amended accordingly. The task title is kept for traceability.
  - **The anchor is an `OffsetDateTime` value type**, not a bare `DateTime`. This satisfies DATA-4's "saved with a time zone offset". [ZOD-DAT-009](../settings-persistence/ZOD-DAT-009-persist-anchor-dates-with-time-zone-offset.md) persists it and verifies the DST and zone-change behaviour.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
