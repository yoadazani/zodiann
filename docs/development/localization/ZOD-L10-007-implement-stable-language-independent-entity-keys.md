# ZOD-L10-007 - Implement stable, language-independent entity keys

## Metadata

- **ID:** ZOD-L10-007
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done
- **Scope:** MVP

## Description

Ensure every sign, body, aspect, and direction is identified internally by a stable key, never by its translated display name, and that storage/computation never touches translated strings.

## Implementation Details

- Core data model (`Body` enum, sign indices 0–11, aspect enum) is already key-based by construction ([ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md)); this task audits every UI layer to confirm no code path compares or stores a translated string instead of the key.
- Hebrew names follow each language's own tradition (not transliteration) per D20, e.g., טלה (Aries), נוגה (Venus), ראש הדרקון (the lunar node) — translation content itself, not the key architecture.

## Design Reference

No direct design reference applies to the architecture; `design-reference/zodiann/screens/*_he_*` show the target Hebrew terminology to translate to (per D20's "each language's tradition" rule) — e.g., the About/Settings/Wheel screens in Hebrew.

## Acceptance Criteria

- [x] No stored or computed value (settings, saved squares, crossing results) ever contains a translated display string instead of a key.
- [x] Hebrew sign/body/node names match traditional Hebrew astrological/astronomical terminology (D20), not transliteration.

## Dependencies

- [ZOD-FND-012](../foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) — Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes
- ZOD-L10-001

## Specification References

- L-9
- D20

## Notes

- **Done 2026-11-14** (plan: [`docs/plans/ZOD-L10-007-ZOD-L10-013-entity-keys.md`](../../plans/ZOD-L10-007-ZOD-L10-013-entity-keys.md)).
- **Keys:** `Body` (existing), `ZodiacSign` and `AspectKind` (`astro_core`), and `CompassDirection` (`gann_core`). JSON is the value's `name`, and the key lists are pinned by literal tests. Names come only from `ZodiannEntityNames` on `ZodiannLocalizations` (`signName`, `bodyName`, `aspectName`, `directionName`; exhaustive switches).
- **Criterion 1 audit (2026-11-14):**
  - **Inspected:** `apps/astro_mobile/lib` (shell only), `packages/feature_*/lib` (stubs), `packages/shared_ui/lib`, and the data model's `String` fields (`SquareConfig.id/name`, `HighlightRule.id/label/colorToken`).
  - **Result:** no stored or computed value holds a translated string. Entity-valued fields are enum-typed (`Crossing.body: Body`). The default `HighlightRule.label`s (`axes`, `diagonals`, `eighths`) are keys. `SquareConfig.name` and user-defined labels are user content.
  - **Guard:** `test/architecture/no_l10n_in_core_test.dart` fails if `astro_core`, `gann_core`, the ephemeris adapters or `shared_storage` import or depend (at runtime) on `shared_ui` / `flutter_localizations`, or mention `ZodiannLocalizations`.
- **Criterion 2:** met per the [ZOD-L10-013](ZOD-L10-013-resolve-and-document-the-symbol-translation-open-decision.md) decision record. Signs, the classical bodies and the node use traditional Hebrew names. Uranus, Neptune and Pluto use the common Hebrew-script forms, a recorded exception (product-owner decision T3). `packages/shared_ui/test/l10n/entity_names_test.dart` pins every name against a literal table and the design kit.
- **From ZOD-L10-001 (2026-11-14):**
  - Add the sign, body, aspect and direction names as keys in `packages/shared_ui/lib/l10n/app_en.arb`, each with an `@key` description (`required-resource-attributes`), and add the same keys to `app_he.arb`. Then run `fvm flutter gen-l10n` in `packages/shared_ui`, and commit the ARB files and the generated files (`melos run l10n:check` fails otherwise).
  - Map the stable keys to the generated getters in code.
  - Screens and test harnesses register `const [ZodiannLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` (material_ui), never the generated `localizationsDelegates`.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
