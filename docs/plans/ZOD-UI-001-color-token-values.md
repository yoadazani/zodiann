# ZOD-UI-001 Colour Token Values Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace FND-013's placeholder token values with MASTER.md §2's exact dark (Graphite) and light (Porcelain) values for all 52 colour tokens. Prove them two independent ways, against MASTER's text and against the design reference's rendered swatch grid, and provide the swatch-grid harness the task asks for.

**Architecture:**
- Only the two token files change: `packages/shared_ui/lib/src/theme/tokens/graphite_tokens.dart` and `porcelain_tokens.dart`. Each becomes a literal `ZodiannTokens(...)` with `Color(0xFF……)` for opaque tokens and `Color.fromRGBO(r, g, b, a)` for MASTER's rgba tokens. `placeholder_tokens.dart` is deleted.
- Everything else (the extension types, `buildZodiannTheme`, the app wiring, the ARCH-7 guard) is FND-013's and stays unchanged.
- Verification:
  - **MASTER text oracle:** a test with MASTER's tables typed in as literal hex strings, checking all 104 values.
  - **Reference-image oracle:** a test that decodes `components_dark.png` / `components_light.png` and compares the pixel at the centre of each of the 43 swatch tiles in their "Colour tokens" section against the token value. Translucent tokens are compared as composited over the panel colour.
  - **Harness:** a test-only `TokenSwatchGrid` widget that lays out the same groups and order as the reference, plus the 9 tokens the reference grid omits. Its tests check that each tile paints its token's colour and each label shows MASTER's name and value. It can write a PNG for side-by-side visual review.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), material_ui 1.11.0, flutter_test (`dart:ui` image decoding).

**Spec:** `assets/zodiann-specification.md` (ARCH-7, NFR-X5, Appendix D). Design: `design-reference/zodiann/MASTER.md` §2, `design-reference/zodiann/components/components_{dark,light}.png`. Task: `docs/development/shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md`.

## Facts established while planning (2026-11-13)

- **Reference grid layout** (corrected in plan review round 1):
  - Both PNGs are 1440 px wide; dark is 1440×5586, light is 1440×5569.
  - Tile colour areas are 52 px tall (`_source/components.html` `.sw i { height: 52px }`), and their x-extents are identical in both themes.
  - Rows 3–5 sit 17 px higher in the light PNG, because a row-2 label wraps only in dark.
  - Row y-centres: **dark 288, 440, 606, 756, 906; light 288, 440, 590, 740, 890.**
  - Rows 1–4 have 8 tiles, centred at x = 141, 306, 472, 637, 802, 967, 1133, 1298.
  - Row 5 (bodies) has 11 tiles, centred at x = 119, 239, 359, 480, 600, 720, 840, 960, 1080, 1201, 1321.
- **Second machine-readable source:** `design-reference/zodiann/_source/kit.css`, the stylesheet the PNGs were rendered from, holds all 52 tokens for both themes. The dark block is `:root, [data-theme="dark"] {` and the light block is `[data-theme="light"] {`; bodies use the `--b-` prefix. The reviewer confirmed it agrees with MASTER §2 on all 104 values.
- **The reference board is `surface`** (`_source/components.html:13`), so translucent tiles composite over `surface`.
- **Tile order**, by reference label:
  1. *Surfaces and text:* bg, bg-raised, surface, surface-2, surface-3, line, text, text-2.
  2. *Brand and state:* accent, accent-line, text-3, focus, danger, ok, line-soft, on-accent.
  3. *Square of Nine roles:* axis-fill, axis, diag-fill, diag, eighth-fill, today, center, sel-outer.
  4. *Elements and aspects:* fire, earth, air, water, asp-conj, asp-soft, asp-hard, cell-fill.
  5. *Bodies:* sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto, node (labelled "Mean node").
- **Not in the reference grid:** accent-strong, accent-soft, scrim, axis-ink, diag-ink, eighth-ink, cell-ink, cell-line, sel-inner.
- **Sampled pixels (PowerShell `GetPixel`):**
  - Every opaque tile equals MASTER's hex **exactly** in both themes.
  - `accent-line` reads `#4A4A4C` (dark) and `#C0C0C1` (light). That is MASTER's rgba blended over the panel colour, which is `surface` (dark `#111114`, light `#FFFFFF`), to within 1 per channel, because the browser stores alpha as 8 bits.
  - So the image oracle compares opaque tokens exactly, and translucent tokens as `Color.alphaBlend(token, surface)` with a tolerance of ±1 per 8-bit channel.

