# ZOD-FND-004 - Set up the CI pipeline

## Metadata

- **ID:** ZOD-FND-004
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Automated tests must run on every change, with special emphasis on the computation core, per the testing strategy.

## Implementation Details

- Configure CI to run `melos run test` (all packages) on every push/PR.
- Separate a fast "core only" job (`astro_core`, `gann_core`) that must pass before merge, from the full suite (including Flutter widget/golden tests).
- Fail the build if any ARB translation key is missing in either language (L-8, feeds ZOD-L10-014).
- Fail the build on analyzer warnings in `astro_core`/`gann_core` (keeps the UI-free constraint enforced, ARCH-2).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A PR with a failing core test is blocked from merge.
- [ ] A PR that adds a UI/Flutter import to `astro_core` or `gann_core` fails CI.
- [ ] Full suite runtime is tracked so it can be kept fast as the test count grows.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace

## Specification References

- "Automated tests in the pipeline"
- L-8

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
