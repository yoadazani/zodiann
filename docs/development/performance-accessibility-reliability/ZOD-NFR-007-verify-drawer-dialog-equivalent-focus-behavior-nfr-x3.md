# ZOD-NFR-007 - Verify drawer dialog-equivalent focus behavior (NFR-X3)

## Metadata

- **ID:** ZOD-NFR-007
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Confirm the drawer specifically behaves as a focus-trapping dialog for assistive tech, distinct from the general NFR-X2 sweep.

## Implementation Details

- Dedicated verification that the drawer opens as a modal dialog with focus retained inside, and returns focus to the hamburger on close (already built in [ZOD-NAV-004](../navigation/ZOD-NAV-004-implement-drawer-top-bar-accessibility-behavior.md); this task is the explicit NFR-X3 sign-off).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] NFR-X3 explicitly signed off as passing, cross-referenced from ZOD-NAV-004's implementation.

## Dependencies

- [ZOD-NAV-004](../navigation/ZOD-NAV-004-implement-drawer-top-bar-accessibility-behavior.md) — Implement drawer/top-bar accessibility behavior

## Specification References

- NFR-X3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
