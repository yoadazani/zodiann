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

- **From ZOD-FND-010 (2026-11-19):** the license record is [`docs/decisions/ZOD-FND-010-swiss-ephemeris-license.md`](../../decisions/ZOD-FND-010-swiss-ephemeris-license.md). The product owner chose **Option A, the AGPL (Free Edition) path, for now**, for a public repository and packages shared with one friend for personal use. **The distribution channel was deliberately left to this task**, so the path is to be reconfirmed here against the channel you pick: if the app is to go to the Apple App Store or Google Play, be sold, or be closed-source, the record says to answer its question Q3 for Astrodienst or buy the Swiss Ephemeris Professional License (CHF 700, 6 years, at the time of reading) **before any store submission**, and not to assume AGPL is acceptable to the stores. R-6 stays open until this task confirms the path. Not legal advice.

- **iOS split (2026-11-24, owner decision):** this task keeps the shared decision (channel and licence path) and both its criteria unchanged. What applies only to the Apple App Store (the licence obligation before any App Store submission, if that channel is chosen) is tracked in [ZOD-IOS-010](../ios/tasks/ZOD-IOS-010-confirm-the-apple-app-store-path-and-its-licensing-obligations.md), conditional on the channel decided here.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Release Preparation" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
