# ZOD-L10-002 - Implement first-launch language detection

## Metadata

- **ID:** ZOD-L10-002
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

On first launch, set the app language from the device language; default to English if unsupported.

## Implementation Details

- Read device locale once on first launch (not on every launch, since a later in-app override — ZOD-L10-003 — must persist and not be overwritten by this check again).
- Supported set: `he`, `en`. Anything else → English.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A device set to Hebrew opens the app in Hebrew on first launch.
- [ ] A device set to e.g. French opens the app in English on first launch.
- [ ] After the first launch, this detection never re-runs and silently override a user's explicit language choice.

## Dependencies

- ZOD-L10-001

## Specification References

- L-2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
