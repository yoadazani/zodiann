# ZOD-IOS-007 - Configure and verify iOS deep links

## Metadata

- **ID:** ZOD-IOS-007
- **Category:** iOS (`ios/tasks/`)
- **Parent task:** [ZOD-NAV-003](../../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md) (iOS deep-link configuration; scope transfer approved by the owner on 2026-11-24)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started (blocked: needs macOS and Xcode; see Notes)
- **Scope:** MVP

## Description

ZOD-NAV-003 wired drawer navigation and deep links through `go_router`. Its notes say the Android and iOS link configuration belongs to it and that iOS `zodiann://` link delivery is unverified. The iOS configuration and verification move here; NAV-003 keeps its Done status for its Android and shared work.

## Implementation Details

- Configure iOS to deliver the app's links (the `zodiann://` scheme and any route such as `#square`) to Flutter's deep-link handling (`Info.plist`; Flutter's deep linking is on by default but the iOS side needs the declared scheme).
- Verify on an iOS simulator and a device that a cold-start link opens the requested screen directly, and that an unknown route falls back to the wheel screen (NAV-5).

## Design Reference

No direct design reference applies.

## Acceptance Criteria

- [ ] On iOS, a deep link opens the requested screen directly on cold start. *(ZOD-NAV-003 criterion 1, iOS clause of "a deep link opens the requested screen directly" within T-UI-1. The drawer navigation and Android deep-link parts are verified in NAV-003; the relaunch clause closes in ZOD-DAT-007.)*
- [ ] An unknown route on iOS falls back to the wheel screen. *(NAV-003 implementation detail, iOS run.)*

## Dependencies

- [ZOD-NAV-003](../../navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md) — Android and shared half (Done)
- [ZOD-IOS-002](ZOD-IOS-002-verify-the-app-shell-build-and-runtime-on-ios.md) — needs a working iOS build

## Specification References

- NAV-5
- T-UI-1

## Notes

- **Blocked: macOS access** (owner constraint 2026-11-20: no spending).
- **Scope transfer.** ZOD-NAV-003 stays Done. The transfer is recorded in that file's Notes.

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
