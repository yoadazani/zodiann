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
- **D2. Selected beats hover**, and hover and selection apply to the **whole row**, from edge to edge (the cells carry no gaps). Hover applies only to a row that has `onTap` (a read-only row such as an About row is not interactive, so it must not look it). Hover has no effect on touch, and a pressed state is deliberately absent (D5).
- **D3. Two densities.** `ZodiannTableDensity.regular` (inline padding 16, 14 text) and `.compact` (inline padding 10, 13 `small` text, the kit's override under 1100 px). The **caller** picks it per breakpoint (WHL-024); the table does not read the breakpoint itself, because only the screen knows it is in the compact layout.
- **D4. The table never clips.** A panel that holds a table passes `clipBehavior: Clip.antiAlias` so a hovered or selected last row does not square off the corner; row focus is drawn inside the row (D5), so clipping hides nothing. Task 6 proves it. `ZodiannPanel`'s default stays `Clip.none` (UI-014).
- **D5. Own interaction layer on `FocusableActionDetector` (focus, hover, Enter / Space) + `GestureDetector` for tap:** a keyboard-only 2 px `focus` ring is drawn **inside** the row's edge (inset, so it is never clipped). No press look and no brightness filter.
- **D6. Minimum height 44, grows with the text scale** (as the tag): a row is `ConstrainedBox(minHeight: ZodiannSize.tableRow)`, the divider is part of the 44. **Overflow (decided):** each cell is laid out with its slot's width as the maximum, in a clipped slot (`ClipRect` over `AlignmentDirectional`): a plain widget wider than the slot is clamped and never moves another column. A `Row` or other flex cell that cannot shrink overflows by its own contract, and the caller wraps it in `Flexible` or an ellipsis; the table does not hide it. The header's labels are `maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis` (the kit's `nowrap`); body cells are the caller's widgets, which wrap long text in `Flexible` or an ellipsis. A table needs a bounded width (flex columns use `Expanded`): in an unbounded-width parent (a horizontal scroll) it asserts with a message, and the caller gives it a `SizedBox(width:)` instead.
- **D7. Semantics:** the table roles (`SemanticsRole.table`, `row`, `columnHeader`, `cell`) are emitted **only inside `ZodiannTable`** (eager). Flutter 3.50's role checks (`semantics.dart:350-388`) require a `row` to have a `table` parent and a table's children to be rows, so a standalone `ZodiannTableRow` or `ZodiannTableHeader` in a lazy `ListView` (WHL-021) would assert in debug if it carried a role. Standalone parts therefore carry **no** table, row, cell or columnHeader role: only `Semantics(container: true)`, button and tap semantics for a tappable row, and `selected: true` for the selected row. A lazy list has no table semantics; WHL-021 owns an alternative (for example a labelled list) if it needs one. A row that is not selected carries **no** selected state (as UI-004: in Flutter 3.50 `false` is a state a screen reader announces). Each row and cell is `container: true` so they do not merge into the parent node.

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
    this.columns,                              // null inside a ZodiannTable (read from its scope); required outside
    required this.cells,                       // cells.length == columns.length (assert)
    this.selected = false,
    this.onTap,                                // null: read-only row, no hover, no focus
    this.semanticLabel,                        // the row's spoken name; required when onTap != null
    this.isLast = false,                       // standalone lists only; ZodiannTable sets it for its last row
    this.density,                              // null inside a ZodiannTable (scope); regular outside
  });
}
```

- A cell is any widget. `ZodiannTableRow` wraps each in a directional alignment (start or end, vertically centred), the density's inline padding, and `DefaultTextStyle` of `body` (or `small` when compact) in `text`. The caller styles inside the cell (`pos` is 14 / 500).
- **Mechanism** (rows are already-built widgets, so the table cannot set their fields): `ZodiannTable` wraps its header and rows in a private `_TableScope` `InheritedWidget` (columns, density, `inTable: true`) and wraps the last row in a private `_LastRow` marker. A `ZodiannTableRow` reads `columns` and `density` from the scope when its own are null; outside a table with `columns == null` it asserts "ZodiannTableRow outside a ZodiannTable needs columns". Inside a table a row must not pass its own `columns` or `density` (debug assert: a row that disagrees with the table would silently misalign). `ZodiannTable` builds its header from its own `columns` and `density`, passed explicitly; `ZodiannTableHeader` reads the scope only for `inTable` and never asserts on its explicit values (the "no own columns" assert is for rows only). Callers of the eager form never set `isLast`; a lazy list sets it on its last item (or accepts the divider under it, which the kit does not draw). Roles (D7) are emitted only when `inTable` is true.
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
3. **A narrow table (phone width 390):** a fixed-width plus flex mix must not throw an overflow and must keep all rows aligned. (Task 2)
4. **Selected and hovered at once, and a selected last row in a clipped panel:** selected wins; the corner is not squared. (Task 3, Task 6)
5. **A row with `onTap` but no semantic label, `cells.length != columns.length`, or its own `columns` inside a table:** an assertion in debug, never a silent misalignment. (Task 2, Task 4)
6. **A cell wider than its column, and a table in an unbounded-width parent:** a wide plain widget is clamped and moves no column; a long text in `Flexible` ellipsizes; the unbounded case fails with a clear message. (Task 2)
7. **Hebrew, text scale 1.5 and a selected row together.** (Task 3)

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

**Files:** modify `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart`; test `packages/shared_ui/test/theme/dimensions_test.dart` (it holds `tableRow` at line 93 and parses `kit.css` at lines 200-221); a throwaway measurement test (not committed) whose results are written under "Measured facts" below.

**Interfaces:** Produces `ZodiannSize.tableHeaderPadding` (10.0), `ZodiannSize.tableCompactPadding` (10.0), `ZodiannSize.tableSelectedBar` (3.0).

- [ ] **Step 1: RED.** In `dimensions_test.dart`, following the file's convention of parsing the kit, assert the three values and that the kit agrees where it can be parsed: `.tbl th` padding-block is 10 (`_rule(css, '.tbl th')`) and `wheel.html`'s `padding-inline: 10px`; the 3 px bar is not parseable from kit.css (`inset 3px`), so assert the value only. Write a doc comment on each constant naming its kit source. Run `cd packages/shared_ui; fvm flutter test test/theme/dimensions_test.dart`; expected: a compile failure naming the three missing constants.
- [ ] **Step 2: Implement** the three constants in `ZodiannSize`.
- [ ] **Step 3: Run** the same test command and `dart test test/architecture` (from the repo root; one process at a time); both pass.
- [ ] **Step 4: Measure the sheet** (both themes) and the screenshots with a throwaway `flutter_test` file in `packages/shared_ui/test/` that decodes the PNGs with `dart:ui` as `test/support/pixels.dart` does (`package:image` is a root dev dependency only; do not use it from a scratchpad script). Measure: for the four sheet rows, header height, row tops, divider row y, fill colours at the cell centre (default, hover, selected), the selected bar's x-run and colour, whether the bar covers the divider row, the last row's height without a divider, and the column left edges. Write each into "Measured facts" as a literal, then delete the throwaway file. If a measured value differs from the expectation (header ≈ 38.4: 10 + 17.4 + 10 + 1; row 44 including the divider; bar 3 wide), the measured value is the oracle and the difference is recorded. The "row is 44 including its divider" test is for non-last rows; the `isLast` test equals the measured value (43 or 44).
- [ ] **Step 5: Commit** `feat(ZOD-UI-010): add the table size tokens`.

#### Measured facts (filled in Task 1, Step 4)

Measured 2026-11-23 from `components_{dark,light}.png` (1440 wide, 1x) and the desktop wheel screenshots (1x), by pixel scans (throwaway test, deleted):

- **Row pitch 44, divider included.** A non-last row is 43 px of fill plus a 1 px `line-soft` divider as its last row of pixels (sheet dark: dividers at y 3609 and 3653, selected fill 3610..3652; light: dividers 3547, 3591, 3635).
- **The last row is 43 px** (no divider): wheel Positions, previous divider y 948, last row fill 949..991, panel bottom border 992. So the `isLast` height is **43** (the plan's M2 alternative resolved).
- **Header: 38 px of label area + 1 px rule = 39 in dark, 37 + 1 = 38 in light**: the same 38.4 (10 + 17.4 + 10 + 1) snapped differently by Chrome. The header-height assertion allows ±1.
- **Fills** (opaque, over the panel's `surface`): dark default `111114`, hover `18181c`, selected `222225`, divider `1b1b20`; light default `ffffff`, hover `f4f5f7`, selected `f1f1f1`, divider `e7e9ed`.
- **Selected and hover fills stop above the divider.** The dividers above and below a selected row stay `line-soft` (not tinted): the fill is the 43 px between them (wheel: dividers 508 and 552, fill 509..551).
- **The bar** is 3 px wide (dark `f4f5f7` = `accent`), covers the **43 px of fill, not the divider rows** (wheel x=948: bar 509..551, dividers 508 and 552 untouched), and sits **inside the panel's 1 px border**: LTR sheet panel border x=508, bar 509..511; English screen border 946, bar 947..949; **Hebrew screen panel 24..493, bar 490..492** (right edge, inside the border).
- **Sheet geometry for the comparison:** the table is 890 px wide (panel inner 509..1398, right border 1399). Column starts relative to 509, from the text starts less the 16 px padding: Body 0, Sign 183, Position 335 (844 - 509), Motion 439 (948 - 509), State 588 (1097 - 509), end 890; widths **183, 152, 104, 149, 302** (the flex values the sheet test uses).
- **Compact reference:** `responsive/mobile/zodiac-wheel_mobile_en_dark.png` is 780 px wide, a 2x capture.
- **Unexplained but irrelevant:** the sheet's table panel shows a 24 px band and a rule above the header (3458..3482 dark); the test renders the table alone and compares from the header's first row down.

### Task 2: Column spec and row layout (RED first)

**Files:** create `zodiann_table_column.dart`, a first `zodiann_table.dart` (row and header skeleton, no states yet); test `test/widgets/table_test.dart`.

**Interfaces:** Consumes the tokens above. Produces `ZodiannTableColumn`, `ZodiannTableAlign`, `ZodiannTableDensity`, `ZodiannTableHeader`, `ZodiannTableRow`, `ZodiannTable` per "Design (API)".

- [ ] **Step 1: Write the failing tests** (names, with assertions):
  - `columns share their left edges in every row`: three rows with different cell widths, columns `flex 2 / 1 / fixed 80`, in a 600 px parent; every row's n-th cell has the same left offset and width (flex widths `(600 - 80) × 2/3` and `× 1/3`).
  - `an end-aligned column ends at the end edge`: the cell's right edge (LTR) equals the column's right edge minus the inline padding; in RTL the cell's left edge equals the column's left edge plus the padding.
  - `inline padding is 16 regular and 10 compact`, read from the first cell's offset.
  - `a narrow parent does not overflow` (390 px with `flex 3 / 2 / fixed 120 / flex 1`): no `FlutterError` from the test binding, all rows aligned.
  - `cells.length must equal columns.length` and `a fixed width and a flex are mutually exclusive` throw `AssertionError` in debug (`expect(() => …, throwsAssertionError)`).
  - `a cell wider than its column moves no other column`: two cells, `SizedBox(width: 500)` and `Row(children: [Flexible(child: Text(longString))])`; no `FlutterError` from the binding, the other columns' offsets equal those of a row without them. A second test documents the contract: a `Row` of fixed-width children wider than the slot **does** report a `RenderFlex` overflow (the caller's duty, D6).
  - `a table in an unbounded-width parent asserts with a message` (a horizontal `SingleChildScrollView` without a `SizedBox`).
  - `a row inside ZodiannTable inherits columns and density` (the row passes neither), and `a row that passes its own columns inside a table asserts`, and `a row outside a table without columns asserts "needs columns"`.
  - `ZodiannTable gives the last row no divider without the caller setting isLast`.
- [ ] **Step 2: Run** `cd packages/shared_ui; fvm flutter test test/widgets/table_test.dart`; expected: a compile failure ("Undefined class 'ZodiannTableColumn'" and the other missing symbols).
- [ ] **Step 3: Implement** `ZodiannTableColumn` (with its asserts), the shared column layout (`Row` of `Expanded(flex:)` and `SizedBox(width:)` slots, each a `ClipRect` over `AlignmentDirectional`), the private `_TableScope` and `_LastRow`, and the header and row skeleton with padding and alignment only.
- [ ] **Step 4: Run** the same command; all pass.
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
  - `a row grows with the text scale` (`TextScaler.linear(1.5)` and a 2.0 case): height > 44, the fill and the bar still span the row's height; the divider stays 1 px at the bottom.
  - `an RTL row mirrors the order of the cells`.
  - `Hebrew, text scale 1.5 and a selected row together`: RTL, a Hebrew label with an LTR number, scale 1.5, selected; the bar is on the right, the end-aligned column ends at the left edge's mirror, no overflow.
- [ ] **Step 2: Run** `cd packages/shared_ui; fvm flutter test test/widgets/table_test.dart`; expected: assertion failures per new test (no fill, no bar).
- [ ] **Step 3: Implement** the row's states: `ColoredBox` fill, directional bar (`PositionedDirectional(start: 0, width: tableSelectedBar)`), divider as the bottom `BorderSide` of a `DecoratedBox`, honouring `isLast`; header with the rule. Whether the bar covers the divider row follows the measured fact from Task 1 (the kit's inset shadow lies inside the cell's padding box, so the expectation is that it does not); the test asserts the measured behaviour. Pull colours from `ZodiannSurfaces`.
- [ ] **Step 4: Run** the same command; all pass; then `cd packages/shared_ui; fvm flutter analyze --fatal-infos`.
- [ ] **Step 5: Commit** `feat(ZOD-UI-010): paint table header, rows, hover and selected`.

### Task 4: Interaction and semantics

**Files:** modify `zodiann_table.dart`; test `table_test.dart`.

- [ ] **Step 1: Write the failing tests:**
  - `tap and Enter and Space activate onTap`; a row without `onTap` is not focusable (`Tab` skips it).
  - `keyboard focus draws a 2 px focus ring inside the row`, only after keyboard traversal (not after a mouse tap), and the ring's rect lies within the row's rect (never outside).
  - `inside ZodiannTable: roles table / row / columnHeader / cell, no assertion thrown`, and the node tree shape is table, then the header row and the rows, then their cells (each row and cell `container: true`); the table includes at least one tappable row (the focus path), no assertion is thrown, and the table's direct children are all `row`.
  - `standalone rows and header in a ListView: no role assertion thrown`, tappable rows are buttons with their label, and no node carries a table, row, cell or columnHeader role.
  - `a tappable row has the button and tap flags and the label; a selected row has isSelected true; an unselected row has no selected state` (`SemanticsFlag.hasSelectedState` absent).
  - `a tappable row without semanticLabel asserts`.
- [ ] **Step 2: Run** `cd packages/shared_ui; fvm flutter test test/widgets/table_test.dart`; expected: failures per new test (no `Focus`, no roles).
- [ ] **Step 3: Implement** D5 and D7 on `FocusableActionDetector(onShowFocusHighlight:, onShowHoverHighlight:, actions: {ActivateIntent: …})` (which supplies the Enter and Space mapping and reacts when the highlight mode changes, as `ZodiannPressable` does with `onShowFocusHighlight`; a bare `Actions` + `Focus` works only under a `WidgetsApp` shortcut table, which a test harness lacks). The ring width is `ZodiannStates.focusRingWidth` (2.0), drawn **inside** the row's edge (inset, not `focusRingGap`). Roles come from the `_TableScope.inTable` flag (D7). **Wrapper order:** the row's `Semantics(container: true, role: row when inTable, button / onTap / selected / label)` is the outermost wrapper and the `FocusableActionDetector` sits **inside** it, so the focus semantics (`Focus` adds its own non-container node, `focus_scope.dart:714`) merge into the row node instead of becoming a roleless node between the table and the row, which `_semanticsTable` would reject. If the detector cannot sit inside, pass `includeFocusSemantics: false` and put `focusable` and `focused` on the row's `Semantics`.
- [ ] **Step 4: Run** the same command; pass.
- [ ] **Step 5: Commit** `feat(ZOD-UI-010): make table rows interactive and accessible`.

### Task 5: Pixel proof against the designer's sheet, both themes, RTL and compact

**Files:** create `test/support/table_features.dart`, `test/widgets/table_sheet_test.dart`.

- [ ] **Step 1: Write the test** (acceptance criterion 1). For each theme, render the sheet's four rows (Default, Hover, Selected, Default; columns Body, Sign, Position, Motion, State with the flex ratios that reproduce the sheet's measured column edges, recorded in the test) at an integer origin and compare with `components_{dark,light}.png` under the tag test's tolerances (fill ±1 per channel; text ±3; geometry exact): header height, row pitch, divider row and colour, the three fills, the bar's width and colour. The cell contents are plain text and ASCII-safe shapes (the glyph and sign cells are WHL-018's), so the comparison covers geometry and fills, not glyph pixels.
- [ ] **Step 2: Add the RTL case** (criterion 2): the bar's pixel run in `01-zodiac-wheel_desktop_he_dark.png` is on the right edge of the Sun row, and the same render in RTL puts it on the right; in LTR on the left (`..._en_dark.png`). Both runs are 3 px wide with the `accent` colour at the cell's vertical centre.
- [ ] **Step 3: Add the compact case:** the mobile wheel PNG is 780 px wide, a **2x** capture (a 44 px row is about 88 px, the 10 px padding 20 px); compare at that factor the compact positions rows (inline padding 10, cell text 13 `small`) against `ZodiannTableDensity.compact`: padding, row height, divider. In compact the **header stays `label` (12)**: the kit's override sets only the body's 13. The kit's compact breakpoint is `max-width: 1100px`, inclusive, while `ZodiannBreakpoint` treats 1100 as desktop; the table does not read the breakpoint (D3), and a note on WHL-024 records the difference.
- [ ] **Step 4: Run** `cd packages/shared_ui; fvm flutter test test/widgets/table_sheet_test.dart`; if it fails for a geometry reason, fix the implementation, never the tolerance; if the reference and the kit disagree, record it (the NAV-002 / UI-009 precedent: the kit wins over MASTER's prose; MASTER is not edited).
- [ ] **Step 5: Commit** `test(ZOD-UI-010): match the sheet's table rows in both themes`.

