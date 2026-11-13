# ZOD-UI-002 - Implement the typography scale

## Metadata

- **ID:** ZOD-UI-002
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done
- **Scope:** MVP

## Description

Build the `TextTheme`/text-style set for every role in the type scale, with the correct family, weight, size, line-height, and tracking.

## Implementation Details

- Implement all roles from MASTER.md §3's table: Hero wordmark, Display readout, Section title, Wordmark (drawer), Screen title, Panel title, Body, Small, Label, Micro, Glyphs — each with its exact size/line-height/weight/tracking and phone-size variant where specified.
- Apply `FontFeature.tabularFigures()` to every style used for degree/date/number columns.
- Append U+FE0E (text presentation selector) to every astrological glyph string so no platform substitutes an emoji rendering.
- Font family resolution: IBM Plex Sans for Latin, IBM Plex Sans Hebrew for Hebrew (which also covers Latin, so it's the whole UI family in Hebrew mode).
- Enforce sentence case everywhere (no all-caps, no letter-spaced eyebrows) as a convention, not a per-string choice.

## Design Reference

`design-reference/zodiann/MASTER.md` §3 "Typography" (complete role table). Cross-check rendered output against `design-reference/zodiann/components/components_dark.png` "Typography" section, which shows each role in both English and Hebrew side by side.

## Acceptance Criteria

- [x] Every role in the table renders at the correct size/weight/tracking in a test harness.
- [x] Tabular figures are verified on a changing-digit-width test (e.g., cycling 0–9 in one column causes no horizontal jitter).
- [x] No astrological glyph renders as a color emoji on any tested platform/font configuration.

## Dependencies

- [ZOD-FND-007](../foundations-architecture/ZOD-FND-007-bundle-offline-fonts-and-verify-no-network-dependency.md) — Bundle offline fonts and verify no network dependency
- [ZOD-FND-013](../foundations-architecture/ZOD-FND-013-establish-the-design-token-theme-skeleton-dark-light-colorscheme.md) — Establish the design-token theme skeleton (dark + light `ColorScheme`)

## Specification References

- MASTER.md §3
- L-13
- L-14

## Notes

- **Implemented (2026-11-13):** `ZodiannTextStyles` (a `ThemeExtension` in `shared_ui`, one style per role + `heroWordmarkPhone`, `displayReadoutPhone`, `glyph`), `buildZodiannTextTheme` (all 15 Material slots), `buildZodiannTheme(script:)`, `withZodiannScript`, `ZodiannScript.forLocale` (he/iw → Hebrew), `ZodiannGlyphs` (29 glyphs + U+FE0E). The app's `MaterialApp.builder` applies the locale's script. Plan: `docs/plans/ZOD-UI-002-typography-scale.md`.
- **Role decisions:** Panel title has no tracking (MASTER gives none; `kit.css` −0.005em, MASTER wins). Blank line heights inherit `kit.css` body 1.45; square cells are a separate `cell` role (11.5 / 1.12) and Micro is 11 (axis labels). Small and Micro default to 400; 500 is `copyWith(fontWeight: w500)`. Tracking applies in both scripts. Phone variants are fields; the screens choose them by breakpoint. Every UI stack ends with the glyph fonts, so a stray glyph in UI text never reaches a system emoji font.
- **Criterion 1 harness:** `packages/shared_ui/test/support/typography_specimen.dart` (the reference board's rows in English and Hebrew + every other role; PNG via `ZODIANN_TYPE_DIR`, reviewed against `components_dark.png`), with rendering tests for line height, tracking and weight. The engine rounds a line box to whole px (31.2 → 31), so the rendering test checks the rounded height and the value test owns the exact value.
- **Criterion 2:** in every UI role, both scripts, digits 0–9 and all 100 readouts `aa°bb′` have one width.
- **Criterion 3 platforms:** host (FontLoader width proofs) and Android 9 x86 emulator-5554 (`apps/astro_mobile/integration_test/glyph_presentation_test.dart`: zero coloured pixels for all 29 glyphs; with the system font and no U+FE0E the same check finds a colour emoji, 3470 coloured pixels). **iOS not run** (needs a Mac); run that test there.
- **Handoffs for screens/components:** (1) Unconstrained RTL layout can wrap a single line by a sub-pixel: `drawerWordmark` / `headlineSmall` on 'מאדים 14°32′' in a shrink-wrapped `Row` lays out on two lines (1 of 143 role × sample combinations; negative tracking + RTL + a fallback-font run). Use `maxLines: 1` (with `overflow: TextOverflow.ellipsis`) on single-line labels mixing Hebrew, digits and ′ — `softWrap: false` does **not** fix it. (2) A glyph inside a UI line makes that line ~2 px taller (Noto Symbols metrics); tables and lists that mix glyph and non-glyph rows may want a `StrutStyle` with `forceStrutHeight`.
- **From ZOD-FND-007 (2026-11-13):** name the bundled fonts only through `ZodiannFonts` with `package: ZodiannFonts.package` (it also prefixes `fontFamilyFallback`). Glyph styles use `fontFamilyFallback: ZodiannFonts.glyphFallback` — Noto Sans Symbols, Noto Sans Symbols 2, then **Noto Sans**, which FND-007 added for ℞ (U+211E, in neither Symbols font; product-owner decision).
- IBM Plex Sans Hebrew lacks ′ (U+2032) and ″ (U+2033), used in positions such as `17°03′` (MASTER §7.3). In Hebrew mode add `fontFamilyFallback: [ZodiannFonts.plexSans]`, as the mockup's stack does (`_source/kit.css:108`).
- Neither Plex family has a `tnum` feature, but digits 0–9 are already equal width (600 units) in all eight files, so figures are tabular by default; keep `FontFeature.tabularFigures()` per the spec, and the jitter test still proves it.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
