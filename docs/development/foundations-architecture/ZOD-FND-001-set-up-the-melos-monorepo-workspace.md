# ZOD-FND-001 - Set up the Melos monorepo workspace

## Metadata

- **ID:** ZOD-FND-001
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Create the Dart/Flutter monorepo skeleton that every later package depends on, matching the structure the spec prescribes so the core stays UI-free and swappable.

## Implementation Details

- Create the `apps/astro_mobile`, `packages/*`, `native/*` layout exactly as listed in "Recommended structure in Melos".
- Configure Melos (`melos.yaml`) with bootstrap, lint, and test scripts that run across all packages.
- Pin Dart/Flutter SDK versions and set up `analysis_options.yaml` shared across packages.
- Set `packages/astro_core` and `packages/gann_core` as pure-Dart packages (no `flutter` dependency, no `dart:ui` import) from the start, enforced by package `pubspec.yaml` constraints.

## Design Reference

No direct design reference applies — this is a tooling/workspace task.

## Acceptance Criteria

- [ ] `melos bootstrap` succeeds and links all packages.
- [ ] `packages/astro_core` and `packages/gann_core` have no Flutter/`dart:ui` dependency (verified by `pub deps`).
- [ ] CI (ZOD-FND-004) can run `melos run test` across the whole workspace.

## Dependencies

_None — this task has no prerequisites._

## Specification References

- "Recommended structure in Melos"
- ARCH-2

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
