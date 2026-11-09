# ZOD-NFR-006 - Audit full screen-reader navigation (VoiceOver/TalkBack)

## Metadata

- **ID:** ZOD-NFR-006
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

End-to-end screen-reader walkthrough of the whole app: drawer open/close, cell navigation, rotation/date accessibility actions.

## Implementation Details

- Full manual pass with VoiceOver (iOS) and TalkBack (Android) covering every interactive element built in `navigation/` through `settings-persistence/`.
- File any gap found as a bug against the specific owning task rather than fixing ad hoc in this task.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] NFR-X2 passes: full navigation with a screen reader and external keyboard works across drawer, wheel, and square.
- [ ] Every finding is filed against its owning component task with a specific repro.

## Dependencies

- [ZOD-NAV-004](../navigation/ZOD-NAV-004-implement-drawer-top-bar-accessibility-behavior.md) — Implement drawer/top-bar accessibility behavior
- [ZOD-WHL-013](../zodiac-wheel/ZOD-WHL-013-implement-screen-reader-accessibility-actions-for-the-wheel.md) — Implement screen-reader accessibility actions for the wheel
- [ZOD-SQR-011](../gann-square/ZOD-SQR-011-implement-keyboard-cell-selection-navigation.md) — Implement keyboard cell-selection navigation

## Specification References

- NFR-X2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
