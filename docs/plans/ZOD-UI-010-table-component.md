# ZOD-UI-010 Table Component Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (sequential, native; see "Execution mode"). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build the shared table shell, `ZodiannTable` with its `ZodiannTableHeader` and `ZodiannTableRow` parts: a 12/500 `text-3` sentence-case header, 44 px rows with a `line-soft` divider, a `surface-2` hover fill, and a selected row with an `accent-soft` fill and a 3 px `accent` bar on the logical start edge (flips under RTL). The positions table (ZOD-WHL-018) and the degree-crossings table (ZOD-WHL-021) build on it.

**Architecture:** Three small widgets in `packages/shared_ui/lib/src/widgets/`. Column geometry is **declared** (`ZodiannTableColumn` with a flex or a fixed width), not measured from content: every row lays its cells out from the same column list, so columns line up across rows without intrinsic measurement, and a row is an independent widget that works inside a `Column` (11 positions) or a lazy `ListView.builder` (up to 2,500 crossings, WHL-021). All geometry comes from existing tokens plus three new size tokens. Every inset is directional (`EdgeInsetsDirectional`, `AlignmentDirectional`), so RTL needs no second code path.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_ui` theme extensions (`ZodiannSurfaces`, `ZodiannTextStyles`), headless pixel measurement as in `tag_sheet_test.dart` and `panel_pixels_test.dart`.

**Task:** `docs/development/shared-ui-design-system/ZOD-UI-010-implement-the-table-component-header-rows-hover-selected.md`. **Design:** `design-reference/zodiann/MASTER.md` §10 "Tables" and §14; `_source/kit.css:265-273` (`.tbl`); the component sheet `components/components_{dark,light}.png` ("Tags, tables and wheel marks": four rows Default, Hover, Selected, Default); `screens/01-zodiac-wheel_desktop_en_dark.png` and `..._he_dark.png` (Positions, Sun selected); `responsive/mobile/zodiac-wheel_mobile_en_dark.png` (compact density).

## Facts established while planning (2026-11-23)

- **kit.css `.tbl`:** `width: 100%`, collapsed borders. `th`: `text-align: start`, 12 (`--fs-xs`) / 500 / `text-3`, padding `10px 16px`, bottom `1px line-soft`, `nowrap`. `td`: padding `0 16px`, `height: 44px`, bottom `1px line-soft`, `nowrap`; the last row has no bottom border. `.end` aligns a column to the end edge. `tr.on td` fills `accent-soft`; `tr.on td:first-child` adds an inset 3 px `accent` shadow on the start side (`inset -3px` in RTL). `tr.hover td` fills `surface-2`. There is no real `:hover` rule: the sheet shows hover as a class, and MASTER says "Hover is `surface-2`".
- **Row pitch in the screenshot is 44** including the divider (Sun 530, Moon 574, Mercury 618): the 44 is the whole row, divider included.
- **Tokens that exist:** `ZodiannSize.tableRow` (44), `ZodiannSpace.s4` (16), `ZodiannSize.hairline` (1), `ZodiannSurfaces.surface2 / lineSoft / text / text3 / accent / accentSoft`, `ZodiannTextStyles.label` (12 / 1.45 / 500: "table headers"), `body` (14 / 1.45 / 400: "table cells"), `small` (13). **Missing:** the header's block padding (10), the compact inline padding (10, `wheel.html:42` below 1100 px, with `small` text), the selected bar width (3; `navActiveBar` is the drawer's, a different thing).
- **Consumers:** only ZOD-WHL-018 and ZOD-WHL-021 name UI-010 as a dependency. The About screen's tables (`about.html:12`) override the table to wrap, with `padding-block: 10` and `vertical-align: top`; they are **not** in this task (see Out of scope).
- **WHL-021 shows up to 2,500 rows** in a scroll area, so the row cannot depend on a whole-table measurement; this drives the declared-column design.
- **Flutter 3.50 has table semantics** (`SemanticsRole.table / row / cell / columnHeader`, `semantics.dart:171-174`). The table role requires its children to be `row` roles (`semantics.dart:353`).
- **UI-014 carried decision:** "UI-010 decides the panel clip opt-in for full-bleed rows". A hovered or selected last row paints a square fill over the panel's 11 px inner corner unless the panel clips (decision D4).
- **`ZodiannPressable` is not reused.** It applies a brightness filter, a 1 px press drop and a 42 % disabled look; a table row needs a fill change and none of those (decision D5).

## Decisions

Defaults the plan implements unless the owner says otherwise (see "Open decisions"). **D1 to D3 are product-visible.**

- **D1. Declared columns, not content-measured.** `ZodiannTableColumn(label:, alignment:, flex:, width:)`; a column is `flex` (default 1) or a fixed `width`, never both. The browser sizes `.tbl` columns from content; a lazy 2,500-row list cannot, and WHL-021 needs the list. Consumers choose the flex ratios that reproduce the designer's screens; the sheet test pins the ratios it uses.
- **D2. Selected beats hover**, and hover and selection apply to the **whole row**, from edge to edge (the cells carry no gaps). Hover applies only to a row that has `onTap` (a read-only row such as an About row is not interactive, so it must not look it).
- **D3. Two densities.** `ZodiannTableDensity.regular` (inline padding 16, 14 text) and `.compact` (inline padding 10, 13 `small` text, the kit's override under 1100 px). The **caller** picks it per breakpoint (WHL-024); the table does not read the breakpoint itself, because only the screen knows it is in the compact layout.
- **D4. The table never clips.** A panel that holds a table passes `clipBehavior: Clip.antiAlias` so a hovered or selected last row does not square off the corner; row focus is drawn inside the row (D5), so clipping hides nothing. Task 6 proves it. `ZodiannPanel`'s default stays `Clip.none` (UI-014).
- **D5. Own interaction layer on `Focus` + `MouseRegion` + `GestureDetector`/`Actions`:** tap and Enter / Space activate, a keyboard-only 2 px `focus` ring is drawn **inside** the row's edge (inset, so it is never clipped), hover is tracked with `MouseRegion`. No press look and no brightness filter.
- **D6. Minimum height 44, grows with the text scale** (as the tag): a row is `ConstrainedBox(minHeight: ZodiannSize.tableRow)`, the divider is part of the 44. Cells do not ellipsize or wrap by themselves (kit `nowrap`): the caller's cell widget decides.
- **D7. Semantics:** the table is `SemanticsRole.table`, the header and each row `row`, each header label `columnHeader`, each cell `cell`; a tappable row is a button, a selected row `selected: true`; a row that is not selected carries **no** selected state (as UI-004: in Flutter 3.50 `false` is a state a screen reader announces).

## Design (API)

```dart
enum ZodiannTableAlign { start, end }
enum ZodiannTableDensity { regular, compact }

