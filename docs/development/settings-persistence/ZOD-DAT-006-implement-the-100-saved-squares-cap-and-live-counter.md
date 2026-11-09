# ZOD-DAT-006 - Implement the 100-saved-squares cap and live counter

## Metadata

- **ID:** ZOD-DAT-006
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 3
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Keep the "N of 100 saved" counter accurate and enforce the cap at the storage layer, not just in the save-flow UI.

## Implementation Details

- Counter updates live on save/delete.
- Cap is enforced in the storage layer ([ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md)) so no code path can bypass it.

## Design Reference

`design-reference/zodiann/screens/03-saved-squares_desktop_en_dark.png` ("7 of 100 saved" counter).

## Acceptance Criteria

- [ ] Counter always reflects the true stored count.
- [ ] No code path (including import, ZOD-DAT-008) can push the stored count above 100 without a clear message.

## Dependencies

- [ZOD-DAT-002](../settings-persistence/ZOD-DAT-002-implement-save-current-square-flow.md) — Implement "Save current square" flow
- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1

## Specification References

- DATA-2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
