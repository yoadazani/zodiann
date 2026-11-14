# ZOD-L10-014 - Implement the missing-translation-key CI test

## Metadata

- **ID:** ZOD-L10-014
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

A dedicated, always-on test (distinct from the general CI wiring in [ZOD-FND-004](../foundations-architecture/ZOD-FND-004-set-up-the-ci-pipeline.md)) that fails specifically when any key is missing in either language file.

## Implementation Details

- Compare the full key set of `app_en.arb` and `app_he.arb` on every test run; fail with a diff listing exactly which keys are missing from which file.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] L-8's requirement ("a test fails when a key is missing in one of the languages") is met by a named, runnable test, not just an ad hoc CI script.

## Dependencies

- ZOD-L10-001
- [ZOD-FND-004](../foundations-architecture/ZOD-FND-004-set-up-the-ci-pipeline.md) — Set up the CI pipeline

## Specification References

- L-8

## Notes

- **From ZOD-L10-001 (2026-11-14):** the key-parity test already exists: `test/architecture/l10n_key_parity_test.dart` (helpers in `arb_keys.dart`). It runs on every `melos run test`, checks every `packages/shared_ui/lib/l10n/app_*.arb` against the template, and lists missing and extra keys per file. L10-001 had to build it, because its criterion 1 needs it. This task keeps its own scope: confirm the test meets L-8's "named, runnable test" inside ZOD-FND-004's pipeline, and extend it if needed.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
