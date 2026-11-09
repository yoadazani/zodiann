# ZOD-UI-015 - Build the automated light/dark, EN/HE visual regression harness

## Metadata

- **ID:** ZOD-UI-015
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1 (harness), ongoing
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Stand up the screenshot-testing infrastructure that L-19 and T-UI tasks depend on, so every component and screen can be verified against the design reference automatically, not just by eyeballing.

## Implementation Details

- Golden-image tests per component, each run in all four combinations (dark/light × EN/HE).
- Store goldens alongside a documented process for updating them deliberately (never silently) when a design change is approved.
- Wire into CI ([ZOD-FND-004](../foundations-architecture/ZOD-FND-004-set-up-the-ci-pipeline.md)) as a required check before merge for any UI package change.

## Design Reference

No direct design reference applies to the harness itself; it exists to enforce fidelity to `design-reference/zodiann/screens/`, `responsive/`, and `components/`.

## Acceptance Criteria

- [ ] A deliberate pixel change in a component fails CI until the golden is updated.
- [ ] All four theme/language combinations are covered for every component built from ZOD-UI-004 onward.

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) through [ZOD-UI-014](../shared-ui-design-system/ZOD-UI-014-implement-the-hairline-panel-component.md)

## Specification References

- L-19
- T-UI series

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
