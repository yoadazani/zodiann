# ZOD-ABT-002 - Build the Computation sources table

## Metadata

- **ID:** ZOD-ABT-002
- **Category:** [About & Sources](../README.md#about) (`about/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the table listing each position source's role and accuracy, matching Appendix F / "Data sources, in order of priority."

## Implementation Details

- Rows: Swiss Ephemeris (JPL data files) — Primary source — Sub-arcsecond; Swiss Ephemeris (Moshier) — fallback message — Lower than files; astronomy-engine — Backup and test comparison — arcminute or better; JPL Horizons — Reference data for tests only — The reference.
- Contains the Latin-script source names embedded in Hebrew text — explicitly exercises ZOD-L10-006's bidi isolation.

## Design Reference

`design-reference/zodiann/screens/05-about-sources_desktop_en_dark.png` "Computation sources" table (exact rows/columns).

## Acceptance Criteria

- [ ] Table content matches the "Data sources, in order of priority" spec table exactly.
- [ ] Source names render correctly isolated in the Hebrew build (verified jointly with ZOD-L10-006).

## Dependencies

- [ZOD-ABT-001](../about/ZOD-ABT-001-build-the-about-screen-hero.md) — Build the About screen hero
- ZOD-L10-006

## Specification References

- "Data sources, in order of priority"
- Appendix F
- MASTER.md §9

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "About & Sources" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
