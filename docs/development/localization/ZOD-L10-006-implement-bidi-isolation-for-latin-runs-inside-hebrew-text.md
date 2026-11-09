# ZOD-L10-006 - Implement bidi isolation for Latin runs inside Hebrew text

## Metadata

- **ID:** ZOD-L10-006
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Wrap every Latin-script run (proper nouns, library names, timezone identifiers, JSON snippets) embedded in Hebrew sentences in a directional isolate, so mixed text never scrambles.

## Implementation Details

- Use FSI/PDI Unicode isolates (`⁨ … ⁩`) or per-span `Directionality`, per MASTER.md §13's explicit guidance and examples ("Swiss Ephemeris", "Asia/Jerusalem (UTC+2)", "JSON").
- Dates/times stay LTR as **one** unit, e.g. `22.11.26  07:36`, never split across isolation boundaries.
- Never force LTR on a string that *also* contains Hebrew words (MASTER.md explicitly calls out this exact mistake as something the mockups demonstrate going wrong).

## Design Reference

`design-reference/zodiann/MASTER.md` §13 "Isolation" (the authoritative guidance, including the explicit warning about what goes wrong when done incorrectly — inspect the Hebrew screenshots in `design-reference/zodiann/screens/*_he_*` for any Latin-in-Hebrew text, e.g., the About screen's "Swiss Ephemeris" references, for the correct rendering to match).

## Acceptance Criteria

- [ ] Every Latin run inside a Hebrew sentence in the app (About sources, settings time-zone label, etc.) renders correctly isolated, matching the `_he_` screenshots.
- [ ] A date/time string never splits across a line or visual direction boundary.

## Dependencies

- ZOD-L10-004
- [ZOD-ABT-002](../about/ZOD-ABT-002-build-the-computation-sources-table.md) — Build the Computation sources table

## Specification References

- L-7
- MASTER.md §13

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
