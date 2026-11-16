# Logo fidelity references (ZOD-FND-008)

`<variant>_<px>.png` are headless-Chrome renderings of `design-reference/zodiann/assets/zodiann-logo-on-{dark,light}.svg`. `test/logo/logo_fidelity_test.dart` compares `ZodiannLogo` against them.

## Layout

- **Variants.** `dark` and `light` (the two in-app marks).
- **Sizes (px).** 40, 80, 120 (the drawer's 40 logical px at device pixel ratios 1, 2, 3) and 132, 264, 396 (the About hero's 132 at the same ratios).
- **Each file** is the whole mark, N × N px, on a transparent background.
- **`manifest.json`.** Records the Chrome version, the sizes, and each SVG's SHA-256 (over the file with CRLF normalised to LF). The test fails when an SVG no longer matches its hash.

## Regenerating

Regenerate only when a logo SVG changes. Run from the workspace root:

```
fvm dart run tool/logo/render_logo_references.dart
```

- **Chrome:** `C:/Program Files/Google/Chrome/Application/chrome.exe`, unless `CHROME` names another executable. The committed images were made with Chrome 157.0.8103.78.
- **Flags:** `--headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --force-color-profile=srgb --default-background-color=00000000 --window-size=<N>,<N> --screenshot=<png>`.
- **After regenerating:** run the fidelity test with `ZODIANN_LOGO_CALIBRATE=1` to print the measured differences; if the ceilings need to change, record why in `docs/plans/ZOD-FND-008-app-icon-logo-asset-set.md` (calibration record).

## What is compared

Per pixel: alpha, and colour premultiplied by alpha, against Chrome's vector render at the same pixel size. Plus the share of Chrome's ink kept in the outer band (the hairline ring and the ticks, radius ≥ 0.40 · side) and in the whole image, so the hairlines can neither vanish nor bloat.
