# ZOD-UI-008 - Implement the radio-list component (ephemeris source selector)

## Metadata

- **ID:** ZOD-UI-008
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the radio-button list used for the three-way ephemeris source choice in Settings.

## Implementation Details

- Standard radio list row: label, optional trailing badge ("Recommended", "Backup").
- Must support the "Swiss Ephemeris, data files" / "Swiss Ephemeris, built-in (Moshier)" / "astronomy-engine" three options per [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md).

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Ephemeris source" section (shows the exact radio list with "Recommended" and "Backup" trailing labels); `design-reference/zodiann/components/components_dark.png` "Others" row.

## Acceptance Criteria

- [ ] Radio list renders and behaves per the settings screenshot (single selection, trailing badges).
- [ ] Keyboard-navigable (arrow keys move selection, matching NFR-X2's external-keyboard requirement).

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §9 "Settings"
- NFR-X2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
