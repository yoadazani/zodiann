# ZOD-UI-011 - Implement the toast/feedback component (export status, progress with Stop)

## Metadata

- **ID:** ZOD-UI-011
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 3
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the toast system used for Excel export status and long-running crossing-table computation progress.

## Implementation Details

- Export toast states: preparing (with a progress bar), saved (with a Share action), canceled, error (with a cause and a remedy) — matches EX-6 exactly.
- Long-computation progress toast includes a Stop action (NFR-P3).

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Feedback"; `design-reference/zodiann/components/components_dark.png` "Feedback" section (shows all five toast states listed verbatim: preparing, saved with Share, canceled, failed with remedy, computing with Stop).

## Acceptance Criteria

- [ ] All toast states in the component sheet are implemented with matching copy structure (status + optional action).
- [ ] The "computing" toast's Stop action actually cancels the underlying isolate computation (ties to ZOD-NFR-001/003).
- [ ] Dismissing/closing a toast without action is never treated as an error (EX-7 "closing the share sheet without choosing is not an error" — equivalent principle).

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- EX-6
- EX-7
- NFR-P3
- MASTER.md §10 "Feedback"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
