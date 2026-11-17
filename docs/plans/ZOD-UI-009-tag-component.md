# ZOD-UI-009 Tag Component Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `ZodiannTag`, the 24 px / 6 px-radius tag in eight variants (axis, diagonal, eighth, no highlight, center, today, neutral, accent), matching the component sheet and carrying the `+` / `×` mark on highlight tags (NFR-X4).

**Architecture:** A pure colour / weight mapping from the existing theme extensions (`ZodiannTagStyle`, like `ZodiannButtonColors`) and one stateless widget. The tag is generic: the caller passes the localized label, and the mark is bound to the variant so it cannot be omitted. Colours, text roles, radius and spacing already exist; the plan adds only three size tokens and two mark glyph constants.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_ui` (`ZodiannSurfaces`, `SquareColors`, `ZodiannTextStyles`, `ZodiannGlyphs`), PNG feature extraction against the design sheet (reusing `Rgba` from `test/support/button_features.dart`).

**Task:** `docs/development/shared-ui-design-system/ZOD-UI-009-implement-the-tag-component-highlight-tags-mode-tags-today-center.md`. **Design:** `design-reference/zodiann/MASTER.md` §10 "Tags" (and §8.3 cell details, §9 saved squares, which use them); `DESIGN_DECISIONS.md` D10; `design-reference/zodiann/_source/kit.css:253-262` (the `.tag` rules the sheet was rendered from); `design-reference/zodiann/_source/kit.js` (`MARK`, `tagAxis` … `tagCenter` en / he); `design-reference/zodiann/components/components_{dark,light}.png` "Highlight and state tags". **Spec:** `assets/zodiann-specification.md` NFR-X4 ("the highlights in the square also have a label or an additional mark").

## Product-owner decisions (2026-11-17)

- **A. Neutral tag weight:** follow kit.css (neutral 12/**500**, every other tag 12/600), matching the component sheet pixel-for-pixel (AC1). MASTER §10's blanket "12/600" is not edited, as with NAV-001's subtitle weight.
- **B. `.fvmrc`:** its uncommitted newline change stays in the working tree and is never staged (standing decision from ZOD-FND-008).

## Facts established while planning (2026-11-17)

- **kit.css** (`.tag`, lines 253–262): `inline-flex`, centred, `gap: 6px`, `height: 24px`, `padding-inline: 8px`, `border-radius: var(--r-sm)` (6), 12 px / 600, `nowrap`.
  - `axis` / `diag` / `eighth`: `*-fill` background, `*-ink` text.
  - `none`: `surface-2` / `text-2`.
  - `today` / `center`: transparent, `today` / `center` text, `inset 0 0 0 1.5px` outline in the same colour.
  - `neutral`: `surface-2` / `text-2`, weight 500.
  - `accent`: `accent-soft` / `accent-strong`.
  - `.mk` (the mark): 13 px, 500, opacity 0.9.
- **Marks (`kit.js` `MARK`, D10):** `+` for axis, `×` (U+00D7) for diagonal; eighth, no highlight, center, today, neutral and accent carry **no mark** (a text label, or a distinct outline). NFR-X4 is met for them by the label.
- **Tokens that exist:** `ZodiannRadius.tag` (6), `ZodiannSpace.s2` (8, the padding), `SquareColors` (`axisFill/Ink`, `diagFill/Ink`, `eighthFill/Ink`, `center`, `today`), `ZodiannSurfaces` (`surface`, `surface2`, `text2`, `accentSoft`, `accentStrong`), `ZodiannTextStyles.label` (12 / 1.45, 500) and `small` (13 / 1.45, 400). **Missing:** tag height 24, tag gap 6, outline width 1.5.
- **Glyph coverage (verified):** IBM Plex Sans and IBM Plex Sans Hebrew, Medium and SemiBold, all contain `+` (U+002B) and `×` (U+00D7).
- **Sheet geometry (measured with headless Chrome on the source layout and by scanning both PNGs, 2026-11-17):**
  - The tags sit on the sheet's panel backdrop: `surface` (`#111114` dark, `#FFFFFF` light).
  - Dark row 1 top y = 3528, row 2 top y = 3560. **Light** row 1 top y = 3510 (18 px higher, not 17), row 2 top y = 3542. Every tag is exactly 24 px tall; row 2 is 32 px below row 1 (24 + 8).
  - Row 1, source left edge x and Chrome width (the PNG snaps these, see below): axis 65 / 53.70, diagonal 126.70 / 78.61, eighth 213.31 / 51.64, no highlight 272.95 / 83.09, center 364.05 / 53.31, today 425.36 / 49.05. Row 2: neutral "Dates" 65 / 47.67, accent "Mean node" 120.67 / 76.81. Tags are 8 apart.
  - The accent fill on the sheet is `accent-soft` over `surface` with 8-bit alpha: dark `#222225`, light `#F1F1F1` (a float `Color.alphaBlend` gives `#222224` / `#F0F0F1`, so never compute the expected value that way).
  - Chrome snaps each tag box to whole pixels (backgrounds and inset outlines). Box edges are hard; only the rounded corners and the text are anti-aliased. Pixel runs (identical in both themes): row 1 axis 65..118, diagonal 127..204, eighth 213..264, no highlight 273..355, center 364..416, today 425..473; row 2 neutral 65..112, accent 121..196. Outline tags show a full-colour pixel plus a 50 % pixel at every side (dark center `F5A524` / `825A1C`, today `2DD4BF` / `1E7269`; light center `D97706` / `EBBA82`, today `0E9F8E` / `86CEC6`). The corner pixel (left, top) is backdrop on every tag, and (left + 1, top + 1) is almost backdrop (dark axis `12161D`, light axis `FAFCFF`), which is what a radius of 6 gives.
  - Source texts on the sheet: `+ Axis`, `× Diagonal`, `Eighth`, `No highlight`, `Center`, `Today`, `Dates`, `Mean node`.
