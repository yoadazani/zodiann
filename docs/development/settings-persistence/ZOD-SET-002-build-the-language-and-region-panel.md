# ZOD-SET-002 - Build the Language and region panel

## Metadata

- **ID:** ZOD-SET-002
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the language selector, English date-order toggle, read-only time-format note, and read-only time-zone display.

## Implementation Details

- Language: System / עברית / English segmented control ([ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md)), changes applied immediately with no restart (L-3).
- Date order in English: Day/month/year vs. Month/day/year (Hebrew always uses day.month.year, shown as a note, not a control — L-12).
- Time format: read-only "24-hour, in both languages" (L-13).
- Time zone: read-only, shows the device zone (e.g., "Device, Asia/Jerusalem (UTC+2)"), with the note that 4-hour steps are measured in absolute time.

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Language and region" panel (exact rows, copy, and control types).

## Acceptance Criteria

- [ ] Changing language takes effect immediately across the whole app, no restart (T-UI/L-18 scenario).
- [ ] Date-order toggle only affects English; Hebrew stays fixed at day.month.year regardless.

## Dependencies

- [ZOD-SET-001](../settings-persistence/ZOD-SET-001-build-the-settings-screen-panel-layout.md) — Build the Settings screen panel layout
- ZOD-L10-003 (language override)
- [ZOD-UI-006](../shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) — Implement the segmented control component

## Specification References

- L-3
- L-12
- L-13
- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
