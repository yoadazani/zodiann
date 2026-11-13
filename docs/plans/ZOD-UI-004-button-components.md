# ZOD-UI-004 Button Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build one `ZodiannButton` widget in `shared_ui`. It has five variants (primary, secondary, accent outline, quiet, danger, with danger's solid form), two sizes (40 / 32), and five states (default, hover, keyboard focus, pressed, disabled). It must match `components/components_{dark,light}.png` pixel for pixel, have a visible keyboard focus ring and a 44 hit area, and do nothing when disabled.

**Architecture:**
- **State constants** live in the token directory:
  - a new `tokens/zodiann_states.dart` holds the brightness factors, pressed offset, disabled opacity, focus-ring geometry, danger-border opacity and the solid-danger ink;
  - `ZodiannSize.minTouchTarget = 44` joins `zodiann_dimensions.dart`.
- **Colours:** `ZodiannButtonColors.resolve(surfaces, variant)` maps a variant to its fill, border and label colours, from `ZodiannSurfaces` only.
- **The widget** is a `StatefulWidget` built on `FocusableActionDetector`, not Material's `ButtonStyleButton`, because the design's states are CSS filters on the whole button layer. The layers, outermost first:
  - `Semantics`, with its own tap action;
  - `FocusableActionDetector` (focus and its keyboard-only highlight, `ActivateIntent`);
  - `MouseRegion` (hover in any highlight mode);
  - a `GestureDetector` that fills the 44 hit box;
  - `Opacity` (disabled);
  - `Transform.translate` (pressed);
  - a `CustomPaint` foreground focus ring, painted outside the box without affecting layout;
  - an always-present `ColorFiltered` brightness, with hover animated over 150 ms;
  - the 40 / 32 border-box `Container`.
- **Criterion 1:** a reference test renders every cell of the sheet's Buttons board. It drives each state with real input (mouse hover, held press, Tab key), and measures each render with the same feature extractor it runs on the PNG.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (FVM), material_ui 1.11.0, flutter_test with `dart:ui` image decoding (as in UI-001/UI-003), bundled IBM Plex fonts (`test/support/load_bundled_fonts.dart`). No new dependencies.

**Spec:** `assets/zodiann-specification.md` NFR-X5 (WCAG AA), NFR-X6 (reduced motion). Design: `design-reference/zodiann/MASTER.md` §10 "Buttons", §4 (sizes), §12 (hover 150 ms, reduced motion), §14 (touch targets ≥ 44, keyboard focus always visible), `_source/kit.css:188–204` (`.focus` / `.pressed` at 203–204), `_source/components.html:50–55, 87–101` (hover filter at line 52). Task: `docs/development/shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md`.

## Facts established while planning (2026-11-13)