### Task 6: Panel integration, export, verification, review, documentation

**Files:** create `test/widgets/table_panel_test.dart`; modify `shared_ui.dart`; documentation per "File structure".

- [ ] **Step 1: Write and run** `cd packages/shared_ui; fvm flutter test test/widgets/table_panel_test.dart`: `a table in an antiAlias panel keeps its rounded corner`: a `ZodiannPanel(clipBehavior: Clip.antiAlias, bodyPadding: EdgeInsets.zero)` around an eager `ZodiannTable` whose last row is selected, on a scaffold of a known colour. Sample the pixel diagonally inside the square corner but outside the arc, at about `(1, h - 2)` of the panel: with `Clip.antiAlias` it equals the page backdrop; with the default `Clip.none` it equals `accent-soft` blended (documents D4's reason). A pixel well inside the row is `accent-soft` in both cases.
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

- **Flutter 3.50 semantics roles** are strict (`semantics.dart:350-388`): hence D7, roles only inside `ZodiannTable`. A lazy list has no table semantics (WHL-021 owns an alternative). Task 4's tree tests are the early check.
- **A table in a zero-padding panel** (`bodyPadding: EdgeInsets.zero`) is the intended use and is covered in Task 6.
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

### Round 1 (comprehensive) - verdict: approve after corrections

| ID | Severity | Finding | Done |
|---|---|---|---|
| C1 | Critical | Table roles cannot hold standalone rows or a pinned header (`semantics.dart:350-388`) | Applied: D7 rewritten, roles only inside `ZodiannTable`; Task 4 tests split in two; Risks updated |
| I1 | Important | `isLast`, columns and density mechanism undefined for already-built rows | Applied: private `_TableScope` and `_LastRow`, nullable row parameters, asserts, three tests |
| I2 | Important | A cell wider than its column and `nowrap` undecided | Applied: D6 overflow decision (clipped slots, header ellipsis, unbounded-width assert), two tests |
| I3 | Important | Commands for widget tests and analyze missing | Applied: explicit commands and expected failures in Tasks 1 to 6 |
| I4 | Important | Task 1 token test unrunnable as worded; `package:image` unavailable; no Measured facts section | Applied: the kit-parsing convention of `dimensions_test.dart`, a throwaway `flutter_test` measurement, a Measured facts section |
| I5 | Important | Focus ring via a non-reactive `highlightMode` read | Applied: `FocusableActionDetector`, `ZodiannStates.focusRingWidth`, inset ring |
| I6 | Important | Panel clip test pixel would not discriminate | Applied: sample at about `(1, h - 2)`, backdrop versus `accent-soft` |
| I7 | Important | Mobile PNG is 2x; header stays 12 in compact; kit breakpoint is `<= 1100` | Applied in Task 5 Step 3 (and a WHL-024 note) |
| M1 to M4 | Minor | Zero-padding panel case, Hebrew + scale + selected test, `isLast` height, bar versus divider wording, hover on touch | Applied (Risks, Task 3, Task 1 Step 4, D2) |

Needs user decision: none new; O1 to O5 stand. To tell the owner: C1 (a lazy list gets no table semantics; WHL-021 owns an alternative) and I2 (the overflow behaviour is now decided).

### Round 2 (focused on the revision, `fb1407f..3f1d323`) - verdict: approve after corrections

| ID | Severity | Finding | Done |
|---|---|---|---|
| I8 | Important | `FocusableActionDetector`'s focus semantics could become a roleless node between table and row | Applied: wrapper order (row `Semantics` outermost, detector inside) or `includeFocusSemantics: false`; the roles test includes a tappable row and checks the table's direct children |
| I9 | Important | D6 overstated: a clamped slot cannot stop a non-shrinking `Row` overflowing; the wide-`SizedBox` test passed trivially | Applied: D6 and Review Focus 6 reworded; the test uses a `SizedBox(500)` and a `Row` with `Flexible` text, plus a contract test that a fixed-width `Row` does report an overflow |
| M5 | Minor | D5 still named `Focus` / `MouseRegion` | Applied |
| M6 | Minor | Header ownership under the scope unstated | Applied (header gets explicit `columns` and `density`; reads the scope only for `inTable`) |
| M7 | Minor | Round 2 record | This table |

Open items after two rounds: none from the reviewer. Not confirmed by the reviewer: `ZodiannRadius.lg` is 12 (read in this session at `zodiann_dimensions.dart:59`), so the `(1, h - 2)` clip pixel is valid. Needs user decision: none new; O1 to O5 stand.
