# ZOD-REL-003 - Finalize store-distribution and Swiss Ephemeris licensing path

## Metadata

- **ID:** ZOD-REL-003
- **Category:** [Release Preparation](../README.md#release-preparation) (`release-preparation/`)
- **Phase:** Phase 4
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Resolve the distribution-channel decision (App Store/Google Play vs. private installation) together with the licensing decision from [ZOD-FND-010](../foundations-architecture/ZOD-FND-010-research-and-document-the-swiss-ephemeris-license-decision.md), since the two are linked.

## Implementation Details

- Confirm which distribution channel is intended (blocks whether the AGPL or paid-professional-license path is required).
- Finalize licensing with Astrodienst accordingly, and update [ZOD-ABT-007](../about/ZOD-ABT-007-build-the-open-source-licenses-list.md)'s license list to match.

## Design Reference

No direct design reference applies — this is not legal advice.

## Acceptance Criteria

- [ ] A written decision exists covering both distribution channel and the resulting license obligation.
- [ ] The About screen's license list (ZOD-ABT-007) matches the final decision.

## Dependencies

- [ZOD-FND-010](../foundations-architecture/ZOD-FND-010-research-and-document-the-swiss-ephemeris-license-decision.md) — Research and document the Swiss Ephemeris license decision
- [ZOD-ABT-007](../about/ZOD-ABT-007-build-the-open-source-licenses-list.md) — Build the Open-source licenses list

## Specification References

- R-6
- "Distribution through the stores..." (Questions to answer before professional development)

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Release Preparation" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
