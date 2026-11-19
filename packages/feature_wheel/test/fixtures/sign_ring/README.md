# Sign ring references (ZOD-WHL-002)

Four Chrome renderings of the design kit's sign ring (`kit.js` `wheelSVG`,
everything but the sectors, glyphs, separators, rims and halo hidden), at
644 x 656 px, R = 300 px, centre (322, 334), `pointerLon` 227.05 (the kit's own
default, `BODIES[0].lon`). They are **generated** visual references, not
designer assets; `kit.css` and MASTER.md stay authoritative.

Regenerate only when a kit file changes (the manifest holds their SHA-256):

    fvm dart run tool/wheel/render_sign_ring_references.dart

`test/canvas/sign_ring_fidelity_test.dart` compares the Flutter render of
`SignRingLayer` with them: mean absolute difference over the annulus
`signBandInner - 20 .. halo + 2` units, the same on the outer rim, inner rim and
halo bands (+-2 px), sector fill at 72 points (+-2 per channel), and the
luminance-weighted glyph centroid and extent per sign (2 px).

## Measured 2026-11-19 (Chrome 157-class headless, Windows)

| Case | mean | outer rim | inner rim | halo | fill | centroid px | box px |
|---|---|---|---|---|---|---|---|
| desktop dark | 0.48 | 0.48 | 0.44 | 0.22 | 1 | 0.54 | 1 |
| desktop light | 0.29 | 0.22 | 0.23 | 0.13 | 0 | 0.35 | 1 |
| compact dark | 0.91 | 0.48 | 0.43 | 0.22 | 1 | 1.04 | 1 |
| compact light | 0.74 | 0.22 | 0.24 | 0.13 | 0 | 1.05 | 1 |

Ceilings are `max(round_up(worst x 1.5), floor)` (see `_ceilings` in the test).
`SignRingLayer.glyphCentringFactor` stays 0: the measured glyph centroids are
within 1.05 px of Chrome's `dominant-baseline: central`.
