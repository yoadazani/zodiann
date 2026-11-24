# ZOD-IOS-001 - Verify the Swiss Ephemeris and astronomy-engine FFI bindings on iOS

## Metadata

- **ID:** ZOD-IOS-001
- **Category:** iOS (`ios/tasks/`)
- **Parent tasks:** [ZOD-FND-003](../../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) (iOS half, split by the owner on 2026-11-20 and approved as a separate task on 2026-11-24); [ZOD-EPH-004](../../computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md) (iOS verification)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started (blocked: needs macOS and Xcode; see Notes)
- **Scope:** MVP

## Description

Prove on iOS what ZOD-FND-003 proved on Android (R-7, ARCH-6): the Swiss Ephemeris C library is bound through Dart FFI, built by the Flutter toolchain under Xcode, and packaged with its data files, and one real computation returns a correct longitude. Also run the astronomy-engine backup adapter (ZOD-EPH-004) on iOS.

## Implementation Details

Moved from ZOD-FND-003 (its Android and shared parts stay there):

- Extend `hook/build.dart` so the hook builds `libswisseph` for iOS (add `OS.iOS`, the iOS architectures and SDKs); `flutter build ios` succeeds. *Evidence: the build log and the linked binary.*
- Build via Xcode (iOS), or native assets if they hold on iOS (ARCH-6), and run one real computation (Sun longitude on a known date) on an iOS simulator or a device, compared against a known-good value.
- Package the ephemeris data files into the iOS app and read them from the iOS sandbox. *Evidence: the test's length check passes on iOS.*
- Run `apps/astro_mobile/integration_test/swiss_ephemeris_spike_test.dart` on an iOS simulator or device with the same flag and negative-control assertions as on Android. *Evidence: the run output.*
- Confirm or reverse the provisional native-assets-versus-Xcode decision (findings section 5). *Evidence: a note in the findings and in `docs/PROGRESS.md` Technical Decisions.*
- Record the iOS binary size and build time in the findings (section 4).
- The complete step list is `docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md` section 8; this task owns it. Findings sections for iOS are written here, not left as a checklist.

Moved from ZOD-EPH-004:

- Run the astronomy-engine iOS checklist in [`docs/spikes/ZOD-EPH-004-astronomy-engine-adapter.md`](../../../spikes/ZOD-EPH-004-astronomy-engine-adapter.md) section 9: build the shim for iOS from the same single source file, and run the adapter's tests (including `astronomy_speed_vs_swiss_test`) on an iOS simulator and a device. The Swiss half needs the iOS half of this task first. The tests do not change; a number that differs from the findings' tables on iOS is recorded, not silently adjusted.

## Design Reference

No direct design reference applies — native build spike.

## Acceptance Criteria

These are the iOS clauses of ZOD-FND-003's four criteria, unchanged in meaning (the Android clauses are verified in ZOD-FND-003), plus the ZOD-EPH-004 iOS verification:

- [ ] A single FFI call returns a correct longitude on an iOS build. *(FND-003 criterion 1, iOS clause: "…on both an Android and an iOS build.")*
- [ ] Data files are packaged and readable from the app sandbox on iOS. *(FND-003 criterion 2, iOS clause: "…on both platforms.")*
- [ ] Spike findings for iOS (build setup, gotchas, size) are written up for the team/agent picking up ZOD-EPH-002. *(FND-003 criterion 3, iOS part.)*
- [ ] The decision on native assets vs. CMake/Xcode for the production build is confirmed or reversed on the iOS evidence. *(FND-003 criterion 4: Android recorded the provisional decision; this confirms it for the production build.)*
- [ ] The astronomy-engine adapter builds and its tests pass on an iOS simulator and a device, per the ZOD-EPH-004 findings section 9. *(ZOD-EPH-004, iOS verification.)*

## Dependencies

- [ZOD-FND-003](../../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) — Android and shared half (Done)
- [ZOD-EPH-004](../../computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md) — Android and host half (Completed)
- [ZOD-IOS-002](ZOD-IOS-002-verify-the-app-shell-build-and-runtime-on-ios.md) — the app shell must build and run on iOS first

## Specification References

- ARCH-6
- R-7
- "Running Swiss Ephemeris in Flutter" (Decisions and implications)

## Notes

- **Blocked: macOS access.** iOS builds need macOS and Xcode. The owner allows no spending (2026-11-20): no paid macOS runner, no paid CI, no Mac purchase. The options are in `docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md` section 8; none is decided.
- **What this does not block.** ZOD-EPH-002, ZOD-FND-011 and ZOD-REL-002's Android and shared work no longer wait on this task (owner decision 2026-11-24). **Risk accepted by that decision:** if iOS shows the binding or the data-file packaging needs a different design, the shared adapter code in ZOD-EPH-002 may need rework; this task is the earliest point at which that shows.
- **Original task text.** The full original wording of ZOD-FND-003's criteria is preserved in that file (marked there as split); nothing was dropped.

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