## Global Constraints

- Values are MASTER.md §2's, copied exactly; don't approximate. rgba tokens keep MASTER's alpha: `Color.fromRGBO(255, 255, 255, 0.07)`, not a pre-rounded hex alpha.
- Colour literals only inside `packages/shared_ui/lib/src/theme/tokens/` (the FND-013 guard enforces this). The harness lives under `test/`, so the guard doesn't apply to it.
- Import `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`. `package:flutter/rendering.dart` for `RenderRepaintBoundary` in tests is fine; only `flutter/material.dart` is banned.
- No API changes to the extensions, `ZodiannTokens`, `buildZodiannTheme` or the app. Out of scope: typography (UI-002), spacing (UI-003), components (UI-004+), the gallery harness (UI-015), and logo variants.
- `signTintOpacity` stays 0.10 / 0.09 (MASTER §2.3, already set by FND-013).
- Tests report through `reason:`, never `print` (`avoid_print` together with `--fatal-infos` fails lint).

## Design decisions (mine, for your confirmation)

- **The harness is test-only:** `packages/shared_ui/test/support/token_swatch_grid.dart`. The task calls it a "test harness", and UI-015 owns the real component gallery. Its labels are literal English strings, which is allowed because it isn't app UI (L-8 applies to the app).
- **The 9 tokens missing from the reference** get a sixth harness section, "Not in the reference grid", so the harness shows all 52 tokens. The visual comparison covers only the 5 sections that exist in the reference.
- **Visual-review PNGs, without committed goldens.**
  - Goldens depend on the platform's font rendering, and flutter_test renders text in the FlutterTest box-glyph font, so a Windows-made golden would be fragile in FND-004's Linux CI.
  - Instead, the harness test always renders the grid to an image, which proves it paints. When the `ZODIANN_SWATCH_DIR` environment variable is set, it also writes `token_swatches_graphite.png` / `token_swatches_porcelain.png` there.
  - The close-out writes them to the session scratchpad for a side-by-side review against the reference crops, and the code reviewer gets them.
- **Contrast:** MASTER states `text-3` is "≥ 4.5:1 on `bg`", and NFR-X5 requires WCAG AA. A small test checks this using WCAG relative luminance: `text`, `text-2` and `text-3` on `bg`, `surface` and `bg-raised`, and `on-accent` on `accent`, all ≥ 4.5:1 in both themes. If a MASTER value fails, the test is **not** loosened: stop and report it to the product owner (MASTER: "When they disagree, stop and ask"). The reviewer computed that every planned pair passes; the weakest is dark `text-3` on `surface` at 4.77.
  - This is a sanity check of MASTER's own stated minimum and the primary text roles. The full audit of every text/background pairing, including `-ink` on `-fill`, belongs to ZOD-NFR-009.

## File Structure

- Modify: `packages/shared_ui/lib/src/theme/tokens/graphite_tokens.dart`, `porcelain_tokens.dart`.
- Delete: `packages/shared_ui/lib/src/theme/tokens/placeholder_tokens.dart`.
- Create:
  - `packages/shared_ui/test/theme/master_values_test.dart`
  - `packages/shared_ui/test/theme/reference_swatches_test.dart`
  - `packages/shared_ui/test/theme/contrast_test.dart`
  - `packages/shared_ui/test/support/token_swatch_grid.dart`
  - `packages/shared_ui/test/theme/token_swatch_grid_test.dart`
- Modify: `packages/shared_ui/test/theme/zodiann_theme_test.dart`. Its `placeholder signTintOpacity…` test is renamed to `signTintOpacity is MASTER's 10 % / 9 %`; the assertions are unchanged.

## Review Focus

