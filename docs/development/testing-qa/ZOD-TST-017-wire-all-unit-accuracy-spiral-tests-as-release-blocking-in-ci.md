# ZOD-TST-017 - Wire all unit/accuracy/spiral tests as release-blocking in CI

## Metadata

- **ID:** ZOD-TST-017
- **Category:** [Testing & QA](../README.md#testing-qa) (`testing-qa/`)
- **Phase:** Phase 1, ongoing
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Confirm Gate 1 ("core passes every accuracy test") is enforced mechanically, not just by policy — every test in [ZOD-TST-001](../testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md) through 013 must block merge/release, not just run and report.

## Implementation Details

- Extends [ZOD-FND-004](../foundations-architecture/ZOD-FND-004-set-up-the-ci-pipeline.md)'s general CI wiring with an explicit "Gate 1" required-checks group covering T-EPH-*, T-CRS-*, T-ASP-1, T-GAN-*, T-FMT-1, and the ACC-* suites.
- Document which checks constitute Gate 1 so a future contributor can see at a glance what "the core passes every accuracy test" means mechanically.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A PR that breaks any Gate-1 test cannot merge.
- [ ] The Gate-1 check group is documented (e.g., in the CI config or a short README) so its scope is unambiguous.

## Dependencies

- [ZOD-FND-004](../foundations-architecture/ZOD-FND-004-set-up-the-ci-pipeline.md) — Set up the CI pipeline
- [ZOD-TST-001](../testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md) through [ZOD-TST-013](../testing-qa/ZOD-TST-013-author-the-date-format-test-t-fmt-1.md)

## Specification References

- "Roadmap and development phases" Gate 1
- "Automated tests in the pipeline"

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Testing & QA" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
