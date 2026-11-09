# ZOD-NFR-016 - Pin all dependency versions and audit for runtime network/script loading

## Metadata

- **ID:** ZOD-NFR-016
- **Category:** [Performance, Accessibility & Reliability](../README.md#performance-accessibility-reliability) (`performance-accessibility-reliability/`)
- **Phase:** Phase 1, ongoing
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Ensure every third-party dependency is pinned to an exact version and that nothing in the app loads a script or resource from the network at runtime beyond the declared, bundled dependencies.

## Implementation Details

- Pin every `pubspec.yaml` dependency to an exact version (no caret ranges that could silently pull in a new, unaudited version).
- Audit for any dynamic code/asset loading mechanism that could reach the network (distinct from, but complementary to, [ZOD-DAT-011](../settings-persistence/ZOD-DAT-011-verify-no-network-analytics-third-party-data-paths-exist.md)'s data-privacy audit — this task is specifically about NFR-R3's "no external scripts at runtime" wording).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] NFR-R3 passes: no network data transmission, all dependencies pinned, no runtime external script loading.
- [ ] `pubspec.yaml` contains no unpinned (`^`-only) version constraint for a production dependency.

## Dependencies

- [ZOD-DAT-011](../settings-persistence/ZOD-DAT-011-verify-no-network-analytics-third-party-data-paths-exist.md) — Verify no network/analytics/third-party data paths exist

## Specification References

- NFR-R3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Performance, Accessibility & Reliability" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
