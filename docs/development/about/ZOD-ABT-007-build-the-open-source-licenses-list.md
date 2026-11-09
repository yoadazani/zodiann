# ZOD-ABT-007 - Build the Open-source licenses list

## Metadata

- **ID:** ZOD-ABT-007
- **Category:** [About & Sources](../README.md#about) (`about/`)
- **Phase:** Phase 4
- **Priority:** Low
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the chip list of every open-source dependency the app ships with attribution.

## Implementation Details

- Chips: Swiss Ephemeris, astronomy-engine, Flutter, Riverpod, go_router, drift, IBM Plex, Noto Sans Symbols — and any dependency added later must be added here too (standing process note).
- Swiss Ephemeris's chip/license text depends on the outcome of [ZOD-FND-010](../foundations-architecture/ZOD-FND-010-research-and-document-the-swiss-ephemeris-license-decision.md)'s license research (AGPL attribution text differs from a commercial-license attribution).

## Design Reference

`design-reference/zodiann/screens/05-about-sources_desktop_en_dark.png` "Open-source licenses" chip row (exact dependency list shown as a baseline — update to match the actual final dependency set).

## Acceptance Criteria

- [ ] Every runtime dependency with a license obligation is listed.
- [ ] Swiss Ephemeris's listed license matches the decision recorded in ZOD-FND-010.

## Dependencies

- [ZOD-ABT-001](../about/ZOD-ABT-001-build-the-about-screen-hero.md) — Build the About screen hero
- [ZOD-FND-010](../foundations-architecture/ZOD-FND-010-research-and-document-the-swiss-ephemeris-license-decision.md) — Research and document the Swiss Ephemeris license decision

## Specification References

- Appendix F
- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "About & Sources" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
