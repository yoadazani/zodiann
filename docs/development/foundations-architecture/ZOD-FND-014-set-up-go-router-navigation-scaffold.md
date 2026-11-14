# ZOD-FND-014 - Set up `go_router` navigation scaffold

## Metadata

- **ID:** ZOD-FND-014
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done
- **Scope:** MVP

## Description

Stand up the routing foundation (empty route stubs) that ZOD-NAV tasks build the real drawer and screen behavior on top of.

## Implementation Details

- Register the five routes from the Navigation table: `#wheel` (default), `#square`, `#saved`, `#settings`, `#about`.
- Confirm the hash values are route identifiers only, not web addresses (per spec note).
- Stub an "unknown route" redirect to `#wheel`.

## Design Reference

No direct design reference applies to routing logic; the resulting screen chrome is covered in ZOD-NAV tasks.

## Acceptance Criteria

- [x] All five routes resolve to a (currently blank) screen stub.
- [x] An unrecognized route redirects to the wheel screen.

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- NAV-5
- Navigation table

## Notes

- 2026-11-14 (done; plan [`docs/plans/ZOD-FND-014-go-router-navigation-scaffold.md`](../../plans/ZOD-FND-014-go-router-navigation-scaffold.md)):
  - **Identifiers:** `AppRoute` (`apps/astro_mobile/lib/src/navigation/app_route.dart`) lists the five screens in the table's order. The spec's `#wheel` is `'#' + name`; the `go_router` location is `path` = `'/' + name`. These are identifiers only, with no URL strategy configured.
  - **Router:** one `GoRouter` from `buildAppRouter({initialLocation})`, held in `appRouterProvider` so app rebuilds never reset the screen.
  - **Unknown routes:** any unmatched location (`/`, `/nope`, `/wheel/extra`, wrong case), at startup or at runtime, is sent by a top-level redirect to `/wheel`. A query string or a trailing slash stays on its route.
  - **Stubs:** each route shows a blank `ScreenStub(route:)`, which replaces `ShellHome`.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
