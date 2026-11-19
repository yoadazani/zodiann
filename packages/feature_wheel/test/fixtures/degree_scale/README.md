# Degree scale references (ZOD-WHL-003)

Four Chrome renderings of the design kit's degree scale (`kit.js` `wheelSVG`,
everything but the ticks and the "10" / "20" labels hidden), at 644 x 656 px,
R = 300 px, centre (322, 334), `pointerLon` 227.05 (the kit's own default,
`BODIES[0].lon`). They are **generated** visual references, not designer
assets; `kit.css` and MASTER.md stay authoritative.

Regenerate only when a kit file changes (the manifest holds their SHA-256):

    fvm dart run tool/wheel/render_degree_scale_references.dart

`test/canvas/degree_scale_fidelity_test.dart` compares the Flutter render of
`DegreeScaleLayer` with them: the tick length along every ray (the tip's
sub-pixel position, within 1 unit of the rule's 5 / 9 / 14 in both the
reference and the render, and within 1 px of each other in position), the
luminance-weighted ink centroid of each of the 24 labels (2 px) and the
reference's measured label radius against `degreeNumberRadius` (2 units), and
the mean absolute difference over the annulus `signBandInner - 40 ..
signBandInner + 1` units.

## Measured 2026-11-19 (Chrome 157.0.8103.79, headless, Windows)

| Case | mean | tick tip error (units) | tick centroid px | label centroid px | label radius error (units) | mean dx / dy px |
|---|---|---|---|---|---|---|
| desktop dark | 1.00 | 0.25 | 0.10 | 1.08 | 0.99 | -0.13 / -0.52 |
| desktop light | 1.30 | 0.25 | 0.09 | 1.05 | 0.97 | -0.16 / -0.50 |
| compact dark | 0.75 | 0.50 | 0.05 | 0.46 | 0.77 | -0.07 / -0.05 |
| compact light | 0.98 | 0.50 | 0.05 | 0.45 | 0.74 | -0.09 / -0.03 |

Ceilings for the mean are `max(round_up(worst x 1.5, 0.05), floor)` (see
`_ceilings` in the test). `DegreeScaleLayer.labelCentringFactor` stays 0: the
measured label centroids are within 1.08 px of Chrome's
`dominant-baseline: central` (desktop labels sit about half a pixel high;
no single fraction of the size fits both tables because Flutter rounds line
heights to whole pixels). The label radius (kit `rSignIn - 26`: 224 desktop,
214 compact) is confirmed to within 1 unit by measurement, closing the
by-eye check of ZOD-WHL-001 decision D7. The labels carry colour fringes in
Chrome (subpixel text antialiasing); the comparisons use luminance.

## The designer's screenshots (`test/design/wheel_scale_png_test.dart`)

Measured 2026-11-19 on `01-zodiac-wheel_desktop_{en,he}_{dark,light}.png`
(the wheel at about 1.05 x the kit's scale; found from the picture, shift
dx = 490):

| Check | worst measured | bound |
|---|---|---|
| tick tip vs the 5 / 9 / 14 rule (kit units, bodies' connectors skipped) | 1.25 | 1.5 |
| label ink centroid vs this Chrome reference (kit units) | 1.55 | 2.0 |
| label ink centroid, English vs Hebrew (kit units) | 0.22 | 0.75 |
| tick zone 233 .. 251 units, English vs Hebrew (per channel) | 1 (78 / 104 pixels differ) | 1 |

The label ring (about 217 .. 231 units) is not compared pixel for pixel
between English and Hebrew: the designer's two renders differ there by up to
110 per channel (subpixel text antialiasing; shapes and positions agree), so
the labels are compared by centroid. The Flutter English and Hebrew renders
are byte-identical (`degree_scale_layer_test.dart`).