1. **A value is mistyped** in one token file, for example `#7C808A` vs `#7C8A80`. Pinned twice: by `master_values_test` and, for the 43 shown tokens, by the reference pixels.
2. **Dark and light are swapped** for a token, or a whole file. The image oracle reads the dark PNG for Graphite and the light PNG for Porcelain.
3. **An rgba token loses its alpha,** becoming opaque white or black. That would show as a solid accent-soft fill or a solid scrim over the whole screen. Pinned by `master_values_test` (exact alpha) and by the `accent-line` composite pixel.
4. **Low-contrast text** in either theme (NFR-X5). Pinned for the primary pairs by `contrast_test`; the full audit is ZOD-NFR-009.
5. **The app's look after the switch:** the shell now paints Graphite `bg` `#08080A` / Porcelain `bg` `#F5F6F8`, a visible change from FND-013's placeholders. The FND-005/013 app tests compare against tokens, not fixed colours, so they stay green. Confirmed on the emulator in the close-out.

---

## Tasks

Bash calls start at the repo root and need `export PATH="$PATH:$LOCALAPPDATA/Pub/Cache/bin"`, or wherever `fvm` lives. Never put `^` inside `cmd //c "…"`. shared_ui tests: `cmd //c "fvm dart run melos exec --scope=shared_ui -- flutter test"`.

### Task 1: MASTER values in the token files (TDD)

**Files:** test `packages/shared_ui/test/theme/master_values_test.dart`; modify both token files; delete `placeholder_tokens.dart`; rename one test in `zodiann_theme_test.dart`.

**Interfaces:** consumes `graphiteTokens`, `porcelainTokens` and the extensions' `tokens` maps (FND-013). Produces the same symbols with MASTER values.

- [ ] **Step 1: Write the failing test.**
  - `master_values_test.dart` holds `const _master = <String, (String, String)>{ 'bg': ('#08080A', '#F5F6F8'), … }`. It covers all 52 tokens by MASTER name, typed from MASTER §2.1–§2.3. For each rgba token the pair holds MASTER's rgba text, for example `('rgba(255,255,255,.07)', 'rgba(11,12,14,.06)')`.
  - The test-local `Color _parse(String)` handles `#RRGGBB` (alpha 1) and `rgba(r,g,b,a)` (as `Color.fromRGBO`).
  - The groups map to extensions like this: surfaces → `ZodiannSurfaces.tokens`; square → `SquareColors.tokens`; elements → `ZodiacColors.tokens`; `asp-*` → `AspectColors.tokens`; bodies keyed by `Body.name` → `BodyColors.tokens`.
  - Tests:
    - `every MASTER §2 token has its Graphite value`: for each of the 52 tokens, `graphite… == _parse(dark)`, with `reason: name`.
    - `every MASTER §2 token has its Porcelain value`: the same for light.
    - `the table covers every token in the theme`: the union of the five `tokens.keys` sets for each theme equals `_master.keys`, so a token added later without a value fails.
    - `kit.css agrees with every token value`: parse `../../design-reference/zodiann/_source/kit.css`, taking the dark block `:root, [data-theme="dark"] {` and the light block `[data-theme="light"] {`, entries `--<name>` or `--b-<body>`. Whitespace-normalise the values, parse them with `_parse`, and compare against both themes' values for all 52 tokens. This is a second, machine-checked source, so one transcription slip copied into both the table and the code still fails.
      - Extract each block's declarations with `RegExp(r'--([a-z0-9-]+)\s*:\s*([^;]+);')`; several share a line, and comments sit between them.
      - Look up and `_parse` only the 52 token names (bodies as `b-<name>`), so `--shadow-float`, `--danger-soft` and `--sign-tint` are never parsed as colours.
      - Also assert that `--sign-tint` equals `signTintOpacity` (`.10` / `.09`).
- [ ] **Step 2: Run it.** Expected: FAIL, 3 of 4. The Graphite, Porcelain and kit.css comparisons fail at the first token (`bg`, `reason: bg`). `the table covers every token` already passes, because FND-013's maps are complete.
- [ ] **Step 3: Implement.**
  - Write both token files as `final ZodiannTokens graphiteTokens = ZodiannTokens(brightness: Brightness.dark, surfaces: const ZodiannSurfaces(bg: Color(0xFF08080A), …), …, zodiac: const ZodiacColors(…, signTintOpacity: 0.10), …);` (`porcelainTokens` likewise, `0.09`).
  - Keep a doc comment citing MASTER §2.
  - Delete `placeholder_tokens.dart`, and rename the `signTintOpacity` test in `zodiann_theme_test.dart`.
  - Check that `grep -rn placeholderTokens packages apps` finds nothing.
