# ZOD-NAV-005 - Implement responsive drawer behavior across breakpoints

## Metadata

- **ID:** ZOD-NAV-005
- **Category:** [Navigation & App Shell](../README.md#navigation) (`navigation/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Verify and implement the drawer's identical-pattern behavior across phone, tablet, and desktop widths (NAV-7), since large screens must not silently become a permanent sidebar.

## Implementation Details

- Apply the three breakpoints from MASTER.md §6 (phone <700, tablet 700–1099, desktop/tablet-landscape ≥1100) to the drawer's width calculation (`min(320, 86%)`) and overlay behavior.
- Confirm no breakpoint renders the drawer as permanently docked content (a common anti-pattern this task exists to explicitly prevent).

## Design Reference

`design-reference/zodiann/MASTER.md` §6 "Breakpoints"; `design-reference/zodiann/responsive/tablet/*` and `responsive/mobile/*` drawer captures if present, else infer identical behavior from the desktop capture at narrower widths.

## Acceptance Criteria

- [ ] Drawer width is `min(320, 86%)` at every tested breakpoint.
- [ ] No breakpoint shows the drawer as permanently visible/docked.

## Dependencies

- [ZOD-NAV-002](../navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md) — Implement the side navigation drawer

## Specification References

- NAV-7
- MASTER.md §6

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Navigation & App Shell" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
