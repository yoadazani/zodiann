# ZOD-FND-010 - Research and document the Swiss Ephemeris license decision

## Metadata

- **ID:** ZOD-FND-010
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Done (see Notes)
- **Scope:** MVP

## Description

This is a non-code research task that blocks a store-distribution decision: Swiss Ephemeris is AGPL or requires a paid Astrodienst professional license, and publishing closed-source code in the app stores likely requires the latter (R-6).

## Implementation Details

- Contact Astrodienst (or review their current published terms) to confirm current licensing options and cost.
- Document the decision (AGPL + open-source the app, or purchase the professional license) in a decision record.
- Feed the outcome into [ZOD-REL-003](../release-preparation/ZOD-REL-003-finalize-store-distribution-and-swiss-ephemeris-licensing-path.md) (store distribution) and the About screen's "Open-source licenses" list ([ZOD-ABT-007](../about/ZOD-ABT-007-build-the-open-source-licenses-list.md)).

## Design Reference

No direct design reference applies — this is a legal/licensing research task, not a code or design task. This is not legal advice.

## Acceptance Criteria

- [x] A written decision record exists stating which license path was chosen and why. (`docs/decisions/ZOD-FND-010-swiss-ephemeris-license.md`: Option A, AGPL for now, chosen by the product owner on 2026-11-19; sourced against the vendor's pages, the contract and the AGPL, with confirmed facts kept apart from interpretations and open questions)
- [x] The decision is referenced by ZOD-REL-003 before any store submission. (a Note in ZOD-REL-003 points to the record and says the path is reconfirmed against the channel; ZOD-REL-003 depends on this task)

## Dependencies

_None — this task has no prerequisites._

## Specification References

- R-6
- "License" row in "Decisions and implications"
- Appendix F

## Notes

- **Decision (2026-11-19, product owner):** Option A, the AGPL path, for now. The distribution channel was left to ZOD-REL-003 (decision D1), which reconfirms the path; R-6 stays open until then. Nothing was purchased or sent to Astrodienst. Four drafted questions for Astrodienst are in the record (section 8). Follow-ups that need the owner's approval, not done here: license the repository AGPL before the first package goes out, tag each build, ABT-007 text. Not legal advice.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