- [ ] **Step 4: Run it again.** Expected: 4/4, and the whole shared_ui suite passes: 26 + 4 = 30. Then the app suite, `cmd //c "fvm dart run melos exec --scope=astro_mobile -- flutter test"`: 16/16, unchanged. Then `cmd //c "fvm dart test test/architecture"`: 23/23. The guard's skip list shrinks to two files, and its `contains(graphite_tokens.dart)` check still holds.
- [ ] **Step 5: Commit** `feat(ZOD-UI-001): MASTER §2 colour values for Graphite and Porcelain`.

### Task 2: Reference-image oracle and contrast (tests over Task 1's values)

These tests are written after the values exist, so their RED evidence comes from mutants (Step 4).

**Files:** `test/theme/reference_swatches_test.dart`, `test/theme/contrast_test.dart`.

- [ ] **Step 1: Write the tests.**
  - **`reference_swatches_test.dart`:**
    - It uses a plain `test` group whose `setUpAll` decodes each PNG once: `instantiateImageCodec` → `getNextFrame` → `toByteData(format: ImageByteFormat.rawRgba)`, then disposes the `ui.Image`. dart:ui works in plain tests under `flutter test`, so no `runAsync` is needed. If `testWidgets` were used instead, every engine future would have to be awaited inside `tester.runAsync`; the reviewer showed that awaiting `toByteData` outside it hangs until timeout. A test-local `Color _pixel(x, y)` reads one pixel.
    - It holds a literal layout table: rows as lists of MASTER token names, in the order given under Facts; the y-centres per theme (dark and light, as under Facts); and the x-centres for 8 and 11 columns.
    - **Uniformity check:** for each tile, the pixels at (x ± 10, y ± 10) must equal the centre pixel, so a coordinate that drifts onto a tile edge or label fails loudly.
    - For each theme (graphite ↔ dark PNG, porcelain ↔ light PNG) it runs `the reference "Colour tokens" swatches match <theme>`. For each of the 43 tiles, opaque tokens must satisfy `_pixel == token` (compared as 8-bit ARGB ints). Translucent tokens (`a < 1`) must have each channel of `_pixel` within ±1 of `Color.alphaBlend(token, surfaces.surface)`.
    - Sanity tests: `the reference images are the expected size`, dark 1440×5586 and light 1440×5569; and `the layout table lists 43 tiles, each a real token`, so a typo in a layout name fails loudly instead of being skipped.
  - **`contrast_test.dart`:**
    - `double _contrast(Color a, Color b)` uses the WCAG formula `(L1 + 0.05) / (L2 + 0.05)` with `computeLuminance()`.
    - `text on bg/surface/bg-raised meets WCAG AA (4.5:1) in both themes` covers `text`, `text-2` and `text-3`.
    - `on-accent on accent meets WCAG AA in both themes`.
- [ ] **Step 2: Run them.** Expected: all pass (2 + 2 reference tests, 2 contrast tests). If a contrast check fails on a MASTER value, stop and report it; don't change the value or the threshold.
- [ ] **Step 3: Commit** `test(ZOD-UI-001): reference swatch pixels and WCAG contrast for the token values`.
- [ ] **Step 4: Mutation check.** Apply each mutant to a token file, confirm it applied with `git diff`, run the shared_ui suite, confirm the named tests fail (not a compile error), restore, and confirm `git diff --exit-code`. Record the counts in the commit body. This can be amended into the Step 3 commit while it is still unpushed; otherwise use a follow-up `test(ZOD-UI-001): mutation record` commit.
  - V1: Graphite `text-3` `0xFF7C808A` → `0xFF7C8A80`. Fails `…Graphite value`, `kit.css agrees…` and `reference … match graphite`.
  - V2: swap Porcelain `axis` and `diag`. Fails `…Porcelain value`, `kit.css agrees…` and `reference … match porcelain`.
  - V3: Graphite `accent-line` alpha `0.24` → `1.0`. Fails `…Graphite value`, `kit.css agrees…` and `reference … match graphite` (the accent-line composite).
  - V4: Porcelain `text-3` → Porcelain `line` value `#D9DCE1`. Fails `…Porcelain value`, `kit.css agrees…`, `reference … match porcelain` and `text on bg/surface/bg-raised meets WCAG AA…`.
  - No harness test fails for any mutant: the harness checks against the tokens themselves.
  - V5: Graphite `sel-inner` (not in the reference grid) `#08080A` → `#08080B`. Fails `master_values` only (both the MASTER and the kit.css tests). This documents that the 9 unshown tokens rest on those two text sources.