- **UI-004 precedent:** pixel-for-pixel has meant extractor-matched (width ±1, fill ±1 per channel, label ±3 per channel, height and top exact), never a raw pixel diff. At `textScaler 2` UI-004's button grows ("text scale 2.0 grows the button"); the tag does the same (minimum height 24).
- **Where tags are consumed later:** SQR-012 (cell details: highlight tag with its mark, Today tag), DAT-001 (saved-squares meta: mode tag), the positions table, SQR-019 and SQR-009 (the controls-summary Today tag, MASTER §8.1, `square.html:116`), ABT-007 (the licenses chip row, `about.html:79` `tag neutral ltr`), and NAV-002 lists UI-009 as a dependency (its text names no tag use; check at its planning). SQR-019, SQR-009 and ABT-007 don't list UI-009 as a dependency; Notes only (Task 4).

## Global Constraints

- **No new dependency**, no member pubspec change. `no_network_test.dart` unchanged and green.
- **Sizes** come from `ZodiannSize` tokens (`tag`, `tagGap`, `tagOutline`), never numeric literals in `lib/` (UI-003 guard); padding is `ZodiannSpace.s2`, radius `ZodiannRadius.tag`. Pin the new tokens in `test/theme/dimensions_test.dart`.
- **Colours** only from the theme extensions; no colour literals in `lib/` (ARCH-7 guard).
- **Text styles** derive from a `ZodiannTextStyles` role with `copyWith` (never a new `TextStyle`). Tag label: `label` with weight 600 (neutral 500) and the variant's ink; mark: `small` with weight 500 and the ink at `ZodiannStates.tagMarkOpacity` (0.9; not an `Opacity` widget).
- **Transparent** fills use `ZodiannStates.transparent` (as `ZodiannButtonColors`); `Colors.*` and colour literals fail the ARCH-7 guard.
- **Text literals:** no string literal in `Text`; the marks come from `ZodiannGlyphs.markAxis` / `markDiagonal`. The label is a parameter (a localized string from the caller).
- **No mirroring:** the mark sits at the start via `Row` order, with no `Transform`.
- **Staging:** every commit stages explicit paths (`git add <paths>`); never `git add -A`, `git add .` or `git commit -a`. `.fvmrc` stays unstaged.
- **Commands:** `fvm dart …` / `fvm flutter …` from PowerShell; Melos as `fvm dart run melos run <script>`. Gates: `lint`, `test`. A root `fvm flutter pub get` deletes the tracked generated l10n files in `packages/shared_ui/lib/l10n/`; restore with `git checkout -- packages/shared_ui/lib/l10n` if you run it (this plan needs no pub get).
- **Naming:** project prefix `Zodiann` (`ZodiannTag`, `ZodiannTagVariant`, `ZodiannTagStyle`).

