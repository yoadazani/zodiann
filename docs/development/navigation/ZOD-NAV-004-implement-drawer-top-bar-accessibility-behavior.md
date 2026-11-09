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

- [ ] VoiceOver/TalkBack announces the hamburger's expanded/collapsed state correctly.
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

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Navigation & App Shell" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
