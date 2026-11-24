# ZOD-NAV-004 - Implement drawer/top-bar accessibility behavior

## Metadata

- **ID:** ZOD-NAV-004
- **Category:** [Navigation & App Shell](../README.md#navigation) (`navigation/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Implement the focus-management and accessibility-state contract for opening/closing the drawer.

## Implementation Details

- On open, focus moves to the active drawer item; on close, focus returns to the hamburger button (NAV-6).
- The hamburger button exposes an expanded/collapsed accessibility state and a descriptive accessibility label (NAV-6).
- The drawer behaves as a modal dialog for assistive tech (focus retained inside while open), consistent with [ZOD-UI-013](../shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md)'s dialog focus-trap pattern (NFR-X3).

## Design Reference

No direct design reference applies — this is a behavioral/accessibility task layered on the already-built [ZOD-NAV-002](../navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md) visuals.

## Acceptance Criteria

- [ ] TalkBack announces the hamburger's expanded/collapsed state correctly. *(Split 2026-11-24: the original read "VoiceOver/TalkBack announces…"; the VoiceOver clause is criterion 3 of [ZOD-IOS-011](../ios/tasks/ZOD-IOS-011-audit-voiceover-and-verify-ios-device-behavior.md).)*
- [ ] Focus lands on the active item when the drawer opens via keyboard or screen reader.
- [ ] Focus returns to the hamburger exactly on close, every time, including via the Android back button.

## Dependencies

- [ZOD-NAV-002](../navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md) — Implement the side navigation drawer
- [ZOD-UI-013](../shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md) — Implement the dialog component

## Specification References

- NAV-6
- NFR-X2
- NFR-X3

## Notes

- **From ZOD-UI-013 (2026-11-23):** the dialog pattern to follow is `showZodiannDialog` (`packages/shared_ui/lib/src/widgets/zodiann_dialog_route.dart`): a modal route on the root navigator whose scope traps Tab (`TraversalEdgeBehavior.closedLoop`), restores the focus that held it when it opened (a keyboard-opened trigger gets it back; `ZodiannButton` and `ZodiannPressable` never take focus on a pointer tap, so a tapped hamburger holds none), names itself through a `namesRoute` node and adds no semantics node for the scrim (`semanticsDismissible => false`). The drawer route (`_ZodiannDrawerRoute`) is its own route class; align its focus and semantics with these tests rather than copying code.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Navigation & App Shell" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