## Out of scope

- Mapping `gann_core` highlight categories to tag variants, the six vocabulary strings (`tagAxis` … `tagCenter`, en / he in `kit.js`) and where tags are placed: SQR-012 owns them (ARB keys with parity tests there). The tag takes its label as a parameter.
- The cell-level `+` / `×` marks in the square (SQR-007); it will reuse `ZodiannGlyphs.markAxis` / `markDiagonal`.
- Interactivity (tags are static, not buttons), icons inside tags, removable chips.
- The NFR-008 colour-blindness audit.

## Review Focus

1. **NFR-X4:** an axis or diagonal tag rendered without its `+` / `×` would convey the highlight by colour alone. The mark is bound to the variant and pinned by test; no other variant may grow a mark.
2. **Outline tags keep a 24 px box and don't move their content:** the 1.5 px outline must be drawn inside the box (`DecoratedBox` with an inside `Border`, like kit's inset shadow), never with a `Container` (it adds the border to the padding) and never outside the box.
3. **RTL / Hebrew:** the mark must lead at the start side in Hebrew, and the Hebrew label must render in IBM Plex Sans Hebrew with `×` and `+` present.
4. **Large text and narrow width:** at `textScaler 2` the tag grows, and in a narrow parent the label ellipsizes without overflowing.
5. **Translucent accent fill:** `accent-soft` over `surface` must equal the sheet's fill in both themes (a harness that paints another backdrop would pass or fail wrongly).

---

### Task 1: Tokens, mark glyphs and the colour mapping

**Files:**
- Modify: `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart` (`ZodiannSize`), `packages/shared_ui/lib/src/theme/tokens/zodiann_states.dart` (`tagMarkOpacity`), `packages/shared_ui/lib/src/theme/zodiann_glyphs.dart`, `packages/shared_ui/lib/shared_ui.dart` (export)
- Create: `packages/shared_ui/lib/src/widgets/zodiann_tag_style.dart`
- Modify (tests): `packages/shared_ui/test/theme/dimensions_test.dart`, `packages/shared_ui/test/theme/glyphs_test.dart`, `packages/shared_ui/test/fonts/glyph_coverage_test.dart`
- Test: `packages/shared_ui/test/widgets/tag_style_test.dart`

**Interfaces:**
- Produces:
  - `ZodiannSize.tag = 24.0`, `ZodiannSize.tagGap = 6.0`, `ZodiannSize.tagOutline = 1.5` (kit.css `.tag`).
  - `ZodiannGlyphs.markAxis = '+'`, `ZodiannGlyphs.markDiagonal = '\u{00D7}'` (no U+FE0E: these are not emoji-presentation glyphs). The marks are **not** added to `ZodiannGlyphs.all` (the 29 astrological glyphs, each one code point plus U+FE0E, drawn with `ZodiannTextStyles.glyph`); update the class doc: the astrological glyphs carry U+FE0E and use `glyph`, while `markAxis` / `markDiagonal` are plain text marks drawn in the UI font (the `small` role).
  - `ZodiannStates.tagMarkOpacity = 0.9` (documented: kit.css `.tag .mk { opacity: .9 }`), pinned in a test.
  - `enum ZodiannTagVariant { axis, diagonal, eighth, noHighlight, center, today, neutral, accent }` with `String? get mark` (`+` for axis, `×` for diagonal, null otherwise).
  - `@immutable final class ZodiannTagStyle { const ZodiannTagStyle({required Color fill, required Color ink, Color? outline, required FontWeight weight}); factory ZodiannTagStyle.of(ZodiannTagVariant v, SquareColors square, ZodiannSurfaces surfaces); }` plus `==` / `hashCode`.

