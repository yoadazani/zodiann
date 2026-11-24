# ZOD-IOS-011 - Audit VoiceOver and verify iOS device behavior

## Metadata

- **ID:** ZOD-IOS-011
- **Category:** iOS (`ios/tasks/`)
- **Parent tasks:** [ZOD-NFR-006](../../performance-accessibility-reliability/ZOD-NFR-006-audit-full-screen-reader-navigation-voiceover-talkback.md) (the VoiceOver pass); [ZOD-NAV-004](../../navigation/ZOD-NAV-004-implement-drawer-top-bar-accessibility-behavior.md); [ZOD-WHL-013](../../zodiac-wheel/ZOD-WHL-013-implement-screen-reader-accessibility-actions-for-the-wheel.md); [ZOD-UI-007](../../shared-ui-design-system/ZOD-UI-007-implement-switch-stepper-and-body-chip-components.md), [ZOD-UI-008](../../shared-ui-design-system/ZOD-UI-008-implement-the-radio-list-component-ephemeris-source-selector.md), [ZOD-UI-013](../../shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md) (VoiceOver wording)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started (blocked: needs macOS and an iOS device; see Notes)
- **Scope:** MVP

## Description

Every task that builds an accessible control verified its semantics in tests and, where it could, with TalkBack. VoiceOver (iOS) behaves differently and was never run. This task owns every VoiceOver check, so the parent tasks keep their TalkBack and shared verification and are not held up by macOS.

## Implementation Details

Moved from ZOD-NFR-006:

- The full manual VoiceOver pass over every interactive element built in `navigation/` through `settings-persistence/`. TalkBack stays in NFR-006. Gaps found are filed as bugs against the owning task, not fixed ad hoc here.

Moved from the component tasks' VoiceOver clauses and "Not covered" device checks:

- ZOD-NAV-004: VoiceOver announces the hamburger's expanded or collapsed state correctly.
- ZOD-WHL-013: VoiceOver can move the wheel by 1° and 10° through accessibility actions.
- ZOD-UI-007: VoiceOver wording for the switch (a button with a `toggled` state) and the orb stepper.
- ZOD-UI-008: VoiceOver wording of a radio row.
- ZOD-UI-013: VoiceOver wording of the dialog, including whether the title is announced twice (the route-naming node and the header both carry it).
- The input field's iOS touch-typing, selection-toolbar and keyboard checks are not here; they are in ZOD-IOS-006.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] NFR-X2 passes on iOS: full navigation with VoiceOver and an external keyboard works across drawer, wheel and square. *(ZOD-NFR-006 criterion 1, VoiceOver clause.)*
- [ ] Every VoiceOver finding is filed against its owning component task with a specific repro. *(ZOD-NFR-006 criterion 2, VoiceOver part.)*
- [ ] VoiceOver announces the hamburger's expanded/collapsed state correctly. *(ZOD-NAV-004 criterion 1, VoiceOver clause.)*
- [ ] VoiceOver can move the wheel by 1° and 10° via accessibility actions. *(ZOD-WHL-013 criterion 1, VoiceOver clause.)*
- [ ] The VoiceOver wording of the switch, the orb stepper, a radio row and the dialog is checked on a device and any change is made test-first in the owning component. *(ZOD-UI-007, ZOD-UI-008 and ZOD-UI-013 "Not covered".)*

## Dependencies

- [ZOD-NFR-006](../../performance-accessibility-reliability/ZOD-NFR-006-audit-full-screen-reader-navigation-voiceover-talkback.md), [ZOD-NAV-004](../../navigation/ZOD-NAV-004-implement-drawer-top-bar-accessibility-behavior.md), [ZOD-WHL-013](../../zodiac-wheel/ZOD-WHL-013-implement-screen-reader-accessibility-actions-for-the-wheel.md) — the Android and shared halves, which must exist to be audited
- [ZOD-IOS-002](ZOD-IOS-002-verify-the-app-shell-build-and-runtime-on-ios.md) — needs a working iOS build

## Specification References

- NFR-X2
- NAV-6
- WH-10

## Notes

- **Blocked: macOS access and an iOS device** (owner constraint 2026-11-20: no spending).
- The wording of the parents' criteria now names TalkBack; the VoiceOver clauses are here. Nothing was dropped.

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
