# ZOD-DAT-011 - Verify no network/analytics/third-party data paths exist

## Metadata

- **ID:** ZOD-DAT-011
- **Category:** [Settings & Persistence](../README.md#settings-persistence) (`settings-persistence/`)
- **Phase:** Phase 4
- **Priority:** High
- **Status:** Not Started
- **Scope:** MVP

## Description

Audit the dependency tree and runtime behavior to confirm the app never sends data off-device, has no analytics/crash reporting, and that every third-party dependency was checked for this before being added.

## Implementation Details

- Review every package dependency (including transitive ones pulled in by Swiss Ephemeris/astronomy-engine FFI wrappers, drift, etc.) for any network call.
- Confirm no crash-reporting or analytics SDK is present anywhere in the dependency graph.
- Document the review as a standing checklist item for any future dependency addition.

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] A network-traffic capture during a full manual walkthrough of the app shows zero outbound requests.
- [ ] No analytics/crash-reporting package appears in `pubspec.lock`.

## Dependencies

- [ZOD-FND-006](../foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) — Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1
- [ZOD-FND-007](../foundations-architecture/ZOD-FND-007-bundle-offline-fonts-and-verify-no-network-dependency.md) — Bundle offline fonts and verify no network dependency

## Specification References

- DATA-5
- DATA-6
- DATA-7
- DATA-8
- NFR-R3

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Settings & Persistence" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
