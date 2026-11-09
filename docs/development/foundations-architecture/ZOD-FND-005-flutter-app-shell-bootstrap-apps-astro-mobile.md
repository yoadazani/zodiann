# ZOD-FND-005 - Flutter app shell bootstrap (`apps/astro_mobile`)

## Metadata

- **ID:** ZOD-FND-005
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Create the running Flutter application shell: entry point, dependency injection wiring, theme application, and the root widget tree that later navigation and screen work plugs into.

## Implementation Details

- Set up Riverpod as the app-wide state management root (ARCH-3).
- Wire dependency injection so `EphemerisPort` implementations (Swiss Ephemeris primary, astronomy-engine backup) are swappable with a single provider override (ARCH-4).
- Apply the light/dark `ThemeData` produced in [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) at the root.
- Set up `flutter_localizations` and the `intl` package scaffolding (consumed fully in ZOD-L10 tasks).

## Design Reference

No direct design reference applies to wiring; the resulting shell's visual chrome is covered by ZOD-NAV tasks referencing `design-reference/zodiann/MASTER.md` §5.

## Acceptance Criteria

- [ ] App boots to a blank themed screen on iOS and Android.
- [ ] Swapping the injected `EphemerisPort` (e.g., to a fake) requires touching only the DI wiring, not feature code.
- [ ] Riverpod devtools show one provider scope per screen once screens exist.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace
- [ZOD-FND-002](../foundations-architecture/ZOD-FND-002-define-the-ephemerisport-interface-contract.md) — Define the `EphemerisPort` interface contract

## Specification References

- ARCH-2
- ARCH-3
- ARCH-4

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
