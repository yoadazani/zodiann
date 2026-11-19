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

- **From ZOD-FND-007 (2026-11-13):** the bundled fonts are IBM Plex Sans, IBM Plex Sans Hebrew, Noto Sans Symbols, Noto Sans Symbols 2 **and Noto Sans** (third glyph fallback for ℞, product-owner decision), all SIL OFL 1.1. Each licence ships as an asset at `packages/shared_ui/assets/fonts/<family>/OFL.txt` (asset key `packages/shared_ui/assets/fonts/<family>/OFL.txt`); register and show all five. Sources and versions: `packages/shared_ui/assets/fonts/SOURCES.md`.

- **From ZOD-FND-010 (2026-11-19):** the Swiss Ephemeris chip shows the **AGPL path** chosen in [`docs/decisions/ZOD-FND-010-swiss-ephemeris-license.md`](../../decisions/ZOD-FND-010-swiss-ephemeris-license.md): AGPL attribution, and the location of the public source that matches each build (the repository and tag). It is not a commercial-license text. The text depends on the final path: ZOD-REL-003 reconfirms the path against the distribution channel, so update the chip if that changes it. Also check the other listed dependencies and fonts for AGPL compatibility, which the record leaves open.
---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "About & Sources" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*

- **From ZOD-UI-009 (2026-11-17):** the licence names are `ZodiannTag(variant: ZodiannTagVariant.neutral, ...)` inside an LTR `Directionality` (kit's `.ltr`).
