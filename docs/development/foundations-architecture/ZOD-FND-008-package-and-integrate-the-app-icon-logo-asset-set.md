# ZOD-FND-008 - Package and integrate the app icon / logo asset set

## Metadata

- **ID:** ZOD-FND-008
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Done (Android and static iOS checks; the iOS on-device and Xcode check is [ZOD-IOS-004](../ios/tasks/ZOD-IOS-004-verify-the-launcher-icon-set-in-xcode-and-app-store-connect.md))
- **Scope:** MVP

## Description

Wire the existing logo artwork (already fully designed — not to be redesigned) as the launcher icon and the three in-app variants.

## Implementation Details

- Launcher icon: `design-reference/zodiann/assets/zodiann-logo.svg` (the tiled mark, corner radius 22%), rendered per-platform at the required launcher sizes.
- In-app dark-surface mark: `assets/zodiann-logo-on-dark.svg` (tile removed).
- In-app light-surface mark: `assets/zodiann-logo-on-light.svg` (deepened gradient `#be598e #826cc3 #1ba5ba`, empty cells at 6% black instead of 6% white).
- Never render the logo below 40px (hairlines blur at small raster sizes per MASTER.md §11).
- Use the PNG renders at 1024px as a high-resolution fallback where SVG isn't practical.

## Design Reference

`design-reference/zodiann/assets/zodiann-logo*.svg` and matching `.png` files; `design-reference/zodiann/MASTER.md` §11 "Iconography and assets" for sizing and placement rules; `design-reference/zodiann/DESIGN_DECISIONS.md` D5a for the rationale. This asset is fully specified — no design work remains, only integration.

## Acceptance Criteria

- [x] Launcher icon renders correctly at all required iOS/Android sizes. (Android adaptive icon checked on an emulator; legacy PNGs and the 15 iOS files verified statically: sizes, no alpha, corner gradient. The iOS on-device / Xcode check is [ZOD-IOS-004](../ios/tasks/ZOD-IOS-004-verify-the-launcher-icon-set-in-xcode-and-app-store-connect.md), criterion 1.)
- [x] Drawer header (40px), About hero (132px) use the correct dark/light variant automatically with theme. (Proven on `ZodiannLogo` at 40 and 132 in both themes with live switching; the drawer and About screens use it in NAV-002 / ABT-001.)
- [x] No instance of the logo renders below 40px anywhere in the app. (`ZodiannLogo` asserts, reports a squeezing parent, and a root guard requires `ZodiannSize.logo…` tokens. Launcher sizes below 40 are platform-mandated.)

## Dependencies

- [ZOD-FND-005](../foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) — Flutter app shell bootstrap (`apps/astro_mobile`)

## Specification References

- MASTER.md §11
- DESIGN_DECISIONS.md D5a

## Notes

- **Delivered:** `ZodiannLogo` (the two 1024 px PNGs, chosen by the app theme), the launcher icons generated from the SVGs (`tool/launcher/gen_launcher_icons.dart`; Android adaptive + legacy, iOS full-bleed opaque), and their checks. Plan: [`docs/plans/ZOD-FND-008-app-icon-logo-asset-set.md`](../../plans/ZOD-FND-008-app-icon-logo-asset-set.md).
- **Product-owner decisions (2026-11-16):** Android adaptive + legacy; iOS full-bleed opaque; this task owns the full launcher set (ZOD-REL-001 narrows to store assets); iOS verified statically only; AC2 proven at widget level.
- **Deviation:** the task allows the SVGs "with flutter_svg or the PNGs"; the 1024 px PNGs are used because `flutter_svg` is ruled out by the no-network guard.

- **iOS split (2026-11-24, owner decision):** the iOS on-device and Xcode check moved to [ZOD-IOS-004](../ios/tasks/ZOD-IOS-004-verify-the-launcher-icon-set-in-xcode-and-app-store-connect.md) together with ZOD-REL-001's iOS validation. Criterion 1 keeps its Android and static evidence.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
