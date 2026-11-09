# ZOD-ASP-002 - Implement aspect-orb configuration data flow

## Metadata

- **ID:** ZOD-ASP-002
- **Category:** [Computation Engine](../README.md#computation-engine) (`computation-engine/`)
- **Phase:** Phase 3 (wired once Settings exists)
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Connect `UserSettings.orbs` (if editing is approved — see D-1 below) or the fixed defaults into [ZOD-ASP-001](../computation-engine/ZOD-ASP-001-implement-aspect-detection-between-body-pairs.md), so the detection engine reads orbs from one place.

## Implementation Details

- If open decision D-1 resolves to "editable," read per-aspect orb values from `UserSettings`; if it resolves to "fixed," hard-code the default table and skip the read path (but keep the plumbing so flipping the decision later is a settings-UI-only change).
- **Blocked on D-1** — see §6 Open decisions.

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` shows editable steppers for this (±8°, ±4°, etc.) already built as a mockup; `design-reference/zodiann/DESIGN_DECISIONS.md` D18 flags this explicitly as needing approval because it mocks an editable control while the spec's default assumes "no editing."

## Acceptance Criteria

- [ ] Changing an orb value in Settings (if approved editable) immediately changes which aspects ZOD-ASP-001 reports, with no restart.
- [ ] If D-1 resolves to "fixed," the settings rows render read-only, matching DESIGN_DECISIONS D18's fallback instruction.

## Dependencies

- [ZOD-ASP-001](../computation-engine/ZOD-ASP-001-implement-aspect-detection-between-body-pairs.md) — Implement aspect detection between body pairs
- [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md) — Build the "Wheel and computation" panel

## Specification References

- "Aspect orbs are configurable in settings" (planning constraints)
- D-1
- DESIGN_DECISIONS.md D18

## Notes

- This task touches an item flagged **needing approval** in `design-reference/zodiann/DESIGN_DECISIONS.md` — confirm the interpretation above with the product owner before implementing.
- This task is **blocked on an open product decision** — see `TASKS.md` §6 "Open decisions and blockers" before proceeding.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Computation Engine" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
