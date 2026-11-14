# ZOD-L10-001 - Set up ARB files and `gen-l10n`

## Metadata

- **ID:** ZOD-L10-001
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done
- **Scope:** MVP

## Description

Establish the translation-key infrastructure every string in the app must flow through — no hard-coded text anywhere in code (L-8).

## Implementation Details

- Separate `.arb` files per language (`app_en.arb`, `app_he.arb`), wired to `gen-l10n`.
- CI check (ties to [ZOD-FND-004](../foundations-architecture/ZOD-FND-004-set-up-the-ci-pipeline.md)): fails the build when a key exists in one language file but not the other.

## Design Reference

No direct design reference applies — infrastructure task; the strings themselves are sourced from the English/Hebrew copy visible throughout `design-reference/zodiann/screens/*_en_*` and `*_he_*`.

## Acceptance Criteria

- [x] Adding a string only to `app_en.arb` (not `app_he.arb`) fails CI.
- [x] No string literal appears directly in a widget's `Text()` call anywhere in the codebase (enforced by lint/review).

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- L-8

## Notes

- **Done 2026-11-14** (plan: [`docs/plans/ZOD-L10-001-arb-localization.md`](../../plans/ZOD-L10-001-arb-localization.md)).
- **N1, product-owner decision (2026-11-14):** the ARB files live in `packages/shared_ui/lib/l10n/` (one shared set), and the generated `ZodiannLocalizations` is exported from `package:shared_ui`, so feature packages can use it without importing the app.
- **N2, product-owner decision (2026-11-14):** criterion 2 is enforced on shipped UI code: the `lib/` of every non-pure-Dart member, generated code included. `test/` and `integration_test/` may use literal text.
- **"Fails CI":** there is no CI pipeline yet (ZOD-FND-004). Criterion 1 is enforced by `test/architecture/l10n_key_parity_test.dart` in `melos run test`, and criterion 2 by `test/architecture/no_text_literals_test.dart`. FND-004's pipeline will run both gates.
- **Generated code:** it is committed. `melos run l10n:check` (first in `lint`) fails when it is stale.
- **Delegates:** register `const [ZodiannLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` (material_ui). `no_generated_delegates_test.dart` forbids the generated `localizationsDelegates`.
- **Scanner gaps:** conditional and `??` literals, and named labels (`semanticsLabel:`, `Tooltip(message:)`, `NavigationDestination(label:)` and similar) stay review-enforced.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