### Task 3: Swatch-grid harness (TDD)

**Files:** `test/support/token_swatch_grid.dart`, `test/theme/token_swatch_grid_test.dart`.

**Interfaces:**
- `class TokenSwatchGrid extends StatelessWidget { const TokenSwatchGrid({super.key}); }`. It reads the five extensions from `Theme.of(context)`, so the same widget renders either theme.
- Sections, each a title plus a `Wrap` of tiles: the five reference sections in the reference order, then "Not in the reference grid".
- A tile's root carries `Key('swatch-<token>')`. Its fill is the tile's only descendant `ColoredBox`, clipped to the rounded shape. Its label is two `Text`s: the name, then the value.
  - Names: `bg`, …, bodies capitalised as in the reference (`Sun`, …, `Mean node`).
  - Values: `#RRGGBB` upper-case for opaque tokens, and `rgba(r, g, b, .aa)` for translucent ones, with the alpha written as `a.toStringAsFixed(2)` minus its leading `0`. So the reference's `rgba(255, 255, 255, .24)` and scrim `.72` / `.40` come out the same.
- `TokenSwatchGrid` builds `RepaintBoundary(key: Key('swatch-grid'), child: <surface board>)`. The `surface` board, with its 1 px `line-soft` border and padding, is **inside** the boundary, so the captured image contains the board and translucent tiles are composited over `surface`. If the board were outside, `toImage` would return unblended translucent pixels (verified in plan review round 2).

- [ ] **Step 1: Write the failing tests.** For both themes:
  - Set `tester.view.physicalSize = const Size(1440, 1600); tester.view.devicePixelRatio = 1; addTearDown(tester.view.reset);`.
  - Pump `MaterialApp(theme: ZodiannTheme.graphite /.porcelain, home: Scaffold(body: SingleChildScrollView(child: TokenSwatchGrid())))`.

  The tests:
  - `shows all 52 tokens, reference sections first, in reference order`: the section titles, in order, are the five reference titles plus the extra one. The tile keys are, in order, the Facts lists plus the 9 extras.
  - `each tile paints its token`: for every tile, `find.descendant(of: tile, matching: find.byType(ColoredBox))` has `.color == the token`.
  - `each label shows MASTER's name and value`:
    - For all 52 tiles, `find.descendant(of: tile, matching: find.text(name))` and the same for `value` each find exactly one widget. Values repeat across tokens (for example `#F2555A` is danger, asp-hard and mars), so finders are always scoped to the tile.
    - Expected strings come from a test-local table: the MASTER name (bodies `Sun` … `Pluto`, `Mean node`), and MASTER's value text with `, ` separators (`rgba(255, 255, 255, .24)`, `rgba(11, 12, 14, .40)`).
    - Literal spot checks, scoped the same way:
      - Graphite: `#08080A` in `swatch-bg`; `Mean node` and `#9CA1AB` in `swatch-node`; `rgba(255, 255, 255, .24)` in `swatch-accent-line`.
      - Porcelain: `#F5F6F8` in `swatch-bg`; `Mean node` and `#646A74` in `swatch-node`; `rgba(11, 12, 14, .26)` in `swatch-accent-line`.
  - `renders to an image, with each tile's pixels as the reference oracle expects`:
    - Inside `tester.runAsync`, capture the `swatch-grid` boundary with `toImage(pixelRatio: 1)` and read it with `toByteData` (rawRgba, and png when writing).
    - For each of the 52 tiles, sample the centre of its fill (`tester.getCenter(fill) - tester.getTopLeft(boundary)`). It must equal the token for opaque tokens, as 8-bit ARGB. For translucent ones it must be within ±1 per channel of `Color.alphaBlend(token, surfaces.surface)`.
    - When `Platform.environment['ZODIANN_SWATCH_DIR']` is set, write `token_swatches_<theme>.png` there.
