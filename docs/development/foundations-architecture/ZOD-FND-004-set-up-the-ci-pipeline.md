# ZOD-FND-004 - Set up the CI pipeline

## Metadata

- **ID:** ZOD-FND-004
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done (see Notes)
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

- [x] A PR with a failing core test is blocked from merge. (Proof PRs against `main`: `Core` red, merge state `BLOCKED`, `gh pr merge` and `gh pr merge --admin` refused; ruleset 27719587. `docs/ci.md` sections 5 and 7.)
- [x] A PR that adds a UI/Flutter import to `astro_core` or `gann_core` fails CI. (Proof PR: `Core` red at the analyzer with `--fatal-infos`; the ARCH-2 test also fails on the same code when run. `docs/ci.md` section 5.)
- [x] Full suite runtime is tracked so it can be kept fast as the test count grows. (`tool/ci/timed.dart`: per-step CSV artifact, job-summary table and a non-failing budget warning, 240 s for the Full suite. `docs/ci.md` sections 2 and 3.)

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace

## Specification References

- "Automated tests in the pipeline"
- L-8

## Notes

- **From ZOD-L10-001 (2026-11-14):** `melos run lint` now starts with `l10n:check`. That step runs `tool/check_l10n.dart`, which calls the pinned SDK's `flutter gen-l10n` (`MELOS_SDK_PATH`, else the running Dart's SDK), so CI needs the `.fvmrc` Flutter SDK, not only Dart. The key-parity test and the `Text()` literal guard run in `melos run test` (root `test/architecture/`).
- **From ZOD-FND-004 (2026-11-20):** the pipeline is `.github/workflows/ci.yml`, documented in [`docs/ci.md`](../../ci.md) (jobs, required checks, runtimes, evidence, ruleset). `Core` and `Lint` run on `ubuntu-latest`; `Full suite` runs on `windows-latest` by the product owner's decision, because two compact degree-scale fidelity cases (`degree_scale_fidelity_test.dart`) exceed their Windows-calibrated ceilings on Linux (no tolerance, golden or hash was changed). Triggers are pushes to `main` and pull requests to `main`. The ruleset on `main` is outside the repository's files (GitHub setting, id 27719587); the checks it requires are named `Core`, `Lint` and `Full suite`. The Gate 1 required-checks group (ZOD-TST-017) and the visual regression harness (ZOD-UI-015) build on this and are not part of it.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
