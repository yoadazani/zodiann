# ZOD-EXT-001 - User-defined aspect orbs with an active-aspects list

## Metadata

- **ID:** ZOD-EXT-001
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Extend [ZOD-ASP-002](../computation-engine/ZOD-ASP-002-implement-aspect-orb-configuration-data-flow.md) (currently gated on D-1) to let users freely edit orb values beyond the default table, and show the list of currently active aspects in the positions/crossings area.

## Implementation Details

Builds directly on the already-wired `[ZOD-ASP-002](../computation-engine/ZOD-ASP-002-implement-aspect-orb-configuration-data-flow.md)` plumbing if D-1 resolves to "editable"; otherwise this becomes net-new UI-unlock work.

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` orb steppers already mock the editable UI (DESIGN_DECISIONS D18).

## Acceptance Criteria

- [ ] Editing an orb value changes detected aspects app-wide with no restart.
- [ ] An "active aspects" list is shown somewhere in the wheel UI.

## Dependencies

- [ZOD-ASP-002](../computation-engine/ZOD-ASP-002-implement-aspect-orb-configuration-data-flow.md) — Implement aspect-orb configuration data flow

## Specification References

- "Planned extensions to the wheel" (user-defined aspect orbs)
- D-1

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
