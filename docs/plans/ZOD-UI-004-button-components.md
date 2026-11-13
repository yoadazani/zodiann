# ZOD-UI-004 Button Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build one `ZodiannButton` widget in `shared_ui`. It has five variants (primary, secondary, accent outline, quiet, danger, with danger's solid form), two sizes (40 / 32), and five states (default, hover, keyboard focus, pressed, disabled). It must match `components/components_{dark,light}.png` pixel for pixel, have a visible keyboard focus ring and a 44 hit area, and do nothing when disabled.

**Architecture:**
- **State constants** live in the token directory:
  - a new `tokens/zodiann_states.dart` holds the brightness factors, pressed offset, disabled opacity, focus-ring geometry, danger-border opacity and the solid-danger ink;
  - `ZodiannSize.minTouchTarget = 44` joins `zodiann_dimensions.dart`.
- **Colours:** `ZodiannButtonColors.resolve(surfaces, variant)` maps a variant to its fill, border and label colours, from `ZodiannSurfaces` only.
- **The widget** is a `StatefulWidget` built on `FocusableActionDetector`, not Material's `ButtonStyleButton`, because the design's states are CSS filters on the whole button layer. The layers, outermost first:
  - `Semantics`;
  - `FocusableActionDetector` (focus, hover, `ActivateIntent`);
  - a `GestureDetector` that fills the 44 hit box;
  - `Opacity` (disabled);
  - `Transform.translate` (pressed);
  - a `CustomPaint` foreground focus ring, painted outside the box without affecting layout;
  - `ColorFiltered` brightness (hover / pressed);
  - the 40 / 32 decorated box.
- **Criterion 1:** a reference test renders every cell of the sheet's Buttons board. It drives each state with real input (mouse hover, held press, Tab key), and measures each render with the same feature extractor it runs on the PNG.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), material_ui 1.11.0, flutter_test with `dart:ui` image decoding (as in UI-001/UI-003), bundled IBM Plex fonts (`test/support/load_bundled_fonts.dart`). No new dependencies.

**Spec:** `assets/zodiann-specification.md` NFR-X5 (WCAG AA). Design: `design-reference/zodiann/MASTER.md` §10 "Buttons", §4 (sizes), §14 (touch targets ≥ 44, keyboard focus always visible), `_source/kit.css:186–203`, `_source/components.html:50–55, 87–101`. Task: `docs/development/shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md`.

## Facts established while planning (2026-11-13)

- **Product-owner decisions (2026-11-13):**
  - **D1 icons:** the 33-icon set (ZOD-FND-009) isn't built yet. Buttons take an optional leading `Widget? icon`, laid out in a 16 × 16 slot with an 8 px gap. Tests use a transparent 16 × 16 placeholder. FND-009 supplies the real icons later.
  - **D2 solid danger ink:** white text on `danger`, as designed. In dark that's 3.37:1 (fails AA for 14 px text); in light it's 4.53:1. This is recorded as a ZOD-NFR-009 handoff, as UI-001 did for `text-3`.
  - **D3 touch target:** the button is drawn at 40 / 32, but its layout height is `max(drawn, 44)`, with transparent margins centred above and below that also take taps. Screens place buttons 8 apart (layout) to get the sheet's 12 px visual gap, which meets MASTER §14's "at least 8 between targets".
- **The sheet's states are CSS filters on the button element** (`components.html:52–55`), not kit.css's `:hover` rules:
  - hover is `filter: brightness(1.12)`;
  - focus is `.focus`, an outline of 2 px `focus` at offset 2;
  - pressed is `.pressed`, `translateY(1px)` plus `brightness(.94)`;
  - disabled is `opacity: .42`.
  
  This agrees with MASTER ("+12 %", "darkens 6 %"). kit.css's `.btn:hover { surface-3 }` / `accent-strong` differ, and **MASTER plus the sheet win**. The filter applies to the button layer before it is composited, so a translucent border clamps at white.
  - Verified: dark `accent-line` border `#4A4A4C` is unchanged on hover.
  - Verified: dark danger border `#762F34` → `#7C3439` on hover.
  - In Flutter, `ColorFiltered(ColorFilter.matrix(diag(k, k, k, 1)))` over the button's own layer has the same semantics. The focus ring sits outside the filter.