- [ ] **Step 1: Write the failing tests**
  - `dimensions_test.dart`: add `tag` 24, `tagGap` 6, `tagOutline` 1.5 to the `ZodiannSize` table, citing MASTER §10 and kit.css `.tag`. Also extend the existing "kit.css agrees" test (`_rule` / `_px`) with the `.tag` rule: `height` = `ZodiannSize.tag`, `gap` = `ZodiannSize.tagGap`, `padding-inline` = `ZodiannSpace.s2`, an oracle independent of the token file.
  - `glyphs_test.dart`: `the highlight marks are + and × (U+00D7), without a variation selector`, and `ZodiannGlyphs.all` still has 29 entries without the marks (the existing FE0E and 29-glyph tests already guard this; the new assertion names the intent).
  - `glyph_coverage_test.dart`: `IBM Plex Sans and IBM Plex Sans Hebrew (Medium and SemiBold) cover the tag marks + and ×`, taking its code points from `ZodiannGlyphs.markAxis.runes` / `markDiagonal.runes` (so it fails to compile in RED; the fonts already cover both).
  - `tag_style_test.dart` (names): `every variant × both themes maps to kit.css` (the table below, literal expected colours from the token files, not from the code under test); `only the neutral tag is weight 500`; `only center and today have an outline, equal to their ink`; `mark is + for axis, × for diagonal and null for the other six`; `accent is accent-soft on accent-strong (tokens)` (the composite over `surface` is checked against the sheet in Task 3); `ZodiannStates.tagMarkOpacity is 0.9`; `== and hashCode`.
  - Expected table (dark / light): axis `axisFill`+`axisInk` 600; diagonal `diagFill`+`diagInk` 600; eighth `eighthFill`+`eighthInk` 600; noHighlight `surface2`+`text2` 600; center `ZodiannStates.transparent` fill, ink = outline = `center`, 600; today `ZodiannStates.transparent` fill, ink = outline = `today`, 600; neutral `surface2`+`text2` **500**; accent `accentSoft`+`accentStrong` 600.
- [ ] **Step 2: Run to verify they fail.** `fvm flutter test test/theme/dimensions_test.dart test/theme/glyphs_test.dart test/fonts/glyph_coverage_test.dart test/widgets/tag_style_test.dart` in `packages/shared_ui`. Expected: compile errors (`ZodiannSize.tag`, `ZodiannGlyphs.markAxis`, `ZodiannStates.tagMarkOpacity`, `ZodiannTagStyle` undefined).
- [ ] **Step 3: Implement** the tokens, the two glyph constants, and `ZodiannTagVariant` / `ZodiannTagStyle` in `zodiann_tag_style.dart` (a `switch` over the variant; outline colours equal the ink for center and today). Export the file from `shared_ui.dart`.
- [ ] **Step 4: Run to verify they pass**, then the full `shared_ui` suite, the root `fvm dart test test/architecture`, and `fvm dart run melos run lint`.
- [ ] **Step 5: Commit** — `feat(ZOD-UI-009): add the tag size tokens, mark glyphs and style mapping`.

### Task 2: `ZodiannTag`

**Files:**
- Create: `packages/shared_ui/lib/src/widgets/zodiann_tag.dart`
- Modify: `packages/shared_ui/lib/shared_ui.dart` (export)
- Test: `packages/shared_ui/test/widgets/tag_test.dart`

