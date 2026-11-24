# ZOD-IOS-010 - Confirm the Apple App Store path and its licensing obligations

## Metadata

- **ID:** ZOD-IOS-010
- **Category:** iOS (`ios/tasks/`)
- **Parent task:** [ZOD-REL-003](../../release-preparation/ZOD-REL-003-finalize-store-distribution-and-swiss-ephemeris-licensing-path.md) (the Apple App Store part of the channel and licensing decision)
- **Phase:** Phase 4
- **Priority:** Critical
- **Status:** Not Started (conditional: only if the Apple App Store is chosen as a channel)
- **Scope:** MVP

## Description

ZOD-REL-003 decides the distribution channel and the licensing path together, for both stores, and keeps that decision. This task holds what applies only to the Apple App Store, so it is not lost if the channel is chosen.

## Implementation Details

Moved from ZOD-REL-003's note (the product-owner record of 2026-11-19, `docs/decisions/ZOD-FND-010-swiss-ephemeris-license.md`):

- If the app is to go to the Apple App Store, the AGPL path must not be assumed acceptable to the store. Before any App Store submission, answer question Q3 for Astrodienst or buy the Swiss Ephemeris Professional License (CHF 700, 6 years, at the time of reading). Not legal advice.
- Record the Apple-specific distribution obligations that follow (store terms against the AGPL, the source-availability policy checklist in `docs/licensing/source-availability-policy.md`), and keep ZOD-ABT-007's licence list in step with the final decision.

If the owner chooses a private or non-Apple-store channel for iOS, this task is closed as not applicable with that decision recorded.

## Design Reference

No direct design reference applies — this is not legal advice.

## Acceptance Criteria

- [ ] The written decision of ZOD-REL-003 states, for iOS, whether the Apple App Store is a channel and, if it is, the licence obligation that applies before submission. *(ZOD-REL-003 criterion 1, iOS clause: "A written decision exists covering both distribution channel and the resulting license obligation.")*

## Dependencies

- [ZOD-REL-003](../../release-preparation/ZOD-REL-003-finalize-store-distribution-and-swiss-ephemeris-licensing-path.md) — the shared decision (the channel and the licence path)

## Specification References

- R-6
- "Distribution through the stores..." (Questions to answer before professional development)

## Notes

- ZOD-REL-003 keeps its description, its second criterion (the About list matches the final decision) and the Google Play side. Nothing about the shared decision moves.
- No macOS access is needed for this task; it is a decision.

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
