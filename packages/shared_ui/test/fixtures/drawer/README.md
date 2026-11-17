# Drawer references (ZOD-NAV-002)

**These are generated visual references, not designer-provided assets.** `kit.css`, `kit.js` and `MASTER.md` remain authoritative; the images never override or redefine them. `test/widgets/drawer_reference_test.dart` compares `ZodiannDrawer` against them.

## What is here

`generated_<theme>_<lang>_<device>.png`: headless-Chrome renderings of `design-reference/zodiann/_source/wheel.html?lang=<lang>&theme=<theme>&drawer=1`, the same page and query the designer's own renders use.

- **Themes.** `dark` and `light`. The designer's PNGs (`screens/00-navigation-drawer_*`, `responsive/mobile/navigation-drawer_*`) are dark only and remain the oracle for the dark theme; the generated `light` images exist because the task's acceptance criteria ask for both themes and no light drawer was rendered. The generated `dark` images exist to prove the generator reproduces the designer's images (the test compares them).
- **Languages.** `en`, `he`.
- **Devices.** `desktop` is 1440 × 900 @1. `mobile` is 390 × 844 @2 shown in a 500-wide window (Chrome will not make a narrower one): the kit page sits in an exactly 390 × 844 iframe at the top left, so the PNG is 1000 × 1688 and the test crops the left 780 device px.
- **`manifest.json`.** The Chrome version, the device table, and the SHA-256 (LF-normalised) of every kit file the renders depend on. The test fails when one of them changes.

## What is compared

Both the PNGs and our rendered panel go through one extractor (`test/support/drawer_features.dart`): the inner-edge line, the header and footer rules, the active item's fill and bar, and each line of ink (text, icon, logo). Positions of edges, rules, the fill and the bar are within 1 logical px; ink extents within 3 logical px; plus a mean per-pixel difference ceiling over the panel. Flutter rounds text line heights to whole pixels, so text-driven heights can be about a pixel shorter than Chrome's per item; the calibration record in the plan says how the ceilings absorb that.

## Regenerating

Only when a kit file changes. From the workspace root:

```
fvm dart run tool/drawer/render_drawer_references.dart
```

- **Chrome:** `C:/Program Files/Google/Chrome/Application/chrome.exe`, unless `CHROME` names another executable. The committed images were made with Chrome 157.0.8103.78.
- **Flags:** `--headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --force-color-profile=srgb --font-render-hinting=none --force-device-scale-factor=<1|2> --window-size=<w>,<h> --virtual-time-budget=5000 --screenshot=<png>`.
- **Calibrating:** run the reference test with `ZODIANN_DRAWER_CALIBRATE=1` to print the measured differences instead of asserting them.
