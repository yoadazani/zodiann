# Icon fidelity references (ZOD-FND-009)

`sheet_<S>.png` are headless-Chrome renderings of the source SVGs in `design-reference/zodiann/assets/icons/`. `test/icons/icon_fidelity_test.dart` compares each icon drawn by `ZodiannIcon` against them.

## Layout

- **Sizes.** S = 16 and 20 (the product sizes, MASTER §4), 48 and 60 (3 × 16 and 3 × 20, for high-density screens), and 96 (shape detail).
- **Sheet.** All 33 icons in one row, in file-name code-unit order (the generator's order, so `ZodiannIcons.values`).
  - Cell `i` covers `x ∈ [i·S, (i+1)·S)`, `y ∈ [0, S)`.
  - The page is `33·S × max(S, 64)`.
  - Icons are black (`#000`) on a transparent background.
- **`manifest.json`.** Records the Chrome version, the sizes, and each SVG's SHA-256 (over the file with CRLF normalised to LF). The test fails when an SVG no longer matches its hash.

## Regenerating

Regenerate only when an SVG changes. Run from the workspace root:

```
fvm dart run tool/icons/render_icon_references.dart
```

- **Chrome:** `C:/Program Files/Google/Chrome/Application/chrome.exe`, unless `CHROME` names another executable. The committed sheets were made with Chrome 157.0.8103.78.
- **Flags:** `--headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --force-color-profile=srgb --default-background-color=00000000 --window-size=<33·S>,<max(S,64)> --screenshot=<png>`.
- **After regenerating:**
  - run `fvm dart run tool/gen_icons.dart`;
  - run the fidelity test with `ZODIANN_ICON_CALIBRATE=1` to see the worst differences per size;
  - if the ceilings need to change, follow the calibration rule in `docs/plans/ZOD-FND-009-svg-icon-set.md` (Task 4 Step 3).

## Deviation from the task text

ZOD-FND-009 asked for the 33 SVGs to be registered as app assets. Instead, by product-owner decision on 2026-11-15:
- the SVGs stay in `design-reference/` as the single source of truth;
- the app bundles Dart drawing data generated from them (`lib/src/icons/zodiann_icons.g.dart`, via `tool/gen_icons.dart`).

The reason is that `flutter_svg` and `vector_graphics` depend on `http`, which the FND-007 no-network guard forbids.
