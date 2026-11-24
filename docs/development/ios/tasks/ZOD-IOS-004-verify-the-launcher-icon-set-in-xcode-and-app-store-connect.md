# ZOD-IOS-004 - Verify the launcher icon set in Xcode and App Store Connect

## Metadata

- **ID:** ZOD-IOS-004
- **Category:** iOS (`ios/tasks/`)
- **Parent tasks:** [ZOD-FND-008](../../foundations-architecture/ZOD-FND-008-package-and-integrate-the-app-icon-logo-asset-set.md) (iOS on-device and Xcode check); [ZOD-REL-001](../../release-preparation/ZOD-REL-001-package-the-launcher-icon-and-store-metadata-assets.md) (iOS icon validation and variants)
- **Phase:** Phase 1 (the FND-008 check); the REL-001 part belongs to Phase 4
- **Priority:** Medium
- **Status:** Not Started (blocked: needs macOS and Xcode; see Notes)
- **Scope:** MVP

## Description

The 15 iOS launcher icon files were generated and checked statically (sizes, no alpha, corner gradient). This task checks them where iOS can judge them: Xcode, a device and App Store Connect, and adds the iOS-specific store variants.

## Implementation Details

Moved from ZOD-FND-008:

- Confirm the Xcode asset catalog accepts all 15 `AppIcon` files with no alpha warning, and that the icon renders correctly on an iOS device and in the App Store Connect preview.

Moved from ZOD-REL-001 (the Android and shared store assets stay there):

- Run the iOS store validation tooling (Xcode and App Store Connect) over the icon set.
- Consider the iOS 18 dark and tinted icon variants. Reuse `tool/launcher/gen_launcher_icons.dart` (`melos run launcher:check`) rather than exporting by hand.

## Design Reference

`design-reference/zodiann/assets/zodiann-logo.svg` (source) and `design-reference/zodiann/MASTER.md` §11. No new design is created.

## Acceptance Criteria

- [ ] Launcher icon renders correctly at all required iOS sizes, verified in Xcode and on a device. *(ZOD-FND-008 criterion 1, iOS on-device and Xcode clause.)*
- [ ] All required iOS icon sizes pass the App Store validation tooling. *(ZOD-REL-001 criterion 1, iOS clause: "…for both platforms … pass each store's validation tooling.")*

## Dependencies

- [ZOD-FND-008](../../foundations-architecture/ZOD-FND-008-package-and-integrate-the-app-icon-logo-asset-set.md) — Android and static half (Done)
- [ZOD-REL-001](../../release-preparation/ZOD-REL-001-package-the-launcher-icon-and-store-metadata-assets.md) — Android and shared half
- [ZOD-IOS-002](ZOD-IOS-002-verify-the-app-shell-build-and-runtime-on-ios.md) — needs a working iOS build

## Specification References

- MASTER.md §11

## Notes

- **Blocked: macOS access** (owner constraint 2026-11-20: no spending).
- The iOS 18 dark and tinted variants are listed in ZOD-REL-001's note as something to consider; whether to build them is decided here when the task is planned.

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
