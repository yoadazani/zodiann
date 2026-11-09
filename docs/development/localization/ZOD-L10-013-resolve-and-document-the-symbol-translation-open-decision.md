# ZOD-L10-013 - Resolve and document the symbol-translation open decision

## Metadata

- **ID:** ZOD-L10-013
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 1 (decision), ongoing (content)
- **Priority:** Medium
- **Status:** Not Started
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

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
