# ZOD-UI-009 - Implement the tag component (highlight tags, mode tags, Today/Center outline tags)

## Metadata

- **ID:** ZOD-UI-009
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the 24px/6-radius tag component used across the square's cell details, saved-squares list, and positions table.

## Implementation Details

- Variants: highlight tags (carry the +/× mark per NFR-X4), outline tags for Today and Center, a neutral tag for mode labels (Dates, Numbers, etc.), an accent tag.
- 12/600 text.

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Tags"; `design-reference/zodiann/components/components_dark.png` "Tags, tables and wheel marks" section (shows Axis/Diagonal/Eighth/No highlight/Center/Today tags with their marks).

## Acceptance Criteria

- [ ] Every tag variant in the component sheet is implemented and matches pixel-for-pixel.
- [ ] Highlight tags always render their +/× mark alongside color, never color alone (NFR-X4).

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Tags"
- NFR-X4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