- **Product-owner decisions (2026-11-13):**
  - **D1 icons:** the 33-icon set (ZOD-FND-009) isn't built yet. Buttons take an optional leading `Widget? icon`, laid out in a 16 × 16 slot with an 8 px gap. Tests use a transparent 16 × 16 placeholder. FND-009 supplies the real icons later.
  - **D2 solid danger ink:** white text on `danger`, as designed. In dark that's 3.37:1 (fails AA for 14 px text); in light it's 4.53:1. This is recorded as a ZOD-NFR-009 handoff, as UI-001 did for `text-3`.
  - **D3 touch target:** the button is drawn at 40 / 32, but its layout (and hit) box is at least 44 × 44: `max(drawn height, 44)` high and `max(drawn width, 44)` wide. The transparent margins around the centred drawn box also take taps. The drawn box's dimensions never change. Labels of about two narrow characters or fewer are narrower than 44 when drawn, measured with the bundled Plex Sans (regular '1' = 42.4, small 'OK' = 43.8, small '1' = 33.8). Their drawn box is centred in a 44-wide target. Vertically, screens place buttons 8 apart (layout) to get the sheet's 12 px visual gap (2 + 8 + 2), which meets MASTER §14's "at least 8 between targets". Horizontally, for buttons at least 44 wide when drawn, the visual gap equals the layout gap: the dialog's Cancel→Delete gap is 8. A narrower button adds (44 − drawn width) / 2 of transparent margin on each side.
  - **U1 hover animation:** MASTER §12's "Hover: 150 ms" is implemented. The brightness factor eases 1 ↔ 1.12 over 150 ms (`Curves.ease`, CSS's default timing). It's instant under reduced motion (`MediaQuery.disableAnimationsOf`, NFR-X6, MASTER §12). Press is instant: §12 times only hover.
  - **U2 dense containers:** D3 applies everywhere. Containers sized by their content grow by 6 (small) / 2 (regular) px per side compared with the mockups, unless their padding absorbs the margin. Example: the crossings panel head goes from 56 to 68 (`wheel.html:55, 154`). This is handed to ZOD-WHL-021, ZOD-SET-005 and ZOD-DAT-001.
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
  - **Border-box:** the inline content inset is the 1 px border plus the padding, so 17 (regular) / 13 (small). Verified: quiet "Cancel" is 78 = 2 + 32 + 44 wide, and its ink sits 17 in from each side.
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
  - **Solid danger:** `screens/04-settings_delete-dialog_desktop_en_dark.png`, "Delete all data", fill `#F2555A`, white label.
    - **Box:** x 779–905, which includes antialiased edge columns (`#432024`), so it is about 126.x px wide at a fractional x. Rows 491–530 are crisp.
    - **Neighbours:** Cancel's right border is at 768–770, and the dialog edge is at x 930.
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
5. **A tap in the invisible hit margin** (2 px above a regular button, 6 px above a small one, and 1 px inside the left / right edge of a narrow button's target) must activate the button. Hit testing must go through ordinary parents (`Row`, `Padding`), because the margin is real layout, not a hit-test trick. Covered by Task 3's `hit margin taps activate` test.
6. **Screen-reader activation:** TalkBack / VoiceOver must announce a button with its label, enabled state and focusability, and double-tap must activate it. A disabled button has no tap action. Covered by Task 3's semantics tests.
7. **A mouse on a touch device** (a tablet with a mouse after a touch) still shows hover. Covered by Task 3's `hover shows in touch highlight mode`.
8. **Focus-ring clipping contract:** the ring extends 4 px beyond the drawn box. Beyond the layout, that's 2 px vertically for regular, none vertically for small, and horizontally 4 − (44 − drawn width) / 2 px when positive. `ZodiannButton` paints the complete ring whenever no ancestor clips it. It cannot override an ancestor's clip, and doesn't try to.
   - **Consumer contract:** wherever the ring can appear, consuming screens and components keep at least 4 px of clear, unclipped space around the drawn button.
   - **When a layout must clip** (a scroll view, a rounded panel), it adjusts its own padding or insets so that keyboard focus stays fully visible (MASTER §14).
   - **Where it's recorded:** the widget's doc comment, the UI-013 / UI-014 hand-offs and PROGRESS's Architecture Conventions.
   - **Covered by** Task 3's `focus ring is painted completely when unclipped` test.

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
    static const Duration hoverDuration = Duration(milliseconds: 150); // MASTER §12
    static const Color transparent = Color(0x00000000);
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
  - `ZodiannStates`' values against MASTER §10 / §12 / kit literals: 1.12, 0.94, 1, 0.42, 2, 2, 0.45, 150 ms;
  - a contrast test that every enabled default label meets ≥ 4.5:1 against its fill, or against `surface` when the fill is transparent, in both themes. **The one exception is dark `dangerSolid`, asserted to be below 4.5 and above 3.0.** The test name records that the shortfall is the D2 hand-off to NFR-009, so the test fails if a later token change silently fixes or worsens it. Copy the 10-line WCAG function from `test/theme/contrast_test.dart`; its `_contrast` is private.
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
- **Build tree, outermost first** (`enabled = onPressed != null`):
  1. `Semantics(container: true, button: true, enabled: enabled, label: label, onTap: enabled ? onPressed : null)`, with no `excludeSemantics` and no `focusable` / `focused`. The `Focus` inside `FocusableActionDetector` supplies `focusable`, `focused` and the focus action (non-iOS), and they merge into this node;
  2. `FocusableActionDetector(enabled: enabled, focusNode, autofocus, onShowFocusHighlight → _focusHighlight, mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden, actions: {ActivateIntent: CallbackAction(onInvoke: → onPressed)})`;
  3. `MouseRegion(onEnter / onExit → _hovered)`, which always tracks. The effective hover is `enabled && _hovered`, so re-enabling under a resting mouse shows hover. Hover isn't taken from `onShowHoverHighlight`, which is suppressed in touch highlight mode;
  4. `GestureDetector(behavior: HitTestBehavior.opaque, excludeFromSemantics: true, onTapDown / onTapUp / onTapCancel → _pressed, onTap → onPressed)`. Pass null callbacks when disabled;
  5. `ConstrainedBox(constraints: BoxConstraints(minWidth: ZodiannSize.minTouchTarget, minHeight: ZodiannSize.minTouchTarget), child: Align(widthFactor: 1, heightFactor: 1, child: …))` (D3). The layout is exactly max(drawn width, 44) × max(drawn height, 44), with the drawn box centred and its own size unchanged. A plain `Center` would fill bounded parents;
  6. `ExcludeSemantics(child: Opacity(opacity: enabled ? 1.0 : ZodiannStates.disabledOpacity, …))`, so the `Text` doesn't add the label a second time;
  7. `Transform.translate(offset: Offset(0, _pressed ? ZodiannStates.pressedOffset : 0))`;
  8. `CustomPaint(foregroundPainter: ZodiannFocusRingPainter(show: _focusHighlight, color: s.focus))`. `ZodiannFocusRingPainter` is a public `@visibleForTesting final class … extends CustomPainter` in `zodiann_button.dart` (`const ZodiannFocusRingPainter({required this.show, required this.color})`), with `shouldRepaint` comparing both fields. `shared_ui.dart` exports the file with `hide ZodiannFocusRingPainter`. Tests import `package:shared_ui/src/widgets/zodiann_button.dart`. Compute `final outset = ZodiannStates.focusRingGap + ZodiannStates.focusRingWidth / 2;` first. Then stroke `RRect.fromRectAndRadius(bounds.inflate(outset), Radius.circular(ZodiannRadius.md + outset))` at width `ZodiannStates.focusRingWidth`, outside the child's bounds;
  9. `TweenAnimationBuilder<double>(tween: Tween(end: enabled && _hovered ? ZodiannStates.hoverBrightness : 1.0), duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : ZodiannStates.hoverDuration, curve: Curves.ease, builder: (h) → ColorFiltered(colorFilter: _brightness(_pressed ? ZodiannStates.pressedBrightness : h), child: …))`. The `ColorFiltered` is always present, identity at 1, so the subtree's shape never changes. Press is instant;
  10. `Container(constraints: BoxConstraints(minHeight: ZodiannSize.control / controlSmall), decoration: BoxDecoration(color: fill, border: Border.all(color: border), borderRadius: ZodiannRadius.control), padding: EdgeInsetsDirectional.symmetric(horizontal: ZodiannSpace.s4 / s3), child: …)`. `Container` adds `decoration.padding` (the 1 px border) to `padding`, matching CSS border-box, so the content inset is 17 / 13;
  11. `Row(mainAxisSize: MainAxisSize.min, spacing: ZodiannSpace.s2, children: [if icon != null: IconTheme(data: IconThemeData(color: colors.label, size: ZodiannSize.iconSmall), child: SizedBox.square(dimension: ZodiannSize.iconSmall, child: icon)), Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: …))])`.
  
  The label style is `body` / `small` with `color: colors.label` and `fontWeight` `w600` for primary, else `w500`.
- `_brightness(k)` is `ColorFilter.matrix([k,0,0,0,0, 0,k,0,0,0, 0,0,k,0,0, 0,0,0,1,0])`. These are matrix literals, which the guard doesn't scan.
- `didUpdateWidget` clears `_pressed` when `onPressed` becomes null.
- **The doc comment states:**
  - at most one primary per region;
  - the 44 layout (D3);
  - **The focus-ring contract (Review Focus 8):** the button paints the complete ring, 4 px beyond the drawn box, whenever no ancestor clips it, and it cannot override an ancestor's clip. Consumers keep at least 4 px of clear, unclipped space around the button wherever the ring can appear. A layout that must clip adjusts its own padding so keyboard focus stays visible.

- [ ] **Step 1: Write the failing tests.** All widget tests pump `MaterialApp(theme: ZodiannTheme.graphite / porcelain, home: Material(child: Center(child: …)))`. **The Hebrew harness** keeps the `MaterialApp` and adds `builder: (c, w) => Theme(data: withZodiannScript(Theme.of(c), ZodiannScript.hebrew), child: Directionality(textDirection: TextDirection.rtl, child: w!))`. `shared_ui` has no `flutter_localizations`, so `locale: Locale('he')` alone would resolve to en_US / LTR. Tests also assert that `Directionality.of` the button's context is `rtl`. Use `setUpAll(loadBundledFonts)`.
  - **`the target is at least 44 × 44 and the drawn box is unchanged`:** for regular and small, each with the labels 'Save', 'OK' and '1':
    - `tester.getSize(find.byType(ZodiannButton))` is exactly `Size(max(drawnWidth, 44), 44)`, so width ≥ 44 and height == 44;
    - the drawn box (the `Container`'s `DecoratedBox`) is 40 / 32 high, and its width equals 2 × (1 + padding) + the label's width, regardless of the 44 minimum. Compare with `closeTo(…, 0.01)`, using `tester.getSize(find.byType(Text)).width` for the label;
    - the drawn box is centred in the target (equal margins on each side, within 0.5 px);
    - inside `Center(child: SizedBox(height: 300, child: Row(children: [button])))`, for each case the `ZodiannButton` is still 44 high and exactly max(decorated box width, 44) wide.
    
    **Which cases exercise which path:**
    - **Narrower than 44 when drawn,** pinning the `minWidth` path: regular '1' (42.4), small 'OK' (43.8) and small '1' (33.8 = 13 + 13 + 7.8, tabular figures).
    - **Wider than 44,** pinning "target = drawn width": 'Save' in both sizes and regular 'OK'.
    - **The margin tap is tested on small '1' only.** First assert the precondition `targetRect.left + 1 < drawnRect.left` (the margin is ≈ 5.1). Then `tester.tapAt(Offset(targetRect.left + 1, targetRect.center.dy))` calls `onPressed` once.
  - **`border-box padding, gap and icon slot`:**
    - the label's start edge minus the box's outer start edge is 1 + 16 + 16 + 8 = 41 with an icon, 17 without, and 13 for small without;
    - the icon slot starts at 17 (13 small) and is 16 × 16;
    - the box's outer end edge minus the label's end edge is 17 (13 small).
  - **`label style per variant`:** the `Text` style's colour equals `ZodiannButtonColors.resolve(...).label`, and its weight is `w600` for primary and `w500` otherwise. Its size is 14 for regular and 13 for small, and its family is the theme's.
  - **`decoration per variant`:** the `BoxDecoration`'s colour and border colour equal `resolve(...)`, with border width 1 and radius `ZodiannRadius.control`.
  - **`RTL puts the icon on the start side`:** under the Hebrew harness, the icon slot's x is greater than the label's x, and the start inset is measured from the right: 17.
- [ ] **Step 2: Run and see it fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/widgets/button_test.dart"`. Expected: compile failure.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run and see it pass.**
- [ ] **Step 5: Mutation proofs.**
  - **B1:** primary weight 500. Fails the label-style test.
  - **B2:** small padding 16. Fails the padding test.
  - **B3:** drop the 44 `ConstrainedBox`. Fails the layout test.
  - **B8:** `DecoratedBox` + `Padding` instead of `Container`, so the border isn't included. Fails the padding test (16 ≠ 17).
  - **B9:** a plain `Center` instead of `Align(widthFactor: 1, heightFactor: 1)`. Fails the `Row` in the 300-high box.
  - **B15:** drop `minWidth`. Fails the regular '1', small 'OK' and small '1' target widths.
- [ ] **Step 6: Gates, then commit.** Commit as `feat(ZOD-UI-004): ZodiannButton variants, sizes and layout`.

### Task 3: States and behaviour (criteria 2 and 3)

**Files:**
- Test: `packages/shared_ui/test/widgets/button_behavior_test.dart`, with the same `MaterialApp` harness as Task 2.
- Modify: `zodiann_button.dart`, only as the tests require.

**Interfaces:**
- Consumes: Task 2's `ZodiannButton`. Tests find the filter with `find.descendant(of: find.byType(ZodiannButton), matching: find.byType(ColorFiltered))` and compare `colorFilter` by equality with `ColorFilter.matrix([...])`, because `ColorFilter` has no matrix getter.

- [ ] **Step 1: Write the failing tests.**
  - **`tap calls onPressed once`.**
  - **`hit margin taps activate`:** `tester.tapAt(topCentre + Offset(0, 1))` on a regular button inside `Row(children: [button])` calls onPressed, and the same works at offset 3 on a small one. A tap 1 px outside the 44 box doesn't. For a small '1' inside `Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 10), button, SizedBox(width: 8)])`, a tap at the target's left edge + 1 at mid-height also activates it.
  - **`hover lightens over 150 ms`:**
    - move a mouse `TestGesture` onto the button and `await tester.pump()`. This starts the animation, so the filter is still identity;
    - after `pump(const Duration(milliseconds: 75))` the filter equals neither the identity matrix nor the 1.12 matrix. Parse the diagonal k from `colorFilter.toString()`: it is within 1e-3 of `1 + 0.12 * Curves.ease.transform(0.5)` (≈ 1.0963; linear would give 1.06);
    - after a further `pump(75 ms)` it equals the 1.12 matrix;
    - move away, then `pump()` + `pump(150 ms)`: identity.
  - **`hover is instant under reduced motion`:**
    - set `tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true)` and `addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue)`. This is the real platform → `MediaQuery` path;
    - after hovering, the filter is 1.12 after a single `pump()`.
  - **`hover shows in touch highlight mode`:** `tester.tap` an empty area first, so the highlight mode is touch. Then hover with a mouse `TestGesture`, `pump()` + `pump(150 ms)`: the filter is 1.12.
  - **`press moves 1 px down and darkens`:** while the gesture is held (`startGesture`, no `up`), the `Transform`'s translation is (0, 1) and the filter is the 0.94 matrix after one `pump()` (press is instant). After `up` both reset and onPressed fired once.
  - **`keyboard focus shows the focus ring; a tap does not`:**
    1. Pump `Row(children: [button, ZodiannButton(label: 'Next', onPressed: () {})])`. `sendKeyEvent(LogicalKeyboardKey.tab)` focuses the button. `ZodiannFocusRingPainter.show` is true, found via `find.byWidgetPredicate((w) => w is CustomPaint && w.foregroundPainter is ZodiannFocusRingPainter)`. The painter's colour equals `surfaces.focus` in both themes.
    2. `tester.tap` it: `focusNode.hasFocus` is still true and `show` is false.
    3. Tab moves focus to 'Next', then Shift+Tab returns: `show` is true again.
  - **`focus ring is painted completely when unclipped`:**
    - **Setup:** for regular 'Save', small 'Save' and small '1' (the last is centred inside the 44 target at a fractional x), in both themes:
      - place the button at a whole-pixel origin, `Align(alignment: Alignment.topLeft, child: Padding(padding: EdgeInsets.all(8), child: button))`, inside a `RepaintBoundary` on `surface`;
      - Tab-focus it, then render to RGBA inside `runAsync`.
    - **Edges:** let L, R, T, B be the drawn box's global left / right / top / bottom (from `tester.getRect` of the `DecoratedBox`). Text widths are fractional, so the edges usually are too.
    - **Sampling:** for each side, sample the one pixel that lies wholly inside the ring band and the one that lies wholly inside the gap, whatever the subpixel alignment:
      - at the drawn box's mid-row: left ring x = ceil(L) − 4, left gap x = ceil(L) − 2; right ring x = floor(R) + 3, right gap x = floor(R) + 1;
      - at its mid-column: top ring y = ceil(T) − 4, top gap y = ceil(T) − 2; bottom ring y = floor(B) + 3, bottom gap y = floor(B) + 1.
    - **Expected:** each ring pixel equals `focus` exactly, and each gap pixel equals `surface` exactly. This pins the "complete ring when unclipped" half of the contract; ancestor clipping is the consumer's responsibility (Review Focus 8).
  - **`Enter and Space activate the focused button`.**
  - **`semantics`:**
    - Enabled: `tester.getSemantics(find.byType(ZodiannButton))` `matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: true, isFocusable: true, hasTapAction: true, hasFocusAction: true, label: 'Save')`. The test platform is Android. The label is exactly 'Save', appearing once.
    - `tester.semantics.tap(find.byType(ZodiannButton))` calls onPressed once.
  - **`disabled: 42 % opacity, no feedback, not focusable, no callback`:**
    - `Opacity.opacity == 0.42`;
    - hover and press leave the filter at identity and the translation at zero;
    - the tap callback isn't called;
    - Tab skips it: focus lands on an enabled sibling placed after it;
    - semantics show `isButton` true, `isEnabled` false, `isFocusable` false and no tap action;
    - re-enabling while the mouse rests on it gives the 1.12 filter after `pumpAndSettle`.
  - **`disabling mid-press clears the pressed state`:** hold a press, rebuild with `onPressed: null`, then release. There's no translation, the filter is identity, the opacity is 0.42 and nothing was called.
  - **`long label ellipsizes`:** in a `SizedBox(width: 120)`, a label 60 characters long (and a Hebrew one under the Hebrew harness) gives no `tester.takeException()`, and the `Text` has `maxLines` 1 and `overflow` ellipsis.
  - **`text scale 2.0 grows the button`:** under `MediaQuery(textScaler: TextScaler.linear(2))` there's no exception, and the decorated box height is ≥ the label's painted height + 2.
- [ ] **Step 2: Run and see it fail** wherever Task 2 didn't already implement the behaviour. Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/widgets/button_behavior_test.dart"`. Expected: failures name the missing behaviour. Any test that passes immediately is listed in the commit message and proven by mutants B4–B7 and B10–B14.
- [ ] **Step 3: Implement** whatever is missing.
- [ ] **Step 4: Run and see it pass.**
- [ ] **Step 5: Mutation proofs.**
  - **B4:** the ring is shown whenever the button has focus, ignoring the highlight. Fails the tap case (step 2).
  - **B5:** the disabled button stays focusable. Fails Tab-skip.
  - **B6:** `didUpdateWidget` doesn't clear `_pressed`. Fails mid-press.
  - **B7:** `GestureDetector` wraps the visual box, not the 44 box. Fails the hit margin.
  - **B10:** hover from `onShowHoverHighlight` instead of `MouseRegion`. Fails touch-mode hover.
  - **B11:** `Semantics` without `onTap`. Fails the semantics tap.
  - **B12:** duration always 150 ms. Fails reduced motion.
  - **B13:** `Curves.linear`. Fails the 75 ms value.
  - **B14:** `excludeSemantics: true` on the outer `Semantics`. Fails `hasFocusAction`.
  - **B16:** ring outset `focusRingGap + focusRingWidth` (1 px further out). Fails the ring / gap pixels.
- [ ] **Step 6: Gates, then commit.** Commit as `feat(ZOD-UI-004): button hover, press, focus ring, semantics and disabled behaviour`.

### Task 4: Component-sheet cross-check (criterion 1)

**Files:**
- Create: `packages/shared_ui/test/support/button_features.dart`, a pure-Dart feature extractor.
- Create: `packages/shared_ui/test/widgets/button_sheet_test.dart`.

**Interfaces:**
- Produces (test-only):
  ```dart
  final class Rgba { const Rgba(this.width, this.height, this.data); final int width, height; final ByteData data; int argb(int x, int y); }
  final class ButtonFeatures { final int? left, top, width, height, fill, border, inkStart; final int label; final List<int>? ring; }
  ButtonFeatures measureButton(Rgba img, {required int originX, required int originY, required int drawnHeight,
      required int spanX, required int board, required int focus, required int padding, bool icon = false, bool boxless = false});
  ```
- **`measureButton` (the same function for the PNG and the render):**
  - **Scan row** `originY + drawnHeight / 2`. Starting at `originX`, find the first non-`board` pixel x.
  - **Ring:** a ring is present when pixels x and x + 1 equal `focus` and x + 2 and x + 3 equal `board`. Then `ring` = those 4 pixels and `left` = x + 4. Otherwise `left` = x.
  - **Right edge:** scan leftward from `originX + spanX` to the first non-`board` pixel. When a ring is present, the right edge is that pixel − 4.
  - **Top and height:** on column `left + 8`, scan down from `originY − 6`. Skip the ring, if present, until 2 px past its last `focus` row. Then take the first non-`board` pixel run. For a quiet cell with a ring, there's no visible box, so measure the ring instead:
    - `top` = the first `focus` row + 4;
    - `height` = the last `focus` row of the bottom segment − the first `focus` row − 7.
    
    Dark check: 1861 + 4 = 1865 and 1908 − 1861 − 7 = 40.
  - **Colours:** `fill` is at (`left + 4`, mid) and `border` at (`left`, mid).
  - **Label area:** x from `left + 1 + padding + (icon ? 16 + 8 : 0)` to `right − 1 − padding`, rows mid ± 5. `label` is the pixel with the largest RGB distance from the fill (from `board` when `boxless`).
  - **`boxless` (quiet outside the focus column):** the box is invisible. Only `inkStart` (the first non-board x minus `originX`) and `label` are measured; the other fields are null.
- **Origins:**
  - **PNG:** `originX` = the column's box x (Facts) − 8, `originY` = the row top (Facts). The small row uses `drawnHeight` 32 and the Facts' small coordinates.
  - **Flutter:** pump `RepaintBoundary(child: ColoredBox(color: surface, child: SizedBox(width: 260, height: 60, child: Stack(children: [Positioned(left: 8, top: 8, child: button)]))))`. Then `originX` = 0 (so the box starts at 8, as on the PNG side, and the ring at 4) and `originY` = 8 + (44 − drawn) / 2 = 10 (regular) / 14 (small). The boundary wraps the whole box, so the ring is captured.

- [ ] **Step 1: Write the failing test.** For each theme (`components_dark.png` / `components_light.png`), decode the PNG and assert its size is 1440 × 5586 / 1440 × 5569. Then, for each of the 25 cells plus the 2 small-row buttons, with `spanX` 218. The exception is the small-row "Export" cell, which uses `spanX` 110, because its neighbour "Small primary" starts at x 723 = 606 + 117:
  1. **PNG side:** `measureButton` on the PNG.
  2. **Flutter side:** render the same label, variant, size and a placeholder icon (`SizedBox.square(dimension: 16)`) where the sheet has an icon. Drive the column's state with real input, then `await tester.pumpAndSettle()`. A single `pump(150 ms)` isn't enough, because the animation starts on the frame that rebuilds:
     - hover: a mouse `TestGesture`;
     - focus: Tab;
     - pressed: a held press;
     - disabled: `onPressed: null`.
     
     Render to RGBA inside `runAsync` and measure.
  3. **Compare:**
     - `width` within ±1 (text rendering);
     - `height` exact;
     - `top − originY` exact, so pressed is +1;
     - `fill` and `border` within ±1 per channel (filter rounding; if translucent borders reach ±2, that's a ledgered ruling, never a silent change);
     - `ring` exact;
     - `label` within ±3 per channel;
     - quiet `boxless` cells: `inkStart` within ±1 (expected 8 + 17 = 25) and `label` within ±3.
  
  **Solid danger** is compared against `04-settings_delete-dialog_desktop_en_dark.png` with `originX` 773, `originY` 491, `spanX` 150 and board = the dialog `surface`. That cell sits at a fractional x, so compare only:
  - `width` within ±1;
  - `height` exact;
  - `fill` at `left + 4` within ±1;
  - `label` within ±3.
  
  Don't compare `border` or `left`, because the edge columns are antialiased.
  
  To show the comparison isn't hollow, also assert that the PNG features equal the Facts' measured literals for the default column.
- [ ] **Step 2: Run and see it fail.** Run `cmd //c "cd packages\\shared_ui && fvm flutter test test/widgets/button_sheet_test.dart"`. Expected: compile failure (no extractor).
- [ ] **Step 3: Implement `button_features.dart`, then run and see it pass.** If a width differs by more than 1 px:
  - check the border-box inset (17 / 13) first, then the label's font, weight, size and letter spacing against kit.css, using `superpowers:systematic-debugging`;
  - never widen a tolerance silently. A tolerance change is a ledgered ruling.
  
  Optionally write the Flutter renders to `ZODIANN_BUTTON_DIR` for visual review against the sheet.
- [ ] **Step 4: Mutation proofs.**
  - **S1:** hover factor 1.10. Fails the light secondary hover border (Δ4).
  - **S2:** pressed offset 0. Fails the pressed tops.
  - **S3:** a focus-ring gap of 1. Fails the ring.
  - **S4:** accentOutline label `text`. Fails the label colour.
- [ ] **Step 5: Gates, then commit.** Commit as `test(ZOD-UI-004): button states cross-checked against the component sheet`.

### Task 5: Review and close-out

- [ ] **Step 1: Whole-branch code review** (opus) with this plan's Review Focus. Fix Critical and Important findings test-first, and defer minors.
- [ ] **Step 2: Close out the docs.**
  - **UI-004 task file:** Done, all three criteria ticked. Notes:
    - D1, D2, D3, U1 (hover 150 ms) and U2 (44 everywhere), with dates;
    - the sheet's filter semantics, with MASTER plus the sheet over kit.css's `:hover`;
    - out-of-scope icon-only buttons and their owners;
    - "at most one primary per region" as a convention.
  - **Notes in other task files:**
    - **ZOD-NFR-009:** the dark solid-danger 3.37:1 shortfall (D2).
    - **ZOD-FND-009:** pass real icons through `ZodiannButton.icon`, at 16.
    - **ZOD-UI-013:** use `ZodiannButtonVariant.dangerSolid` for destructive confirmation; actions are 8 apart horizontally. Focus-ring contract: keep at least 4 px of clear, unclipped space around each button. If the dialog must clip, adjust its padding so keyboard focus stays visible. The button can't override an ancestor's clip.
    - **ZOD-UI-014:** the same focus-ring contract for buttons in panels (panel heads, panel bodies, scrolled content).
    - **ZOD-WHL-021, ZOD-SET-005, ZOD-DAT-001:** `ZodiannButton` takes max(drawn, 44) layout height and max(drawn width, 44) width (D3 / U2). Very short labels (e.g. small 'OK', '1') get transparent side margins. A container sized by content grows by 6 (small) / 2 (regular) px per side compared with the mockup (crossings panel head 56 → 68) unless its padding absorbs the margin.
    - **ZOD-NFR-010:** the button hover animates over 150 ms and is instant under `disableAnimations` (tested in UI-004).
    - **NAV-001, WHL-016, WHL-017:** icon buttons follow the same state model (`ZodiannStates`, brightness filters, focus ring).
  - **PROGRESS:**
    - Architecture Conventions:
      - buttons are `ZodiannButton`; at most one primary per region;
      - interactive states use `ZodiannStates`;
      - hit targets are ≥ 44 × 44 (drawn size unchanged), with buttons laid out 8 apart vertically;
      - focus-ring contract: consumers keep ≥ 4 px of clear, unclipped space around buttons; a layout that must clip adjusts its padding so keyboard focus stays visible.
    - Technical Decisions: D1, D2, D3, U1, U2, and the filter semantics.
    - Verification, Git State, next task.
  - **TASKS.md:** UI-004 Done.
  - Commit as `docs(ZOD-UI-004): close out button components`, then push, open the PR and record its link.

## Plan review

### Round 1: Needs user decision (3 Critical, 6 Important, 9 Minor, 2 Needs user decision)

The reviewer re-scanned both component PNGs and the dialog PNG with its own decoder. It confirmed the filter model, every row top, column x, width and colour in the Facts, the contrast figures, and the existing token, style and guard APIs.

**Critical (all applied):**
- **C1:** the padding left out the 1 px border. The content inset is 17 / 13 (quiet "Cancel" 78 = 2 + 32 + 44). The build tree now uses `Container` (the border goes into the padding); the test expects 41 / 17 / 13; mutant B8 added.
- **C2:** a plain `Center` fills bounded parents. It's now `Align(widthFactor: 1, heightFactor: 1)`, with a `Row`-in-300-high-box test and mutant B9.
- **C3:** the solid-danger origin landed on Cancel, and its edges are antialiased. The origin is now (773, 491), `spanX` 150, with no `border` or `left` comparison.

**Important (all applied):**
- **I1:** `onShowHoverHighlight` is suppressed in touch highlight mode. Hover now comes from `MouseRegion`, with a touch-mode hover test and mutant B10.
- **I2:** `excludeSemantics` dropped the tap action. `Semantics` now carries `onTap`, `focusable` and `focused`, with semantics tests, mutant B11 and Review Focus 6.
- **I3:** the tap half of the ring test couldn't catch B4. The test is now Tab → tap keeps focus with the ring hidden → Shift+Tab shows it again.
- **I4:** `measureButton` was underspecified (the ring is 2 px; origins; ring top; quiet has no box). It's fully specified now, including the `boxless` mode and the `Rgba` type.
- **I5:** D3's effect on dense rows is handed to WHL-021, SET-005 and DAT-001 (see U2).
- **I6:** all widget tests use a `MaterialApp` harness, which keyboard shortcuts need.

**Minor:**
- **M1** (guard-safe ring radius, constants instead of literals): applied.
- **M2** (S1 caught by the light secondary hover border): applied.
- **M3** (copy `_contrast`): applied.
- **M4** (compare filters by equality): applied.
- **M5** (line references): applied.
- **M6** (±2 on translucent borders is a ledgered ruling): applied.
- **M7** (keep `ColorFiltered` always present): applied, required by U1 anyway.
- **M8** (focus ring vs clipping): applied as Review Focus 8 and the UI-013 / UI-014 notes.
- **M9** (D3 gap wording, vertical vs horizontal): applied.

**Needs user decision (resolved 2026-11-13):**
- **U1:** animate MASTER §12's 150 ms hover, instant under reduced motion. Applied: `TweenAnimationBuilder`, `ZodiannStates.hoverDuration`, tests at 75 / 150 ms, a reduced-motion test, mutant B12, and an NFR-010 note.
- **U2:** keep the 44 layout everywhere, with notes for WHL-021, SET-005 and DAT-001.

### Round 2: Approve after corrections (3 Critical, 2 Important, 5 Minor, 0 Needs user decision)

The reviewer confirmed that every round-1 correction and U1 / U2 are applied consistently. It re-scanned the sheet and the dialog geometry, and verified the U1 mechanics against the Flutter 3.50 sources.

**Critical (all applied):**
- **C1:** the hover animation starts on the frame that rebuilds, so `pump(150 ms)` alone still shows identity. Task 3 now uses `pump()` then 75 + 75 ms, and Task 4 uses `pumpAndSettle()`.
- **C2:** the small-row "Export" cell needs `spanX` 110, because 218 runs into "Small primary".
- **C3:** `shared_ui` has no `flutter_localizations`, so `Locale('he')` resolves to LTR. The Hebrew harness now adds an explicit `Directionality(rtl)` and asserts it.

**Important (all applied):**
- **I1:** tests can't name a private painter. It's now a public `@visibleForTesting` `ZodiannFocusRingPainter`, hidden from the package export.
- **I2:** `excludeSemantics` dropped the focus action. The outer `Semantics` now keeps the merged `Focus` semantics; `GestureDetector` uses `excludeFromSemantics` and the visuals sit under `ExcludeSemantics`. The test adds `hasFocusAction`, a single label and disabled `isFocusable: false`; mutant B14 added.

**Minor (all applied):**
- **M1:** quiet focus-cell top and height are measured from the ring (1865 / 40).
- **M2:** `MouseRegion` always tracks, so a button re-enabled under a resting mouse shows hover (test added).
- **M3:** reduced motion goes through `FakeAccessibilityFeatures`.
- **M4:** a named 'Next' sibling for Tab / Shift+Tab.
- **M5:** the ease curve is checked at 75 ms (≈ 1.0963), with mutant B13.

No open items remain after two rounds.

### Material revision (2026-11-13): product-owner clarifications, round 1

**Clarifications applied** (no other product-owner decision changed, no scope added):
- **Focus-ring clipping contract:**
  - `ZodiannButton` paints the complete ring when no ancestor clips it, and doesn't claim to override an ancestor's clip.
  - Consumers keep ≥ 4 px of clear, unclipped space wherever the ring can appear. A layout that must clip adjusts its own padding so keyboard focus stays visible.
  - Recorded in D3, Review Focus 8, the Task 2 doc comment, a new Task 3 pixel test, the UI-013 / UI-014 hand-offs and the PROGRESS conventions.
- **Complete 44 × 44 target:** the hit box gets `minWidth: 44` as well as `minHeight: 44`. A new Task 2 test covers 'Save' / 'OK' / '1' in both sizes and checks the exact target size, the unchanged drawn size, centring and a margin tap. Mutant B15 added.

**Reviewer verdict:** approve after corrections (1 Critical, 2 Important, 5 Minor, 0 Needs user decision). The reviewer probed the layer stack on Flutter 3.50 with the bundled Plex Sans. All findings applied:
- **C1:** the ring-pixel test sampled fixed offsets at fractional edges. It now samples the one wholly covered ring pixel and gap pixel per side (ceil / floor of the edge), from a whole-pixel origin, for regular 'Save', small 'Save' and small '1'. Mutant B16 added.
- **I1:** narrow-label claims were corrected with measured widths (regular '1' 42.4, small 'OK' 43.8, small '1' 33.8). The horizontal-gap wording now accounts for a narrow button's side margins.
- **I2:** the `Row`-in-300 assertion is now max(drawn width, 44).
- **M1:** the margin tap is limited to small '1', with an explicit precondition.
- **M2:** a horizontal margin tap inside a `Row` was added to Task 3, and Review Focus 5 now covers it.
- **M3:** drawn widths are compared with `closeTo(…, 0.01)`.
- **M4:** Review Focus 8 states the per-size overhang beyond the layout.
- **M5:** the U2 hand-off covers width too.

Task 4 is unaffected: every sheet cell is wider than 44 when drawn.
