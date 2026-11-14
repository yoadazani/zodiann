# ZOD-L10-013 - Resolve and document the symbol-translation open decision

## Metadata

- **ID:** ZOD-L10-013
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 1 (decision), ongoing (content)
- **Priority:** Medium
- **Status:** In Progress
- **Scope:** MVP

## Description

Confirm and document the open decision on whether astrological symbols/terms are translated per each language's tradition (the plan's assumed default) or kept uniform — this gates every translated string in ZOD-L10-007/020.

## Implementation Details

- The spec explicitly assumes full translation per tradition as its working default (open decision, "Translation and content" section) — confirm this with the product owner before translation content work proceeds at scale.
- Document the final decision so ZOD-L10-007's Hebrew terminology work has an unambiguous source of truth.

## Design Reference

`design-reference/zodiann/screens/*_he_*` already assume full per-tradition translation (DESIGN_DECISIONS D20) — confirm this matches the final product decision before treating it as settled.

## Acceptance Criteria

- [ ] A written decision record exists, consistent with or explicitly overriding D20.
- [ ] ZOD-L10-007's Hebrew terminology work cites this decision record.

## Dependencies

_None — this task has no prerequisites._

## Specification References

- "Open decision" under "Translation and content"
- D20

## Notes

- This task intersects an open decision recorded in `TASKS.md` §6 "Open decisions and blockers" — review it before implementing.
- **Decision record (2026-11-14, product owner):**
  - **D20 is confirmed.** Astrological names (signs, bodies, the node, aspects, directions) are translated per each language's tradition, not kept uniform.
  - **Aspects:** the design's Hebrew names (T2): צמידות, סקסטייל, ריבוע, טריין, אופוזיציה. This includes the established transliterations סקסטייל, טריין, אופוזיציה.
  - **Outer planets:** the common Hebrew names אורנוס, נפטון, פלוטו (T3), not the Academy of the Hebrew Language's proposals (אורון, רהב). These planets have no traditional Hebrew names, so this is a **recorded exception** to ZOD-L10-007 criterion 2's "not transliteration". That criterion is met for every sign, the classical bodies (שמש, ירח, כוכב חמה, נוגה, מאדים, צדק, שבתאי) and the node (ראש הדרקון).
  - **Source of truth:** `packages/shared_ui/lib/l10n/app_he.arb`, pinned by `packages/shared_ui/test/l10n/entity_names_test.dart` against the design kit (`design-reference/zodiann/_source/kit.js`).
  - **Plan:** [`docs/plans/ZOD-L10-007-ZOD-L10-013-entity-keys.md`](../../plans/ZOD-L10-007-ZOD-L10-013-entity-keys.md) (decisions T1–T4).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
