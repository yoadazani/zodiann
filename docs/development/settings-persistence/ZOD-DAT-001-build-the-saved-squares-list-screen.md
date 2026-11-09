# ZOD-DAT-001 - Build the Saved squares list screen

## Metadata

- **ID:** ZOD-DAT-001
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the list of saved squares with mini thumbnail, name, meta tags, update date, and action buttons.

## Implementation Details

- Head: section title (26/600), counter ("7 of 100 saved"), primary "Save current square" button.
- Row: 52px mini thumbnail showing the real highlight pattern for that square's size/mode, name (16/500), meta (mode tag, size, anchor), "Updated <date>", then Open + rename (pencil) + delete (trash) icon buttons.
- Phone: actions collapse into an overflow (⋮) button.
- Empty state per the component sheet (no saved squares yet).

## Design Reference

`design-reference/zodiann/screens/03-saved-squares_desktop_{en,he}_{dark,light}.png` (full list with 7 example squares); `design-reference/zodiann/components/components_dark.png` "Dialogs, drawer items and empty state" section for the empty-state treatment; `design-reference/zodiann/MASTER.md` §9 "Saved squares".

## Acceptance Criteria

- [ ] List matches the reference screenshot's row layout, thumbnail style, and meta tags.
- [ ] Empty state matches the component sheet when zero squares are saved.
- [ ] Phone layout collapses actions into an overflow button, matching responsive expectations (no dedicated mobile screenshot exists for this screen — flagged as a minor design gap, infer from the general phone action-collapse pattern used elsewhere).

## Dependencies

- [ZOD-UI-014](../shared-ui-design-system/ZOD-UI-014-implement-the-hairline-panel-component.md) — Implement the hairline panel component
- [ZOD-UI-009](../shared-ui-design-system/ZOD-UI-009-implement-the-tag-component-highlight-tags-mode-tags-today-center.md) — Implement the tag component (highlight tags, mode tags, Today/Center outline tags)
- [ZOD-NAV-003](../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md) — Wire drawer navigation to `go_router` routes

## Specification References

- DATA-2
- UC10
- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
