# ZOD-REL-001 - Package the launcher icon and store metadata assets

## Metadata

- **ID:** ZOD-REL-001
- **Category:** [Release Preparation](../README.md#release-preparation) (`release-preparation/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Finalize the platform-specific launcher-icon exports and any store-listing image assets derived from the already-designed logo.

## Implementation Details

- Generate the full iOS/Android launcher icon size set from `assets/zodiann-logo.svg` ([ZOD-FND-008](../foundations-architecture/ZOD-FND-008-package-and-integrate-the-app-icon-logo-asset-set.md)'s source asset).
- No new visual design is created here — this is packaging work only.

## Design Reference

`design-reference/zodiann/assets/zodiann-logo.svg` (source), `design-reference/zodiann/MASTER.md` §11.

## Acceptance Criteria

- [ ] All required icon sizes for both platforms are generated and pass each store's validation tooling.

## Dependencies

- [ZOD-FND-008](../foundations-architecture/ZOD-FND-008-package-and-integrate-the-app-icon-logo-asset-set.md) — Package and integrate the app icon / logo asset set

## Specification References

- MASTER.md §11

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Release Preparation" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