- [ ] **Step 2: Run it.** Expected: FAIL to compile (`token_swatch_grid.dart` doesn't exist).
- [ ] **Step 3: Implement** the widget per Interfaces, styled after `design-reference/zodiann/_source/components.html` (lines 13–21, 49):
  - The grid sits on a `surface` board with a 1 px `line-soft` border, so translucent tiles composite over `surface` as they do in the reference.
  - Group titles are in `text-2`.
  - Columns are fixed: 8 per row, 11 for bodies, 8 for the extra section, equal widths, 12 px gap.
  - Tiles have a 52 px fill, a 1 px `line-soft` border and rounded corners, with the name in `text` and the value in `text-3`.
  - All colours come from the theme's tokens.
  - The fill is `SizedBox(height: 52, width: double.infinity, child: ColoredBox(...))`; a fill given only a height collapses to zero width in a `Column`.
  - Labels have no fixed height, `maxLines` or ellipsis, so they wrap: test glyphs are 1 em wide.
- [ ] **Step 4: Run it again.** Expected: 4 tests × 2 themes = 8 pass. shared_ui total: 30 + 6 + 8 = 44.
- [ ] **Step 5: Commit** `test(ZOD-UI-001): token swatch-grid harness`.

### Task 4: Close-out

- [ ] **Step 1: Gates.** `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"`, both exit 0. Record the per-package counts.
- [ ] **Step 2: Visual review.**
  - Run the harness test with `ZODIANN_SWATCH_DIR` set to the session scratchpad. Crop the reference "Colour tokens" sections (dark y 200–1010, light y 200–995) into the same folder, using PowerShell `System.Drawing` or a scratch Flutter test in the scratchpad.
  - Compare them side by side: section order, tile order and colours. Text renders in the FlutterTest box-glyph font in tests, which is expected.
  - Record the result.
- [ ] **Step 3: On device** (if emulator-5554 is running). Build the debug APK, launch it, and take light and dark screenshots. Expected: blank screens in Porcelain `#F5F6F8` and Graphite `#08080A`, with no crash.
- [ ] **Step 4: Whole-branch code review** (opus, with the Review Focus and the PNGs from Step 2). Fix Critical and Important findings test-first.
- [ ] **Step 5: Docs.**
  - Task file: Status Done. Criterion 1 ← `master_values_test`. Criterion 2 ← `reference_swatches_test` + harness + visual review. Criterion 3 ← the FND-013 guard, still green.
  - TASKS.md: Done.
  - PROGRESS:
    - completed row, technical decisions (test-only harness, image oracle, no goldens), verification, next task;
    - a handoff note: "Known: dark `text-3` is below 4.5:1 on `surface-2` / `surface-3` / `accent-soft` (4.48 / 4.05 / 4.03). Avoid it there, or ZOD-NFR-009 decides.";
    - mark the FND-013 "placeholder token values" decision as superseded;
    - Git State.
- [ ] **Step 6: Commit, push, PR, and record the PR link** per the workflow.

## Acceptance Criteria → Evidence

| Criterion | Evidence |
|---|---|
| Every token in MASTER.md §2 has a corresponding value in both themes | `master_values_test`: 52 × 2 values plus the coverage test. Mutants V1–V5. |
| A rendered swatch grid (test harness) visually matches the components PNGs' token section | `reference_swatches_test` (43 tiles × 2 themes against the reference pixels, with the uniformity check). `TokenSwatchGrid` tests: the rendered tile pixels equal the reference oracle's expectations, and the labels match the reference. The side-by-side PNG review in Task 4. |
| No component references a hex literal instead of a token (ARCH-7) | FND-013's `no_color_literals_test` stays green, with literals only in `tokens/`. |

## Risks

- **The 9 tokens the reference grid doesn't show** rest on two sources, MASTER's text and the reference stylesheet `kit.css`, both machine-checked. V5 documents this.
- **Reference PNG coordinates** were measured per theme and verified with the engine's own decoder in plan review. The uniformity check catches a coordinate drifting onto an edge, and the exact-size check catches a regenerated PNG.
- **Tiles coloured like the panel** (`surface`; light `on-accent` and `cell-fill`) cannot detect a misplaced coordinate. The uniformity check and the other 42 (dark) / 40 (light) tiles cover this. Tile edges are 17 px apart between the themes; the chosen centres differ by 16, and both fall within the fill.
- **Engine futures awaited outside `runAsync`** in a `testWidgets` body hang the test until it times out (verified for `toByteData`). The plan awaits all of them inside `runAsync`, or uses a plain `test`.
- **`sel-outer` / `sel-inner`** are MASTER's values, copied as is. The light selected-cell treatment is a §6.2 "needs approval" item (D11, ZOD-SQR-008 / Gate 2), so these two values may change after approval.
- **A visible app change:** the blank shell turns Graphite/Porcelain. This is intended, since it's the task's purpose.

## Plan review

### Round 1: Approve after corrections (0 Critical, 6 Important, 9 Minor; no new user decisions)

- **I1, applied.** The light PNG's rows 3–5 sit 17 px higher than in the dark PNG. Light samples at the planned y-values landed 9 px from tile edges and passed by luck. Facts now give per-theme y-centres (verified by the reviewer with the engine decoder, all 86 samples uniform), with exact image sizes, a uniformity check and a risk note on panel-coloured tiles.
- **I2, applied.** `toByteData` awaited outside `runAsync` hangs (reproduced). The reference test uses a plain `test` with `setUpAll` decoding, and the harness capture does everything inside `runAsync`.
- **I3, applied.** Value texts repeat across tokens, so the key moved to the tile root, and every name/value finder is scoped to its tile for all 52 tiles.
- **I4, applied.** The harness board is now `surface`, as in the reference (`components.html:13`), so translucent tiles composite identically. The render test samples every tile's pixels against the oracle's expectation, tying the rendered grid to the reference. Styling and the fixed column layout follow `components.html`.
- **I5, applied.** The contrast test is scoped as a sanity check; the full pairing audit is ZOD-NFR-009.
- **I6, applied.** New `kit.css agrees with every token value` test: the reference stylesheet is a second machine-checked source for all 52 tokens, which covers the 9 the grid doesn't show. Counts: Task 1 4/4, shared_ui 30, then 44.
- **M1, applied:** RED expectation is 3 of 4.
- **M2, applied:** the test font is FlutterTest, not Ahem.
- **M3, applied:** the `tester.view` sizing API is named.
- **M4, applied:** the architecture suite is re-run after Task 1.
- **M5, applied:** tests never use `print`.
- **M6, applied:** the cropping tool and coordinates are named.
- **M7, applied:** a handoff note on dark `text-3` below AA on `surface-2` / `surface-3` / `accent-soft`.
- **M8, applied:** the D11 risk on `sel-outer` / `sel-inner`.
- **M9, applied:** the alpha formatting rule.

### Round 2 (final): Approve after corrections (0 Critical, 1 Important, 8 Minor; no user decisions)

The reviewer re-ran the baselines (shared_ui 26, architecture 23), re-measured every tile extent, and rendered the harness on the pinned SDK.

- **I1, applied.** The `surface` board must be **inside** the capture `RepaintBoundary`. Outside it, `toImage` returns unblended translucent pixels (reproduced); inside it, every sample equals `alphaBlend(token, surface)` exactly.
- **M1, applied:** the kit.css extraction regex, parsing only the 52 token names, plus an assertion that `--sign-tint` equals `signTintOpacity`.
- **M2, applied:** per-theme literal spot checks.
- **M3, applied:** the full list of tests each mutant fails, including kit.css; harness tests are unaffected by design.
- **M4, applied:** crop ranges include the row-5 labels.
- **M5, applied:** the full-width fill, and wrapping labels.
- **M6, applied:** `flutter/rendering.dart` is allowed in tests.
- **M7, applied:** the app-suite command is named.
- **M8, applied:** Risks wording on tile counts and the 17 px edge offset.

No open items.
