# ZOD-FND-012 - Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes

## Metadata

- **ID:** ZOD-FND-012
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the four core immutable data classes from the spec's data model, with JSON (de)serialization, as the shared contract between computation, storage, and UI.

## Implementation Details

- Implement exactly the `SquareMode`, `SpiralStart`, `SpiralRotation`, `SquareConfig`, `HighlightMatch`/`AnglesMatch`/`MultipleOfMatch`, `HighlightRule`, `Body`, `Crossing` types as specified (code block in "Data model and user settings").
- Add `fromJson`/`toJson` for every class (used by DATA-1 storage and DATA-3 backup export).
- `Crossing` is explicitly **not** persisted — ensure no storage code path attempts to save it (it's derived/recomputed only).
- Document the default highlight rules (Axes/Diagonals/Eighths, priorities 1/2/3) as the default `List<HighlightRule>` a new `SquareConfig` gets.

## Design Reference

No direct design reference applies — this is a pure data-model task in `packages/astro_core`/`packages/gann_core`.

## Acceptance Criteria

- [ ] All four classes compile and round-trip through JSON without data loss.
- [ ] `Crossing` has no storage/persistence code path.
- [ ] A new `SquareConfig` defaults to the three default highlight rules in the documented priority order.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace

## Specification References

- "Data model and user settings" (full code block)
- "Default highlight rules"

## Notes

- `Body` is defined in `packages/astro_core` by [ZOD-FND-002](ZOD-FND-002-define-the-ephemerisport-interface-contract.md). This task adds its `fromJson`/`toJson` and must not redefine it.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
