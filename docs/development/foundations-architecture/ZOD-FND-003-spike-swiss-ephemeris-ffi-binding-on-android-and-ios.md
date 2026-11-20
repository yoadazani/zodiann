# ZOD-FND-003 - Spike: Swiss Ephemeris FFI binding on Android and iOS

## Metadata

- **ID:** ZOD-FND-003
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** In Progress (Android half verified; iOS half pending: see Completion notes)
- **Scope:** MVP

## Description

De-risk the single biggest technical unknown (R-7) before any feature work starts: prove that the Swiss Ephemeris C library can be bound via Dart FFI, built via the Flutter toolchain, and packaged with its data files, on both target platforms.

## Implementation Details

- Vendor the Swiss Ephemeris C source into `native/swisseph/`.
- Generate Dart bindings with `ffigen`.
- Build via CMake (Android) and Xcode (iOS), or native assets if stable enough at the time of implementation (ARCH-6).
- Run one real computation (e.g., Sun longitude on a known date) on a physical or emulated device of each platform and compare against a known-good value.
- Decide and document how the ephemeris data files are packaged as app assets and loaded at runtime (flat files vs. compressed bundle).
- Record build-time, binary-size, and licensing findings for [ZOD-REL-003](../release-preparation/ZOD-REL-003-finalize-store-distribution-and-swiss-ephemeris-licensing-path.md).

## Design Reference

No direct design reference applies — native build spike.

## Acceptance Criteria

- [ ] A single FFI call returns a correct longitude on both an Android and an iOS build.
- [ ] Data files are packaged and readable from the app sandbox on both platforms.
- [ ] Spike findings (build setup, gotchas, size) are written up for the team/agent picking up ZOD-EPH-002.
- [ ] A decision is recorded on native assets vs. CMake/Xcode for the production build.

## Dependencies

- [ZOD-FND-001](../foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) — Set up the Melos monorepo workspace

## Specification References

- ARCH-6
- R-7
- "Running Swiss Ephemeris in Flutter" (Decisions and implications)

## Notes

- **From ZOD-FND-015 (2026-11-20):** when this task vendors the Swiss Ephemeris source (and any data files), it must preserve the original Swiss Ephemeris license and copyright files and notices unchanged, and record the exact upstream version and where it came from, so [ZOD-FND-015](ZOD-FND-015-apply-the-agpl-decision-to-the-repository.md)'s inventory and source policy can cover it. ZOD-FND-015 is recommended before this task adds Swiss Ephemeris to the repository (licensing decision: `docs/decisions/ZOD-FND-010-swiss-ephemeris-license.md`). Scope and criteria of this task are unchanged.

## Completion notes

*Written 2026-11-20 on branch `task/ZOD-FND-003-swiss-ephemeris-ffi-spike-android`. The owner split this task: the Android half was implemented and verified locally on Windows; the iOS half stays pending because macOS access is unavailable and no spending is allowed (no paid macOS runner, no paid CI, no Mac purchase). **The task is not complete and its four criteria stay unchecked until a real iOS computation is verified.** Verification commands, results and the commit they cover are in `docs/PROGRESS.md` (Verification); the findings and the iOS checklist are in [`docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md`](../../spikes/ZOD-FND-003-swiss-ephemeris-ffi.md); the plan is [`docs/plans/ZOD-FND-003-swiss-ephemeris-ffi-spike-android.md`](../../plans/ZOD-FND-003-swiss-ephemeris-ffi-spike-android.md).*

1. **Criterion 1 (a single FFI call returns a correct longitude on both Android and iOS): Android verified, iOS open.** On the `Pixel_9_Pro_API_35` x86_64 emulator, Sun and Moon at three UT instants are within 0.03 to 0.24 arcseconds of JPL Horizons, with the Swiss Ephemeris flag set and no warning; an empty-directory control falls back to Moshier. arm64-v8a and armeabi-v7a were built and alignment-checked but not executed. iOS: not attempted.
2. **Criterion 2 (data files packaged and readable from the app sandbox on both platforms): Android verified, iOS open.** The `.se1` files are in the APK under `flutter_assets/packages/ephemeris_swiss/assets/ephe/` and are read from the app's files directory. iOS: not attempted.
3. **Criterion 3 (findings written up for the agent picking up ZOD-EPH-002): written for Android; incomplete.** The findings document covers the Android build, gotchas, measurements and what EPH-002 must know. The iOS sections are an explicit checklist, not results.
4. **Criterion 4 (native assets versus CMake/Xcode decision recorded): provisional.** Native assets were chosen on the Android evidence; the decision is confirmed or reversed by the iOS half (condition stated in the findings, section 5).

**Remaining to close this task:** the iOS checklist in the findings, section 8. Every task that lists this one under Dependencies (ZOD-EPH-002, ZOD-FND-011, ZOD-NFR-011, ZOD-REL-002) stays blocked meanwhile.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