- **Variant colours** (kit.css `.btn*`; the sheet's pixels agree):

  | Variant | Fill | Border (1 px, inside) | Label | Weight |
  |---|---|---|---|---|
  | primary | `accent` | `accent` | `onAccent` | 600 |
  | secondary | `surface2` | `line` | `text` | 500 |
  | accentOutline | transparent | `accentLine` | `accentStrong` | 500 |
  | quiet | transparent | transparent | `text2` | 500 |
  | danger | transparent | `danger` at α 0.45 (`color-mix 45 %`) | `danger` | 500 |
  | dangerSolid | `danger` | `danger` | `#FFFFFF` (D2) | 500 |
- **Geometry:**
  - **Sizes:** regular is 40 high, padding-inline 16, font 14 (body) at 500, so primary is 14 / 600. Small is 32 high, padding-inline 12, font 13 (small) at 500, so small primary is 13 / 600.
  - **Shared:** radius 8 (`ZodiannRadius.control`), gap 8 between the icon slot and the label, and the icon slot is 16 (`ZodiannSize.iconSmall`) in both sizes. The width is the content width.
  - **Focus ring:** a 2 px ring at a 2 px gap outside the box. Its outer corner radius is about 12 (Chrome draws the outline radius as 8 + offset), so tests sample straight edges only.
- **Sheet coordinates** (pixel scans, both PNGs 1440 wide at DPR 1; the board is `surface`):
  - **Column x (the drawn box's left edge):** default 221, hover 455, focus 689 (ring at 685–686, gap 687–688), pressed 923, disabled 1157.
  - **Row tops (y):** each row is 40 high; pressed is drawn 1 px lower.

    | Theme | primary | secondary | accentOutline | quiet | danger |
    |---|---|---|---|---|---|
    | Dark | 1709 | 1761 | 1813 | 1865 | 1917 |
    | Light | 1692 | 1744 | 1796 | 1848 | 1900 |
  - **Box widths (both themes):** primary "Export to Excel" with icon is 156, secondary "Save" with icon is 89, accentOutline "Show up to today" with icon is 169, quiet "Cancel" with no icon is 78 (measured inside its focus ring: 685 + 4 to 770 − 4), danger "Delete" with icon is 100.
  - **Small row:**
    - dark y 1989–2020, light y 1972–2003 (32 high);
    - "Export" small secondary with icon at x 614–702 (89 wide);
    - "Small primary" with no icon at x 723–833 (111 wide).
  - **Solid danger:** `screens/04-settings_delete-dialog_desktop_en_dark.png`, "Delete all data", fill `#F2555A`, box x 779–905, y 491–530 (127 × 40), white label.
- **Measured pixel values** (the default column; other states follow the filter maths, to within ±1 per channel):

  | Cell | Dark fill / border | Light fill / border |
  |---|---|---|
  | primary | `#F4F5F7` / same | `#0B0C0E` / same |
  | secondary | `#18181C` / `#2A2A30` | `#F4F5F7` / `#D9DCE1` |
  | accentOutline | board / `#4A4A4C` | board / `#C0C0C1` |
  | danger | board / `#762F34` | board / `#EFA4AB` |

  Check rows:
  - dark primary: hover `#FFFFFF`, pressed `#E5E6E8`, disabled `#707174`;
  - dark secondary: hover fill `#1B1B1F`, border `#2F2F36`;
  - light secondary: pressed `#E5E6E8`, border `#CCCFD3`.
- **The label text colour is checked through the widget tree** (`DefaultTextStyle` / `Text` style). In the pixels it is the label region's extreme pixel, within ±3 per channel, because of antialiasing.
- **Contrast (NFR-X5):** all default labels pass AA, except dark solid danger at 3.37:1 (D2, handed off).
  - Danger on `surface`: 5.59 (dark), 4.53 (light).
  - Quiet `text2`: 7.55 / 8.11.
  - Disabled controls are exempt (WCAG 1.4.3).
- **Out of scope:** icon-only buttons on the sheet's lower row:
  - the hamburger is NAV-001 (`icon-btn`, 46);
  - back/forward is WHL-016 (`icon-btn boxed`);
  - play/pause is WHL-017 (`.play`, 48).

## Global Constraints

- Colours come only from `ZodiannSurfaces` (ARCH-7). Colour and numeric layout literals appear only in `packages/shared_ui/lib/src/theme/tokens/`, which both guards enforce.
- Material types come from `package:material_ui/material_ui.dart`. `package:flutter/rendering.dart` and `package:flutter/services.dart` may be imported for `RenderProxyBox` and `LogicalKeyboardKey`, as test files already do. No new dependencies.
- Labels are sentence case and passed in by callers. The widget never transforms case.
- **At most one primary per region** is a usage convention, not a runtime check. It goes in `ZodiannButtonVariant.primary`'s doc comment and in PROGRESS's Architecture Conventions.
- Before every commit, `cmd //c "fvm dart run melos run lint && fvm dart run melos run test"` exits 0.
- **Toolchain:**
  - run `export PATH="$PATH:$LOCALAPPDATA/Pub/Cache/bin"` first;
  - use `cmd //c "…"`;
  - never stage `.idea/`, `.qodo/` or `.fvmrc`.

## Out of scope

- Icon-only buttons (NAV-001, WHL-016, WHL-017) and the real icon SVGs (FND-009).
- The dialog layout around the solid danger button (UI-013).
- Resolving the dark solid-danger contrast (NFR-009, D2).

## Review Focus

1. **A long label or a Hebrew label in a narrow slot** must give one line with an ellipsis and no overflow error. Covered by Task 3's `long label ellipsizes` test, at 120 px width, in both directions.
2. **System text scaling (200 %)** must grow the button rather than clip the label: 40 is a minimum, not a fixed height. Covered by Task 3's `text scale 2.0 grows the button` test.
3. **Disabling mid-press** (`onPressed` becomes null while the pointer is down) must leave no pressed offset, filter or callback. Covered by Task 3's `disabling mid-press clears the pressed state` test.
4. **Keyboard use:**
   - Tab reaches enabled buttons and skips disabled ones.
   - Enter and Space activate the focused button.
   - The ring shows for keyboard focus only, not after a tap.
   
   Covered by Task 3's keyboard tests.
5. **A tap in the invisible hit margin** (2 px above a regular button, 6 px above a small one) must activate the button. Hit testing must go through ordinary parents (`Row`, `Padding`), because the margin is real layout, not a hit-test trick. Covered by Task 3's `hit margin taps activate` test.

---

### Task 1: State constants and variant colours

**Files:**
- Create: `packages/shared_ui/lib/src/theme/tokens/zodiann_states.dart` (export it).
- Modify: `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart`. Add `ZodiannSize.minTouchTarget = 44.0` with the doc line "Minimum touch target (MASTER §14)".
- Create: `packages/shared_ui/lib/src/widgets/zodiann_button_colors.dart`. This adds a `src/widgets/` directory; export the file.
- Test: `packages/shared_ui/test/widgets/button_colors_test.dart`. Also extend `test/theme/dimensions_test.dart` with `minTouchTarget == 44`.

**Interfaces:**
- Produces:
  ```dart
  abstract final class ZodiannStates {
    static const double hoverBrightness = 1.12, pressedBrightness = 0.94, pressedOffset = 1.0,
        disabledOpacity = 0.42, focusRingWidth = 2.0, focusRingGap = 2.0, dangerBorderOpacity = 0.45;
    static const Color onDangerSolid = Color(0xFFFFFFFF); // kit .btn.danger.solid; D2 contrast note in the doc comment
  }
  enum ZodiannButtonVariant { primary, secondary, accentOutline, quiet, danger, dangerSolid }
  @immutable final class ZodiannButtonColors {
    const ZodiannButtonColors({required Color fill, required Color border, required Color label});
    final Color fill, border, label;
    static ZodiannButtonColors resolve(ZodiannSurfaces s, ZodiannButtonVariant v);
    // == / hashCode
  }
  ```
  Put `ZodiannButtonVariant` in `zodiann_button_colors.dart`. Its doc comments carry MASTER's uses:
  - **primary:** at most one per region;
  - **secondary:** the default;
  - **accentOutline:** time and anchor shortcuts;
  - **quiet:** Cancel;
  - **danger:** destructive;
  - **dangerSolid:** inside a confirmation dialog only.

  Transparent fills and borders use `ZodiannStates.transparent` (`static const Color transparent = Color(0x00000000)`). The colour guard flags `Colors.transparent` outside `tokens/`. `resolve` uses the `ZodiannStates` constants, never inline numbers. For example, the danger border is `s.danger.withValues(alpha: ZodiannStates.dangerBorderOpacity)`.

- [ ] **Step 1: Write the failing tests.** In `button_colors_test.dart`, for both `graphiteTokens.surfaces` and `porcelainTokens.surfaces`, assert the Facts table for all six variants, row by row, with the expected values written as token references. For example, danger's border is `s.danger.withValues(alpha: 0.45)`, and dangerSolid's label is `const Color(0xFFFFFFFF)`. Also assert:
  - `ZodiannStates`' values against MASTER §10 / kit literals: 1.12, 0.94, 1, 0.42, 2, 2, 0.45;
  - a contrast test that every enabled default label meets ≥ 4.5:1 against its fill, or against `surface` when the fill is transparent, in both themes. **The one exception is dark `dangerSolid`, asserted to be below 4.5 and above 3.0.** The test name records that the shortfall is the D2 hand-off to NFR-009, so the test fails if a later token change silently fixes or worsens it. Reuse the contrast helper from `test/theme/contrast_test.dart`, or copy its 10-line WCAG function.
- [ ] **Step 2: Run and see it fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/widgets/button_colors_test.dart test/theme/dimensions_test.dart"`. Expected: compile failure.
- [ ] **Step 3: Implement** the constants, the enum and `resolve` (a `switch` expression).
- [ ] **Step 4: Run and see it pass.** Same command.
- [ ] **Step 5: Mutation proofs.**
  - **C1:** secondary border `lineSoft`. Fails.
  - **C2:** danger border opacity 0.5. Fails.
  - **C3:** `disabledOpacity = 0.45` (the input's value). Fails.
- [ ] **Step 6: Gates, then commit.** Commit as `feat(ZOD-UI-004): button state constants and variant colours`.

### Task 2: `ZodiannButton` widget

**Files:**
- Create: `packages/shared_ui/lib/src/widgets/zodiann_button.dart` (export it).
- Test: `packages/shared_ui/test/widgets/button_test.dart` (structure and layout; behaviour is Task 3).

**Interfaces:**
- Consumes: Task 1, `ZodiannTextStyles` (`body`, `small`), `ZodiannSize`, `ZodiannSpace`, `ZodiannRadius`.
- Produces:
  ```dart
  enum ZodiannButtonSize { regular, small }
  class ZodiannButton extends StatefulWidget {
    const ZodiannButton({super.key, required String label, required VoidCallback? onPressed,
      ZodiannButtonVariant variant = ZodiannButtonVariant.secondary, ZodiannButtonSize size = ZodiannButtonSize.regular,
      Widget? icon, FocusNode? focusNode, bool autofocus = false});
    // onPressed == null ⇒ disabled.
  }
  ```
- **Build tree, outermost first:**
  1. `Semantics(button: true, enabled: onPressed != null, label: label, excludeSemantics: true)`;
  2. `FocusableActionDetector(enabled: onPressed != null, focusNode, autofocus, mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden, onShowHoverHighlight, onShowFocusHighlight, actions: {ActivateIntent: CallbackAction(onInvoke: → onPressed)})`;
  3. `GestureDetector(behavior: HitTestBehavior.opaque, onTapDown / onTapUp / onTapCancel → _pressed, onTap → onPressed)`. Pass null callbacks when disabled.
  4. `ConstrainedBox(minHeight: ZodiannSize.minTouchTarget)` + `Center` (D3). The hit box is the full 44 layout, and the visual box is centred in it.
  5. `Opacity(disabled ? 0.42 : 1)`;
  6. `Transform.translate(Offset(0, pressed ? 1 : 0))`;
  7. `CustomPaint(foregroundPainter: _FocusRingPainter(show: _focusHighlight, color: s.focus))`. It strokes an `RRect` inflated by gap + width / 2 (3 px), stroke width 2, radius 8 + 3, outside the child's bounds;
  8. `ColorFiltered(_brightness(pressed ? 0.94 : hovered ? 1.12 : 1))`, or no filter at 1;
  9. `ConstrainedBox(minHeight: 40 / 32)`;
  10. `DecoratedBox(fill, Border.all(border), ZodiannRadius.control)`;
  11. `Padding(horizontal: 16 / 12)`;
  12. `Row(mainAxisSize: min, spacing: ZodiannSpace.s2, [if icon: SizedBox.square(dimension: ZodiannSize.iconSmall, child: icon), Flexible(Text(label, maxLines: 1, overflow: ellipsis, softWrap: false, style))])`.
  
  The label style is `body` / `small` with `color: colors.label` and `fontWeight` 600 for primary, else 500. `IconTheme(color: colors.label, size: 16)` wraps the icon.
- `_brightness(k)` is `ColorFilter.matrix([k,0,0,0,0, 0,k,0,0,0, 0,0,k,0,0, 0,0,0,1,0])`. These are matrix literals, not layout literals, so the guard doesn't apply.
- Hover / pressed / focus state is held in `_hovered`, `_pressed` and `_focusHighlight`. `didUpdateWidget` clears `_pressed` and `_hovered` when `onPressed` becomes null.

- [ ] **Step 1: Write the failing tests** (`button_test.dart`, under `ZodiannTheme.graphite`, `setUpAll(loadBundledFonts)`):
  - **`regular is drawn 40 high in a 44 layout; small 32 in 44`:**
    - `tester.getSize(find.byType(ZodiannButton)).height == 44` for both sizes;
    - the `DecoratedBox` size heights are 40 and 32.
  - **`padding, gap and icon slot`:**
    - the label's left edge minus the box's left edge is 16 + 16 + 8 with an icon, 16 without, and 12 for small;
    - the icon slot is 16 × 16.
  - **`label style per variant`:** the `Text` style's colour equals `ZodiannButtonColors.resolve(...).label`, and its weight is 600 for primary and 500 otherwise. Its size is 14 for regular and 13 for small, and its family is the theme's.
  - **`decoration per variant`:** the `BoxDecoration`'s colour and border colour equal `resolve(...)`, with border width 1 and radius `ZodiannRadius.control`.
  - **`RTL puts the icon on the start side`:** under `Directionality(rtl)`, the icon slot's x is greater than the label's x.
- [ ] **Step 2: Run and see it fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/widgets/button_test.dart"`. Expected: compile failure.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run and see it pass.**
- [ ] **Step 5: Mutation proofs.**
  - **B1:** primary weight 500. Fails the label-style test.
  - **B2:** small padding 16. Fails the padding test.
  - **B3:** drop the 44 `ConstrainedBox`. Fails the layout test.
- [ ] **Step 6: Gates, then commit.** Commit as `feat(ZOD-UI-004): ZodiannButton variants, sizes and layout`.

### Task 3: States and behaviour (criteria 2 and 3)

**Files:**
- Test: `packages/shared_ui/test/widgets/button_behavior_test.dart`.
- Modify: `zodiann_button.dart`, only as the tests require.

**Interfaces:**
- Consumes: Task 2's `ZodiannButton`.

- [ ] **Step 1: Write the failing tests.** These run with `tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.automatic`; traditional keyboard mode comes from sending a key event.
  - **`tap calls onPressed once`.**
  - **`hit margin taps activate`:** `tester.tapAt(topCentre + Offset(0, 1))` on a regular button inside `Row(children: [button])` calls onPressed, and the same works at offset 3 on a small one. A tap 1 px outside the 44 box doesn't.
  - **`hover lightens`:** with a mouse `TestGesture` moved onto the button, the `ColorFiltered` exists with matrix diagonal 1.12. After moving away, no `ColorFiltered` is in the subtree.
  - **`press moves 1 px down and darkens`:** while the gesture is held (`startGesture`, no `up`), the `Transform`'s translation is (0, 1) and the filter diagonal is 0.94. After `up` both reset and onPressed fired once.
  - **`keyboard focus shows the focus ring; a tap does not`:**
    - `sendKeyEvent(LogicalKeyboardKey.tab)` focuses the button and `_FocusRingPainter.show` is true, found via `find.byWidgetPredicate` on `CustomPaint` with a painter of that type. The painter's colour equals `surfaces.focus` in both themes.
    - After a fresh pump, tapping the button gives `show` false.
  - **`Enter and Space activate the focused button`.**
  - **`disabled: 42 % opacity, no feedback, not focusable, no callback`:**
    - `Opacity.opacity == 0.42`;
    - hover and press give no `ColorFiltered` and a zero translation;
    - the tap callback isn't called;
    - Tab skips it: focus lands on an enabled sibling placed after it;
    - semantics `isEnabled` is false and `isButton` is true.
  - **`disabling mid-press clears the pressed state`:** hold a press, rebuild with `onPressed: null`, then release. There's no translation, the opacity is 0.42 and nothing was called.
  - **`long label ellipsizes`:** in a `SizedBox(width: 120)`, a label 60 characters long (and a Hebrew one under RTL) gives no `tester.takeException()`, and the `Text` has `maxLines` 1 and `overflow` ellipsis.
  - **`text scale 2.0 grows the button`:** under `MediaQuery(textScaler: TextScaler.linear(2))` there's no exception, and the `DecoratedBox` height is ≥ the label's painted height + 2.
- [ ] **Step 2: Run and see it fail** wherever Task 2 didn't already implement the behaviour. Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/widgets/button_behavior_test.dart"`. Expected: failures name the missing behaviour. Any test that passes immediately is listed in the commit message and proven by mutants B4–B7.
- [ ] **Step 3: Implement** whatever is missing.
- [ ] **Step 4: Run and see it pass.**
- [ ] **Step 5: Mutation proofs.**
  - **B4:** the ring is shown whenever the button has focus, ignoring the highlight. Fails the tap case.
  - **B5:** the disabled button stays focusable. Fails Tab-skip.
  - **B6:** `didUpdateWidget` doesn't clear `_pressed`. Fails mid-press.
  - **B7:** `GestureDetector` wraps the visual box, not the 44 box. Fails the hit margin.
- [ ] **Step 6: Gates, then commit.** Commit as `feat(ZOD-UI-004): button hover, press, focus ring and disabled behaviour`.

### Task 4: Component-sheet cross-check (criterion 1)

**Files:**
- Create: `packages/shared_ui/test/support/button_features.dart`, a pure-Dart feature extractor over RGBA `ByteData` with width and height.
- Create: `packages/shared_ui/test/widgets/button_sheet_test.dart`.

**Interfaces:**
- Produces (test-only):
  ```dart
  final class ButtonFeatures { final int left, top, width, height; final int fill, border, label; final List<int>? ring; }
  ButtonFeatures measureButton(Rgba img, {required int originX, required int originY, required int spanX, required int board, int? iconSlot});
  ```
- **`measureButton`:**
  - Scan row `originY + 20` (+16 for small) rightward from `originX` to the first non-`board` pixel. That pixel is the box, or the ring when focused.
  - When a ring is detected (the pixel equals `focus` and the next two are `board`), record `ring` = those 4 pixels and set `left` = ring + 4.
  - Find the right edge by scanning leftward from `originX + spanX`.
  - Find `top` and `height` on column `left + 8`, outside the ring.
  - `fill` is at (`left + 4`, mid).
  - `border` is at (`left`, mid).
  - `label` is the pixel with the largest RGB distance from `fill` within the label area. That area starts at x = `left + padding + (iconSlot ?? 0)` and runs to `right − padding`, across rows mid ± 5.

- [ ] **Step 1: Write the failing test.** For each theme (`components_dark.png` / `components_light.png`), decode the PNG and assert its size is 1440 × 5586 / 1440 × 5569. Then, for each of the 25 cells plus the 2 small-row buttons, using the Facts' coordinates (`spanX` 218):
  1. **PNG side:** `measureButton` on the PNG.
  2. **Flutter side:** at DPR 1, pump a `ColoredBox(surface)` 260 × 60 with the button at (8, 8) inside a `RepaintBoundary`. Use the same label, variant, size and a placeholder icon `SizedBox.square(dimension: 16)` where the sheet has an icon. Drive the column's state with real input:
     - hover: a mouse `TestGesture`;
     - focus: Tab;
     - pressed: a held press;
     - disabled: `onPressed: null`.
     
     Render to RGBA inside `runAsync` and measure it the same way.
  3. **Compare:**
     - `width` within ±1 (text rendering);
     - `height` exact;
     - `top − originTop` exact, so pressed is +1;
     - `fill` and `border` within ±1 per channel (filter rounding);
     - `ring` exact;
     - `label` within ±3 per channel.
  
  The dialog's solid danger "Delete all data" is compared the same way against `04-settings_delete-dialog_desktop_en_dark.png` (origin 760, 480, `spanX` 170, board = dialog `surface`).
  
  To show the comparison isn't hollow, also assert that the PNG features equal the Facts' measured literals for the default column.
- [ ] **Step 2: Run and see it fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/widgets/button_sheet_test.dart"`. Expected: compile failure (no extractor).
- [ ] **Step 3: Implement `button_features.dart`, then run and see it pass.** If a width differs by more than 1 px:
  - investigate the label's font, weight, size and letter spacing against kit.css, using `superpowers:systematic-debugging`;
  - never widen the tolerance silently. A tolerance change is a ledgered ruling.
  
  Optionally write the Flutter renders to `ZODIANN_BUTTON_DIR` for visual review against the sheet.
- [ ] **Step 4: Mutation proofs.**
  - **S1:** hover factor 1.10. Fails the hover cells (fill ±1).
  - **S2:** pressed offset 0. Fails the pressed tops.
  - **S3:** a focus-ring gap of 1. Fails the ring.
  - **S4:** accentOutline label `text`. Fails the label colour.
- [ ] **Step 5: Gates, then commit.** Commit as `test(ZOD-UI-004): button states cross-checked against the component sheet`.

### Task 5: Review and close-out

- [ ] **Step 1: Whole-branch code review** (opus) with this plan's Review Focus. Fix Critical and Important findings test-first, and defer minors.
- [ ] **Step 2: Close out the docs.**
  - **UI-004 task file:** Done, all three criteria ticked. Notes:
    - D1, D2 and D3 with dates;
    - the sheet's filter semantics, with MASTER plus the sheet over kit.css's `:hover`;
    - out-of-scope icon-only buttons and their owners;
    - "at most one primary per region" as a convention.
  - **Notes in other task files:**
    - **ZOD-NFR-009:** the dark solid-danger 3.37:1 shortfall (D2).
    - **ZOD-FND-009:** pass real icons through `ZodiannButton.icon`, at 16.
    - **ZOD-UI-013:** use `ZodiannButtonVariant.dangerSolid` for destructive confirmation; actions are 8 apart.
    - **NAV-001, WHL-016, WHL-017:** icon buttons follow the same state model (`ZodiannStates`, brightness filters, focus ring).
  - **PROGRESS:**
    - Architecture Conventions:
      - buttons are `ZodiannButton`; at most one primary per region;
      - interactive states use `ZodiannStates`;
      - hit targets are ≥ 44, with buttons laid out 8 apart.
    - Technical Decisions: D1, D2, D3, and the filter semantics.
    - Verification, Git State, next task.
  - **TASKS.md:** UI-004 Done.
  - Commit as `docs(ZOD-UI-004): close out button components`, then push, open the PR and record its link.