**Interfaces:**
- Consumes: `ZodiannTagVariant`, `ZodiannTagStyle.of`, `ZodiannSize.tag / tagGap / tagOutline`, `ZodiannSpace.s2`, `ZodiannRadius.tag`, `ZodiannTextStyles.label / small`, `ZodiannGlyphs.markAxis / markDiagonal`.
- Produces: `class ZodiannTag extends StatelessWidget { const ZodiannTag({super.key, required this.variant, required this.label}); final ZodiannTagVariant variant; final String label; }`.
  - Layout: a `ConstrainedBox(minHeight: ZodiannSize.tag)` around a **`DecoratedBox`, not a `Container`** (kit's outline is an inset shadow that does not move the content; a `Container` adds the border to the padding): fill, `ZodiannRadius.tag`, and for the outline variants `Border.all(color: outline, width: ZodiannSize.tagOutline, strokeAlign: BorderSide.strokeAlignInside)`. Inside it `Padding(horizontal: ZodiannSpace.s2)` and `Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center)` (main axis at the start, as CSS) with the mark (when `variant.mark != null`), a `ZodiannSize.tagGap` gap, and the label (`maxLines: 1`, `softWrap: false`, ellipsis, in a `Flexible`).
  - Styles: label = `label` role `.copyWith(fontWeight: style.weight, color: style.ink)`; mark = `small` role `.copyWith(fontWeight: FontWeight.w500, color: style.ink.withValues(alpha: ZodiannStates.tagMarkOpacity))`.
  - Semantics: one node whose label is `label`; the visible text and the mark are excluded (the mark is decoration; the label is the accessible name).

- [ ] **Step 1: Write the failing tests** (`tag_test.dart`, each in both themes where colours matter). Names:
  - `is exactly 24 high with 8 start and end padding, radius 6, for all eight variants` (height 24 at the default text scale; padding measured from the label / mark position; the label's vertical centre equals the box's within 0.5).
  - `gap between the mark and the label is 6`.
  - `axis renders + and diagonal renders ×, always, in front of the label` (NFR-X4; the mark text is found in the tree and precedes the label in reading order).
  - `eighth, noHighlight, center, today, neutral and accent render no mark`.
  - `label style is 12 / 600 in the variant's ink; neutral is 500` and `mark style is 13 / 500 at 0.9 alpha`.
  - `center and today draw a 1.5 px inside outline in their ink; the others draw none`: the `BoxDecoration.border` is a `Border` whose every side has `width == ZodiannSize.tagOutline`, `color == ink` and `strokeAlign == BorderSide.strokeAlignInside`, and for center and today the content starts exactly 8 from the box's start edge (a `Container` would put it at 9.5).
  - `RTL: the mark leads at the start side and the box mirrors exactly (no Transform)` (en and he).
  - `Hebrew label renders in IBM Plex Sans Hebrew` (family from the resolved style under `withZodiannScript`) with the axis tag `ציר`.
  - `textScaler 2.0 grows the tag (height > 24, no overflow)`.
  - `narrow parent ellipsizes without overflow`; for the axis tag the `+` is still laid out at full width when the label ellipsizes (NFR-X4 holds under squeeze).
  - `one semantics node named by the label; the mark is excluded`.
  - `switches live with the theme` (graphite → porcelain colours change).
- [ ] **Step 2: Run to verify they fail.** Expected: compile error, `ZodiannTag` undefined.
- [ ] **Step 3: Implement `ZodiannTag`** as described under Interfaces; export it from `shared_ui.dart`.
- [ ] **Step 4: Run to verify they pass**, then the full `shared_ui` suite and `fvm dart run melos run lint`. **Mutation proofs:** drop the mark for axis; show a mark on eighth; outline `strokeAlignOutside` (caught by the strokeAlign assertion); `Container` instead of `DecoratedBox` (content at 9.5, caught by the padding assertion); swap axis / diagonal fills; neutral at 600; mark in an `Opacity` widget; mirror with `Transform`; each must fail a named test.
- [ ] **Step 5: Commit** — `feat(ZOD-UI-009): add ZodiannTag`.

### Task 3: Match the component sheet (AC1)

**Files:**
- Create: `packages/shared_ui/test/support/tag_features.dart` (measures a tag the same way on a design PNG and a Flutter render; reuses `Rgba` from `button_features.dart`; includes a PNG decode helper relative to `packages/shared_ui`, since UI-004's `_decode` is private to its test), `packages/shared_ui/test/support/tag_harness.dart` (pumps the eight tags on a `surface` backdrop at the sheet's labels and captures them)
- Test: `packages/shared_ui/test/widgets/tag_sheet_test.dart`

**Interfaces:**
- Consumes: `ZodiannTag`, the sheet PNGs `components_dark.png` / `components_light.png`, `Rgba`.
- Produces: `TagFeatures measureTag(Rgba image, {required int left, required int top, required int spanRight, required int backdrop, int? outline})` (ARGB `int`s, as `measureButton`), one extractor for both sides, returning:
  - **Box:** the left and right edges (where the pixel stops being the backdrop, scanned along the mid row), the width, and the top and bottom measured at a column at least 8 px from the left edge, scanning from top − 6 downward and bottom + 6 upward (near a corner the top reads one pixel off from anti-aliasing), hence the height.
  - **Fill:** the colour sampled 4 px inside the box.
  - **Corner:** compared against the outline colour when `outline` is given, and against the fill otherwise (for center and today the fill is the backdrop, so a fill comparison would always tie). `cornerOuter` = whether (left + 1, top + 1) is nearer the backdrop (true for radius 6, false for radius 4). `cornerInner` = whether (left + 2, top + 1) is nearer the fill or outline (true for radius 6, false for radius 8 or more, e.g. `ZodiannRadius.control`). Sheet values: (l + 1, t + 1) is dark center `4F3919`, today `18423F`, light center `F5DABB`, today `C2E7E2`; (l + 2, t + 1) is dark axis `15294C` against fill `16305A`, light axis `E3ECFF` against `DCE8FF`.
  - **Outline** (center and today): the pixels (left, mid), (left + 1, mid), (col, top) and (col, top + 1), where the sheet shows the full outline colour and then a 50 % pixel.
  - **Label colour:** the pixel farthest (RGB) from the fill, searched only in the content area x ∈ [left + 2 + 8, right − 2 − 8], rows mid − 5 … mid + 5 (inside the 1.5 px outline and the 8 px padding; the outline is drawn in the ink colour, so a search that included it would pass a wrong label colour).
  - **Definitions:** `mid = top + 12`. `spanRight` = the known right edge + 3 on the sheet (121, 207, 267, 358, 419, 476; row 2: 115, 199) and origin + 100 on the Flutter side, where each tag gets its own cell with at least 8 px of backdrop on every side (the next tag is only 8 px away, so a longer scan would land on it). "Top exact" means the measured top equals the `top` argument on both sides.

- [ ] **Step 1: Write the failing tests.** `setUpAll(loadBundledFonts)` (as `button_sheet_test.dart`; without it widths are measured in the test font).
  - **`extractor reads the sheet's known geometry`** (an oracle independent of the widget): on both sheet PNGs, pin literal values: tops dark 3528 / 3560, light 3510 / 3542; height 24; widths 54, 78, 52, 83, 53, 49 (row 1) and 48, 76 (row 2); fills dark `16305A`, `3D3412`, `222226`, `18181C`, `18181C`, `222225`, light `DCE8FF`, `FBEFC2`, `ECEDF0`, `F4F5F7`, `F4F5F7`, `F1F1F1` (axis, diagonal, eighth, no highlight, neutral, accent); the outline profiles from the Facts (full pixel, then 50 %).
  - **`ZodiannTag matches the sheet`**, per theme and tag: measure the sheet PNG and a `ZodiannTag` rendered on a `surface` backdrop (`#111114` dark, `#FFFFFF` light) with the sheet's text, and compare. The harness renders each tag at an **integer origin** (as UI-004 does at (8, 8)); the sheet side is measured from the snapped pixel lefts 65, 127, 213, 273, 364, 425 (row 1) and 65, 121 (row 2), and the tops above. Tolerances (as UI-004): width ±1 (Flutter's fractional right edge adds at most one partial column), fill ±1 per channel, label ±3 per channel, outline pixels ±3, height (24) and top exact; `cornerOuter` and `cornerInner` equal on both sides. Texts: `Axis` (with `+`), `Diagonal` (with `×`), `Eighth`, `No highlight`, `Center`, `Today`, `Dates`, `Mean node`.
  - **`layout width matches Chrome`**: compare `tester.getSize(find.byType(ZodiannTag)).width` with the Chrome source widths in the Facts (53.70, 78.61, 51.64, 83.09, 53.31, 49.05; 47.67, 76.81) within ±0.5. This is the arbiter for the pixel-width check: Chrome snaps both edges and Flutter at an integer origin shows its fractional right edge as one extra column, so snapping alone uses the whole ±1 budget on four tags (diagonal fails if Flutter's text is wider by more than 0.39, accent 0.19, center 0.69, today 0.95). If the pixel width misses ±1 but the layout width is within ±0.5, the miss is snapping and goes into the calibration record; if the layout width is off by more than 0.5, it is a widget defect.
  - **`accent fill`**: the sheet side is exactly `0xFF222225` (dark) / `0xFFF1F1F1` (light); the Flutter side is within ±1 per channel of it (a float `Color.alphaBlend` gives `0xFF222224` / `0xFFF0F0F1`; do not compute the expected value that way).
- [ ] **Step 2: Run to verify it fails.** Expected: the harness and extractor do not exist (compile error).
- [ ] **Step 3: Implement** `tag_features.dart` and `tag_harness.dart`; fix any real difference the comparison exposes in `ZodiannTag` (a deviation from the sheet is a defect in the widget or a recorded ruling, never a loosened tolerance without a calibration record). If `label` misses ±3 only because no Flutter pixel reaches full ink coverage (the nearest pixel is a blend of ink and fill: the sheet's text is LCD-antialiased, Flutter's greyscale at fractional x), record it in the calibration record with the measured values; never change the ink.
- [ ] **Step 4: Run to verify it passes**, then the full `shared_ui` suite and lint. **Mutation proofs:** padding 6 and gap 4 (both also fail the layout-width check), height 26, radius 4 (`cornerOuter`), radius 8 (`cornerInner`), outline 1 px (the outline pixels), wrong backdrop; each must fail a named assertion. (Neutral at weight 600 is owned by Task 1's `only the neutral tag is weight 500` and Task 2's `label style is 12 / 600 … neutral is 500`: "Dates" differs by under one column, inside the width tolerance.)
- [ ] **Step 5: Commit** — `test(ZOD-UI-009): match the tag sheet in both themes`.

### Task 4: Review and close-out

**Files:**
- Modify: `docs/PROGRESS.md`, `docs/development/TASKS.md`, the task file's status, this plan (calibration and implementation records), and "From ZOD-UI-009" Notes in `docs/development/gann-square/ZOD-SQR-012-build-cell-details-core-fields.md`, `docs/development/settings-persistence/ZOD-DAT-001-build-the-saved-squares-list-screen.md`, `docs/development/gann-square/ZOD-SQR-019-build-the-controls-panel-layout-and-summary-row.md`, `docs/development/gann-square/ZOD-SQR-009-implement-the-today-cell-computation-and-live-update.md` and the ABT-007 task file (`docs/development/about/ZOD-ABT-007-build-the-open-source-licenses-list.md`)

- [ ] **Step 1: Invoke `requesting-code-review`** over the whole branch; fix Critical and Important findings test-first (cheap minors may be promoted).
- [ ] **Step 2: Invoke `verification-before-completion`:** `fvm dart run melos run lint` exit 0 and `fvm dart run melos run test` exit 0, with real counts; `no_network_test` unchanged and green. A visual check of the rendered tag sheet (a saved PNG of both themes next to the design crop) is reviewed by eye and recorded.
- [ ] **Step 3: Update docs.** Task file status `Done`; `TASKS.md`; `PROGRESS.md` (Completed Tasks row with evidence; Current Task; Next Recommended Task; Technical Decisions: neutral weight 500 per kit.css; Architecture Conventions: a **Tags** paragraph, "use `ZodiannTag`, the label is a localized parameter, the mark is bound to the variant (NFR-X4), tokens `ZodiannSize.tag*`, marks from `ZodiannGlyphs`"; deferred minors). Notes: **SQR-012:** map the cell's highlight (axis / diagonal / eighth / none / center) to `ZodiannTagVariant` and show `ZodiannTag(today)` when applicable, with the six vocabulary strings as ARB keys (en / he from `kit.js`) and parity tests; **DAT-001:** the mode tag is `ZodiannTagVariant.neutral` with a localized mode name. **SQR-019 (and SQR-009):** the controls-summary Today tag is `ZodiannTag(variant: today)` with a localized label. **ABT-007:** the license names are `ZodiannTagVariant.neutral` inside an LTR `Directionality` (kit's `.ltr`).
- [ ] **Step 4: Commit and push** the task branch, open the PR into `main`, and record the link in `PROGRESS.md` as a follow-up commit (SKILL.md Step 8).

