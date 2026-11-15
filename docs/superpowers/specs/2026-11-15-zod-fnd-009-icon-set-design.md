# ZOD-FND-009 — Icon set design (short)

**Status:** decided by the product owner, 2026-11-15. The implementation plan is `docs/plans/ZOD-FND-009-svg-icon-set.md`.

## Intent

Bring the 33 finished Zodiann icons (`design-reference/zodiann/assets/icons/*.svg`) into the app behind one widget. This unblocks the top bar (ZOD-NAV-001) and gives `ZodiannButton.icon` real icons. Sizes: 20 in controls (`ZodiannSize.icon`), 16 in small buttons and fields (`ZodiannSize.iconSmall`). Back and forward follow the reading direction.

## Constraint that shaped it

`flutter_svg` 2.4.0 and `vector_graphics` 1.3.1 both depend on `http`, which the FND-007 no-network guard (DATA-8) forbids at runtime.

## Approaches

1. **Generate Dart drawing code from the SVGs.** Chosen.
2. `flutter_svg` plus an exception in the guard. Rejected: it weakens a deliberate rule.
3. Icon font. Rejected: it needs Node or FontForge tooling outside Flutter.

## Decisions (product owner)

- No `flutter_svg`, no `vector_graphics`, no new runtime dependency. The FND-007 guard is not touched.
- The SVG files in `design-reference/` stay the single source of truth.
- A deterministic generator writes the Dart drawing data. A `--check` mode fails when the committed output is stale. The generated file is never edited by hand.
- The generator fails explicitly on any unsupported element, attribute or value. It never drops drawing instructions silently.
- Paths, circles, rects, fills, strokes, stroke widths and viewBox proportions are preserved.
- Sizes come from `ZodiannSize.icon` and `ZodiannSize.iconSmall`.
- `iconBack()` and `iconFwd()` choose `chevL` or `chevR` from Flutter's `Directionality`, as `kit.js` does. No icon is ever mirrored automatically. `chevL`, `chevR` and every other icon draw the same in both directions.
- Tests cover all 33 icons, both sizes, LTR / RTL selection, and visual fidelity against the source SVGs.
- Documented deviation: the source SVGs stay in `design-reference/`, and the app bundles the generated Dart drawing code instead of SVG assets.

## Left to the plan

File layout, generator internals, the reference-image method for the fidelity tests, thresholds, and mutation proofs.
