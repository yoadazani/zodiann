# ZOD-ABT-001 - Build the About screen hero

## Metadata

- **ID:** ZOD-ABT-001
- **Category:** [About & Sources](../README.md#about) (`about/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the top hero block: logo, wordmark, version/build, and one-sentence purpose statement.

## Implementation Details

- App logo at 132px (uses [ZOD-FND-008](../foundations-architecture/ZOD-FND-008-package-and-integrate-the-app-icon-logo-asset-set.md)'s asset), "Zodiann" wordmark at 56/300 (phone 40, per [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md)'s Hero wordmark role), version + build string, one-sentence purpose copy.

## Design Reference

`design-reference/zodiann/screens/05-about-sources_desktop_en_dark.png` hero block (exact copy: "A precise instrument for time cycles: real planet positions on a zodiac wheel, and the Gann Square of Nine where every cell is a number, a day, or a 4-hour block.").

## Acceptance Criteria

- [ ] Hero matches the reference screenshot in both themes/languages.
- [ ] Version/build string reflects the actual app build, not a hard-coded placeholder.

## Dependencies

- [ZOD-FND-008](../foundations-architecture/ZOD-FND-008-package-and-integrate-the-app-icon-logo-asset-set.md) — Package and integrate the app icon / logo asset set
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-NAV-003](../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md) — Wire drawer navigation to `go_router` routes

## Specification References

- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "About & Sources" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