## Open items for approval

1. **Labels are parameters.** The six fixed vocabulary strings (`tagAxis` … `tagCenter`) are left to SQR-012, so UI-009 adds no ARB keys. Alternative: add them here with parity tests against `kit.js`. Recommended: leave them to SQR-012 (the tag stays generic, as `ZodiannButton` does).
2. **Text scale grows the tag** (minimum height 24), mirroring UI-004's button, rather than clamping the text or fixing the height as the top bar does. Recommended: grow (the tag must stay readable).
3. **No interactivity and no icons** in tags in this task.

## Plan review

### Round 1: Approve after corrections (1 Critical, 7 Important, 8 Minor, 0 Needs user decision)

- **C1 (Chrome snaps tag boxes to whole pixels; a fractional-x harness would fail width ±1):** applied. Facts now record the snapped runs; the harness renders each tag at an integer origin and the sheet side is measured from the snapped lefts.
- **I1 (label-colour search included the outline):** applied (content-area window). **I2 (extractor couldn't catch radius 4 or outline 1 px; neutral weight 600 not catchable by the sheet):** applied (outline and corner features; neutral weight owned by Tasks 1–2). **I3 (`Container` vs `DecoratedBox`, strokeAlign assertions, mutations):** applied. **I4 (marks must not join `ZodiannGlyphs.all`):** applied. **I5 (`loadBundledFonts`, PNG decode helper):** applied. **I6 (accent composite 0xFF222225 / 0xFFF1F1F1; ±1 on the Flutter side):** applied. **I7 (independent extractor oracle):** applied (`extractor reads the sheet's known geometry`).
- **M1–M8:** applied (`ZodiannStates.transparent`; `ZodiannStates.tagMarkOpacity`; coverage test from `ZodiannGlyphs` runes; Row cross-axis centre and label centred within 0.5; SQR-019 / SQR-009 / ABT-007 consumers and Notes; kit.css `.tag` cross-check; ARGB `int` signature; the `+` stays full width under squeeze).

### Round 2: Approve after corrections (0 Critical, 1 Important, 5 Minor, 0 Needs user decision)

- **I1 (the ±1 width budget is fully used by snapping on four tags; no rule to tell snapping from a defect):** applied. A `layout width matches Chrome` test (±0.5 against the Chrome source widths) arbitrates, and padding / gap mutants also fail it.
- **M1 (`mid` and `spanRight` undefined):** applied. **M2 (corner feature tied on outline tags and passed radius ≥ 8):** applied (`cornerOuter` / `cornerInner`, radius 8 mutant). **M3 (SQR-009 and the SQR-019 path missing from Files):** applied. **M4 (label ±3 may be unreachable under greyscale anti-aliasing):** applied as a calibration-record rule. **M5 (duplicate `all` test):** noted in the test text.
- **Open items after round 2:** none needing a decision beyond the three listed in "Open items for approval". Both rounds verified the sheet geometry, outline pixels, fills, glyph coverage and `Container` vs `DecoratedBox` behaviour independently.
