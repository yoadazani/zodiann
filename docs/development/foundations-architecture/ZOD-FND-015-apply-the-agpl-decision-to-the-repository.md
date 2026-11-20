# ZOD-FND-015 - Apply the AGPL decision to the repository

## Metadata

- **ID:** ZOD-FND-015
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done (see Notes)
- **Scope:** MVP

## Description

[ZOD-FND-010](ZOD-FND-010-research-and-document-the-swiss-ephemeris-license-decision.md) recorded the product owner's decision: **Option A, the AGPL path, for now** (`docs/decisions/ZOD-FND-010-swiss-ephemeris-license.md`). The repository is public today with **no license file**, so the decision is not yet applied. This task applies it to the repository: the license text and notices, a verified inventory of third-party components and project-owned assets, and a written source-availability and release-tag policy. It is a documentation task; it changes no application code and no dependency. It is not legal advice and makes no compliance claim.

## Implementation Details

- Add the unmodified GNU AGPL-3.0 text as `LICENSE`, with a statement of what it covers and what it does not (third-party components and any excluded project-owned assets keep their own terms).
- Build a third-party inventory: every direct and transitive Dart/Flutter dependency (runtime, dev, test), the Flutter and Dart SDKs and engine, native and platform dependencies, fonts, images, icons, logos and other assets. Each row records the license, the verification source and the verification date; anything not verified is marked `Unverified`.
- Record the product owner's licensing decision for the project-owned assets (logo, icons, design-reference material, specification files): which are covered by AGPL-3.0, which are distributed under a separate license, and which are explicitly excluded.
- Write the source-availability and release-tag policy: each distributed build maps to one exact public Git tag, the Corresponding Source for that tag is available at a stated place together with the build scripts and materials the license requires, and a public repository alone is not assumed to satisfy the license.
- Keep the unresolved legal questions listed (Astrodienst Q2 data files, Q4 switching, OFL fonts against AGPL, store terms) and separate verified facts from technical interpretations and questions for Astrodienst or a lawyer.
- Coordinate with [ZOD-FND-003](ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) (preserve the original Swiss Ephemeris license and copyright files) and [ZOD-ABT-007](../about/ZOD-ABT-007-build-the-open-source-licenses-list.md) (consume the inventory) by Notes only.
- Out of scope: CI, the About screen implementation, vendoring Swiss Ephemeris, any source or dependency change, sending questions to Astrodienst, the store-distribution decision ([ZOD-REL-003](../release-preparation/ZOD-REL-003-finalize-store-distribution-and-swiss-ephemeris-licensing-path.md)).

## Design Reference

No direct design reference applies — this is a licensing and documentation task. This is not legal advice.

## Acceptance Criteria

- [x] `LICENSE` at the repository root is the unmodified AGPL-3.0 text, with its source URL and access date recorded, and the README states what the license covers and where the source is. (`LICENSE` sha256 `0d96a4ff…` equals the gnu.org text fetched and re-fetched on 2026-11-20; source and date in the decision record, section 3; README "License" section)
- [x] A third-party inventory covers every dependency (direct and transitive, all scopes), the SDKs and engine, native and platform dependencies, fonts and assets, each with license, verification source and date; unverified entries are marked `Unverified`. (`docs/licensing/third-party-inventory.md`: all 100 lock entries once each, 7 `Unverified`; SDKs, engine, Android and iOS, native, fonts and asset groups in sections 3 to 7)
- [x] The product owner's decision on the project-owned assets is recorded (covered, separately licensed or excluded, per asset group). (inventory section 6 and decision record section 2: D1 AGPL-3.0 for (a)–(e) and (g), (f) separate, D6 none)
- [x] A written source-availability and release-tag policy states how each distributed build maps to an exact public tag and where its Corresponding Source is. (`docs/licensing/source-availability-policy.md`)
- [x] Unresolved questions (Q2, Q4, OFL against AGPL, store terms, others found) are listed as unresolved, and no document claims legal compliance or clearance. (decision record section 6: Q2, Q4, Q5, Q-L1 to Q-L6; section 7 states what is not established)

## Dependencies

- [ZOD-FND-010](ZOD-FND-010-research-and-document-the-swiss-ephemeris-license-decision.md) — Research and document the Swiss Ephemeris license decision

## Specification References

- R-6
- "License" row in "Decisions and implications"
- Appendix F

## Notes

- **Done (2026-11-20; plan [`docs/plans/ZOD-FND-015-agpl-repository-licensing.md`](../../plans/ZOD-FND-015-agpl-repository-licensing.md)):** documentation only, no code and no test run; verification is the source and completeness checks recorded in `docs/PROGRESS.md`. Findings left for the owner: F1 (the reference woff2 fonts in `design-reference/` have no license text beside them) and D4 and D5 follow-ups (per-file headers; an inventory staleness guard). Open legal and technical questions stay open (decision record, section 6). Not legal advice.

- **Timing (2026-11-20, product owner):** recommended before any build is distributed and before Swiss Ephemeris components enter the repository ([ZOD-FND-003](ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md)); it is **not** a blocker for [ZOD-FND-004](ZOD-FND-004-set-up-the-ci-pipeline.md) (CI).
- **Owner decisions (2026-11-20):** copyright line `Copyright (C) 2026 Yoad Azani`; **`AGPL-3.0-only`** (D2) applies to the project-authored asset groups (logo, icons, generated icon code, design reference, specifications, fixtures, source, translations, scripts, docs) but **not** to third-party assets or dependencies, which keep their own licenses; the name "Zodiann" gets no trademark statement (D6); the owner states they created those materials; both Git identities are theirs; AI co-authorship is recorded as an Open legal question and does not block this task; read-only `gh` queries are authorized. This does not mean Astrodienst's own terms are clarified: its AGPL version wording (drafted Q5), Q2, Q4 and the other listed legal questions remain open. Not legal advice.
- The ID `ZOD-FND-014` was already used by the `go_router` task, so this task is `ZOD-FND-015`.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
