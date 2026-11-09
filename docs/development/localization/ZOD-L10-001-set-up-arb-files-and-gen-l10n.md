# ZOD-L10-001 - Set up ARB files and `gen-l10n`

## Metadata

- **ID:** ZOD-L10-001
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Establish the translation-key infrastructure every string in the app must flow through — no hard-coded text anywhere in code (L-8).

## Implementation Details

- Separate `.arb` files per language (`app_en.arb`, `app_he.arb`), wired to `gen-l10n`.
- CI check (ties to [ZOD-FND-004](../foundations-architecture/ZOD-FND-004-set-up-the-ci-pipeline.md)): fails the build when a key exists in one language file but not the other.

## Design Reference

No direct design reference applies — infrastructure task; the strings themselves are sourced from the English/Hebrew copy visible throughout `design-reference/zodiann/screens/*_en_*` and `*_he_*`.

## Acceptance Criteria

- [ ] Adding a string only to `app_en.arb` (not `app_he.arb`) fails CI.
- [ ] No string literal appears directly in a widget's `Text()` call anywhere in the codebase (enforced by lint/review).

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- L-8

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