class ZodiannTableColumn {
  const ZodiannTableColumn({
    required this.label,                       // localized by the caller, sentence case
    this.alignment = ZodiannTableAlign.start,
    this.flex = 1,                             // ignored when width != null
    this.width,                                // fixed logical px
  });
}

class ZodiannTable extends StatelessWidget {
  const ZodiannTable({
    super.key,
    required this.columns,
    required this.rows,                        // List<ZodiannTableRow>; eager, shrink-wrapped
    this.density = ZodiannTableDensity.regular,
  });
}

/// The header row, public so a lazy list can pin it above a ListView.
class ZodiannTableHeader extends StatelessWidget {
  const ZodiannTableHeader({super.key, required this.columns,
      this.density = ZodiannTableDensity.regular});
}

class ZodiannTableRow extends StatelessWidget {
  const ZodiannTableRow({
    super.key,
    required this.columns,                     // the same list the header has
    required this.cells,                       // cells.length == columns.length (assert)
    this.selected = false,
    this.onTap,                                // null: read-only row, no hover, no focus
    this.semanticLabel,                        // the row's spoken name; required when onTap != null
    this.isLast = false,                       // true: no divider (kit `tr:last-child td`)
    this.density = ZodiannTableDensity.regular,
  });
}
```

- A cell is any widget. `ZodiannTableRow` wraps each in a directional alignment (start or end, vertically centred), the density's inline padding, and `DefaultTextStyle` of `body` (or `small` when compact) in `text`. The caller styles inside the cell (`pos` is 14 / 500).
- `ZodiannTable` builds `[header, ...rows]` in a `Column` and marks the **last** row `isLast` itself, so callers of the eager form never set it; a lazy list sets `isLast` on its last item (or accepts the divider under it, which the kit does not draw).
- Fill order (bottom to top): `surface` (the panel) < hover `surface-2` < selected `accent-soft`, then the divider (bottom 1 px, `line-soft`), then the 3 px selected bar at the start edge, then the keyboard ring.

## Global Constraints

- Values from tokens, never literals: `test/architecture/no_magic_dimensions_test.dart`, `no_color_literals_test.dart`; text styles derived with `copyWith` from `ZodiannTextStyles` roles; sentence case (`no toUpperCase(`); no string literal in `Text` in shipped `lib/` (`no_text_literals_test.dart`); labels come from the caller.
- Material types from `package:material_ui`, never `flutter/material.dart`.
- Directional geometry only (`EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderDirectional`, `PositionedDirectional`); no `left` / `right`.
- Run `test/architecture` with `dart test test/architecture`, never `flutter test` (PROGRESS conventions). Run Flutter commands as `fvm flutter …`, Melos as `fvm dart run melos …`.
- Reduced motion: the component has no animation (a state change is an instant fill change, as kit.css has no transition on `.tbl`).

## Review Focus

Inputs the spec implies and no acceptance criterion exercises; each has a test in the named task.

1. **Hebrew / RTL with a bidi cell:** a Hebrew label and an LTR number (`17°03′`) in one row; the end-aligned column must stay at the end edge, the bar on the right. (Task 3, Task 5)
2. **Text scale 1.5 or more:** a row grows and its divider and bar still span the whole row; the header grows. (Task 3)
3. **A cell wider than its column / a narrow table (phone width 390):** a fixed-width plus flex mix must not throw an overflow and must keep all rows aligned. (Task 2)
4. **Selected and hovered at once, and a selected last row in a clipped panel:** selected wins; the corner is not squared. (Task 3, Task 6)
5. **A row with `onTap` but no semantic label, or `cells.length != columns.length`:** an assertion in debug, never a silent misalignment. (Task 2, Task 4)

## Out of scope

- The About screen's wrapping tables (`about.html:12`: auto height, `padding-block: 10`, top-aligned). No dependency names UI-010 for them; the API does not forbid it (cells are free widgets), but the variant is not built or tested here. Flag to the About tasks.
- Sorting, sticky header, column resize, selection by checkbox, row virtualization inside the table itself (the building blocks make a lazy list possible; WHL-021 composes it).
- The positions table's content (glyph cells, `℞`, columns dropped on a phone) and the crossings two-line phone list: WHL-018 / WHL-021.
- The scroll-edge fade of the crossings list (WHL-021).
- The visual regression harness (ZOD-UI-015).

## File structure

- Modify `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart`: add `ZodiannSize.tableHeaderPadding` (10), `tableCompactPadding` (10), `tableSelectedBar` (3).
- Create `packages/shared_ui/lib/src/widgets/zodiann_table_column.dart`: `ZodiannTableAlign`, `ZodiannTableDensity`, `ZodiannTableColumn`, and the private column layout (one `RenderObject`-free `Row` of `Expanded` / `SizedBox`, shared by header and rows).
- Create `packages/shared_ui/lib/src/widgets/zodiann_table.dart`: `ZodiannTable`, `ZodiannTableHeader`, `ZodiannTableRow` and their private paint helpers (divider, bar, ring).
- Modify `packages/shared_ui/lib/shared_ui.dart`: export both (the column file's public types; hide privates).
- Create tests: `test/widgets/table_test.dart` (layout, states, RTL, text scale, semantics, interaction), `test/widgets/table_sheet_test.dart` (pixels against the sheet in both themes, the Hebrew bar, compact against the mobile PNG), `test/widgets/table_panel_test.dart` (panel clip), support `test/support/table_features.dart`.
- Documentation: the task file, `docs/development/TASKS.md`, `docs/PROGRESS.md` (Architecture Conventions "Tables", Technical Decisions, Verification, Git State).

## Tasks

### Task 1: Tokens and the measured oracle

**Files:** modify `zodiann_dimensions.dart`; test `test/theme/` (extend the existing dimension-token test, whichever file holds `ZodiannSize.tableRow`); a scratch measurement (scratchpad, not committed) whose results are recorded under "Measured facts" below.

**Interfaces:** Produces `ZodiannSize.tableHeaderPadding` (10.0), `ZodiannSize.tableCompactPadding` (10.0), `ZodiannSize.tableSelectedBar` (3.0).

- [ ] **Step 1: RED.** In the existing token test, assert the three values and that each has a doc comment naming its kit.css source (the file's convention); run it and confirm it fails because the constants do not exist.
- [ ] **Step 2: Implement** the three constants in `ZodiannSize`.
- [ ] **Step 3: Run** the token test and `dart test test/architecture` (the magic-dimension guard reads this directory as exempt); both pass.
- [ ] **Step 4: Measure the sheet** (both themes) and the three screenshots with a scratch Dart script using `package:image`: for the four sheet rows, header height, row tops, divider row y, fill colours at the cell centre (default, hover, selected), the selected bar's x-run and colour, whether the bar covers the divider row, the last row's height without a divider, and the column left edges. Write each into "Measured facts" as a literal. If a measured value differs from the expectation (header ≈ 38.4: 10 + 17.4 + 10 + 1; row 44 including the divider; bar 3 wide over the row height), the measured value is the oracle and the difference is recorded.
- [ ] **Step 5: Commit** `feat(ZOD-UI-010): add the table size tokens`.

### Task 2: Column spec and row layout (RED first)

**Files:** create `zodiann_table_column.dart`, a first `zodiann_table.dart` (row and header skeleton, no states yet); test `test/widgets/table_test.dart`.

**Interfaces:** Consumes the tokens above. Produces `ZodiannTableColumn`, `ZodiannTableAlign`, `ZodiannTableDensity`, `ZodiannTableHeader`, `ZodiannTableRow`, `ZodiannTable` per "Design (API)".

- [ ] **Step 1: Write the failing tests** (names, with assertions):
  - `columns share their left edges in every row`: three rows with different cell widths, columns `flex 2 / 1 / fixed 80`, in a 600 px parent; every row's n-th cell has the same left offset and width (flex widths `(600 - 80) × 2/3` and `× 1/3`).
  - `an end-aligned column ends at the end edge`: the cell's right edge (LTR) equals the column's right edge minus the inline padding; in RTL the cell's left edge equals the column's left edge plus the padding.
  - `inline padding is 16 regular and 10 compact`, read from the first cell's offset.
  - `a narrow parent does not overflow` (390 px with `flex 3 / 2 / fixed 120 / flex 1`): no `FlutterError` from the test binding, all rows aligned.
  - `cells.length must equal columns.length` and `a fixed width and a flex are mutually exclusive` throw `AssertionError` in debug (`expect(() => …, throwsAssertionError)`).
- [ ] **Step 2: Run** them and confirm they fail because the symbols are missing.
- [ ] **Step 3: Implement** `ZodiannTableColumn` (with its asserts) and the shared column layout (`Row` of `Expanded(flex:)` and `SizedBox(width:)` children under a directional alignment), the header and row skeleton with padding and alignment only.
- [ ] **Step 4: Run** the tests; all pass.
- [ ] **Step 5: Commit** `feat(ZOD-UI-010): add table columns and row layout`.

### Task 3: Header, row, hover and selected looks, RTL and text scale

**Files:** modify `zodiann_table.dart`; test `table_test.dart`.

**Interfaces:** Consumes Task 2. Produces the painted states (fill order in "Design (API)").

- [ ] **Step 1: Write the failing tests:**
  - `header is label style over text-3 with a line-soft rule`: the header text style is `styles.label` with `text3`; a descendant paints a `lineSoft` rule of `ZodiannSize.hairline` at the bottom; vertical padding is `tableHeaderPadding`; header label text has no `toUpperCase` effect (a mixed-case label renders as given).
  - `a row is 44 high including its divider` (no text scale); `the last row has no divider` (`isLast`), and its height is the measured value from Task 1.
  - `hover fills surface-2 on a row with onTap`, using `TestGesture` with a mouse pointer; `a row without onTap does not react to hover`.
  - `selected fills accent-soft and wins over hover`.
  - `the selected bar is 3 wide on the start edge` in LTR (left) and in RTL (right): read from the painted `BorderDirectional` / positioned bar widget's resolved rect, not from colour.
  - `a row grows with the text scale` (`TextScaler.linear(1.5)` and a 2.0 case): height > 44, the bar and divider still span the row's height.
  - `an RTL row mirrors the order of the cells`.
- [ ] **Step 2: Run** them; confirm each fails for the expected reason (no fill, no bar).
- [ ] **Step 3: Implement** the row's states: `ColoredBox` fill, directional bar (`PositionedDirectional(start: 0, width: tableSelectedBar)` over the row's full height, inside the divider rule), divider as the bottom `BorderSide` of a `DecoratedBox`, honouring `isLast`; header with the rule. Pull colours from `ZodiannSurfaces`.
- [ ] **Step 4: Run** the tests; all pass; run `fvm flutter analyze --fatal-infos` for `shared_ui`.
- [ ] **Step 5: Commit** `feat(ZOD-UI-010): paint table header, rows, hover and selected`.

### Task 4: Interaction and semantics

**Files:** modify `zodiann_table.dart`; test `table_test.dart`.

- [ ] **Step 1: Write the failing tests:**
  - `tap and Enter and Space activate onTap`; a row without `onTap` is not focusable (`Tab` skips it).
  - `keyboard focus draws a 2 px focus ring inside the row`, only after keyboard traversal (not after a mouse tap), and the ring's rect lies within the row's rect (never outside).
  - `semantics tree`: table node has `SemanticsRole.table`; the header and each row `row`; each header label `columnHeader`; each cell `cell`; a tappable row has the button and tap flags and the label; a selected row has `isSelected` true; an unselected row has **no** selected flag (`SemanticsFlag.hasSelectedState` absent); no `SemanticsNode` throws the role assertions with `ZodiannTableRow`s used standalone in a `ListView`.
  - `a tappable row without semanticLabel asserts`.
- [ ] **Step 2: Run** them; confirm they fail.
- [ ] **Step 3: Implement** D5 and D7: `Focus` with a `focusHighlightMode` check (keyboard-only ring, as `ZodiannPressable` decides it), `Actions` for `ActivateIntent`, `MouseRegion` for hover, `Semantics` roles. Reuse `ZodiannPressable`'s keyboard-only test only if it is exposed; otherwise read `FocusManager.instance.highlightMode` directly.
- [ ] **Step 4: Run** the tests; pass.
- [ ] **Step 5: Commit** `feat(ZOD-UI-010): make table rows interactive and accessible`.

### Task 5: Pixel proof against the designer's sheet, both themes, RTL and compact

**Files:** create `test/support/table_features.dart`, `test/widgets/table_sheet_test.dart`.

- [ ] **Step 1: Write the test** (acceptance criterion 1). For each theme, render the sheet's four rows (Default, Hover, Selected, Default; columns Body, Sign, Position, Motion, State with the flex ratios that reproduce the sheet's measured column edges, recorded in the test) at an integer origin and compare with `components_{dark,light}.png` under the tag test's tolerances (fill ±1 per channel; text ±3; geometry exact): header height, row pitch, divider row and colour, the three fills, the bar's width and colour. The cell contents are plain text and ASCII-safe shapes (the glyph and sign cells are WHL-018's), so the comparison covers geometry and fills, not glyph pixels.
- [ ] **Step 2: Add the RTL case** (criterion 2): the bar's pixel run in `01-zodiac-wheel_desktop_he_dark.png` is on the right edge of the Sun row, and the same render in RTL puts it on the right; in LTR on the left (`..._en_dark.png`). Both runs are 3 px wide with the `accent` colour at the cell's vertical centre.
- [ ] **Step 3: Add the compact case:** the mobile wheel PNG's compact positions rows (inline padding 10, 13 text) against `ZodiannTableDensity.compact`: padding, row height, divider.
- [ ] **Step 4: Run** the sheet test; if it fails for a geometry reason, fix the implementation, never the tolerance; if the reference and the kit disagree, record it (the NAV-002 / UI-009 precedent: the kit wins over MASTER's prose; MASTER is not edited).
- [ ] **Step 5: Commit** `test(ZOD-UI-010): match the sheet's table rows in both themes`.

### Task 6: Panel integration, export, verification, review, documentation

**Files:** create `test/widgets/table_panel_test.dart`; modify `shared_ui.dart`; documentation per "File structure".

- [ ] **Step 1: Write and run** `a table in an antiAlias panel keeps its rounded corner`: a `ZodiannPanel(clipBehavior: Clip.antiAlias, bodyPadding: EdgeInsets.zero)` whose last row is selected; the pixel at the panel's inner bottom corner is the panel's border/background, not `accent-soft`. And the same panel without a clip squares the corner (documents D4's reason).
- [ ] **Step 2: Export** `ZodiannTable`, `ZodiannTableHeader`, `ZodiannTableRow`, `ZodiannTableColumn`, `ZodiannTableAlign`, `ZodiannTableDensity` from `shared_ui.dart` (alphabetical among the widgets).
- [ ] **Step 3: Verification:** `fvm dart run melos run lint`, `fvm dart run melos run test`, `dart test test/architecture` (separately, one process at a time); record counts and exit codes and the head commit.
- [ ] **Step 4: Whole-branch review** by a fresh reviewer (`requesting-code-review`); fix Important findings test-first.
- [ ] **Step 5: Documentation** after verification: task file status and completion notes, `TASKS.md`, `PROGRESS.md` (Architecture Conventions "Tables (UI-010)": use the table parts, declared columns, the antiAlias panel rule, density chosen by the caller; Technical Decisions D1 to D7; Verification; Git State; Next Recommended Task).
- [ ] **Step 6: Commit and push** per the workflow, open the PR, record the link.

## Acceptance criteria mapping

1. Header, row, hover and selected states match the screenshots in both themes: Tasks 3 and 5 (sheet, both themes; the desktop screenshot for the bar; compact against the mobile PNG).
2. The selected-row accent edge renders on the correct logical side in LTR and RTL: Tasks 3 (geometry) and 5 (Hebrew screenshot pixels).

## Execution mode

Sequential, native (`executing-plans`). No independent work: the tasks share two files and each builds on the previous interface. No subagents except the mandatory plan review and whole-branch review.

## Risks

- **Flutter 3.50 semantics roles** may be stricter than the SDK source suggests (the table role validates its children). Task 4's tree test is the early check; fall back to row and cell roles only if the table role cannot hold a lazy list.
- **Sheet cell contents** use glyph fonts; the test compares geometry and fills only, so a font difference cannot fail it.
- **Row height with text scale**: a row is a minimum height, so the 44 is exact only at scale 1.
- **Declared flex ratios** are an approximation of the browser's content sizing; the sheet test pins one set, WHL-018 / 021 re-verify against their own screens.

## Open decisions (for the owner; defaults are implemented)

- **O1 (D1):** declared columns (flex or fixed) instead of content-measured columns. Alternative: Flutter's `Table` with `IntrinsicColumnWidth`, which matches the browser's content sizing but is not lazy, so WHL-021's 2,500 rows would be built and measured eagerly.
- **O2 (D2):** hover only on tappable rows; selected wins over hover.
- **O3 (D3):** build the compact density now (the kit defines it; WHL-018 / 021 need it below 1100 px), chosen by the caller. Alternative: leave it to the wheel tasks, which would then need a size token of their own.
- **O4 (D4):** a panel with a table passes `Clip.antiAlias`; the table itself does not clip.
- **O5:** the About screen's wrapping tables stay out of this task.

## Plan review

_Pending: the `plan-reviewer` cycle runs next (at most two rounds); the record is added here._
