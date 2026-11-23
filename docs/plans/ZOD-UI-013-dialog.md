# ZOD-UI-013 Dialog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (sequential, native; see "Execution mode"). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build the modal dialog shell, `ZodiannDialog` and `showZodiannDialog`: a centred 420 px box (16 radius, 20/600 title, message, actions at the end) over a scrim, on the floating-layer elevation. Escape, a tap on the scrim and the back button close it **without** taking any action; focus stays inside while it is open and returns to the control that opened it. Delete confirmation (ZOD-DAT-004, ZOD-DAT-010 via SET-005), save-square naming (ZOD-DAT-002) and any other confirm/cancel flow build on it.

**Architecture:** One stateless widget for the box and one function that pushes a modal route on the **root** navigator, as `showZodiannDrawer` does. The route comes from Flutter's `RawDialogRoute`, which already gives a `FocusScope` that traps Tab traversal and a pop that restores the previous route's focus, a dismissible barrier that handles Escape and a tap, and the back button; this plan adds the Zodiann scrim, no animation, semantics, the layout and the pixel proof. All geometry comes from existing tokens plus two new size tokens and one new text role.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_ui` theme extensions (`ZodiannSurfaces`, `ZodiannElevation`, `ZodiannTextStyles`), `ZodiannButton`, `ZodiannTextField`, headless pixel measurement as in `table_sheet_test.dart`.

**Task:** `docs/development/shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md`. **Design:** `design-reference/zodiann/MASTER.md` §10 "Dialog" and §12 (motion), `_source/kit.css:284-287` (`.dialog`) and `:150` (`.scrim`), `screens/04-settings_delete-dialog_desktop_en_dark.png` (the one mocked instance, 1440 x 900), and the component sheet's "Save square" dialog (`components/components_{dark,light}.png`, section "Dialogs, drawer items and empty state").

## Facts established while planning (2026-11-23)

- **kit.css:** `.dialog` = `surface` fill, radius `--r-xl` (16), `--shadow-float`, padding `--s6` (24), width 420, `max-width: calc(100vw - 32px)`. `h3` 20 (`--fs-xl`) / 600, margin-bottom `--s2` (8); `p` `text-2`; `.actions` = flex, `justify-content: flex-end`, `gap: --s2` (8), `margin-top: --s6` (24). `.scrim` = `position: fixed; inset: 0; background: var(--scrim)`. No animation is specified for the dialog; MASTER §12 says "No decorative or ambient motion, ... no entrance animations", and its only dialog-like motion is the drawer's.
- **The mocked dialog** (settings, delete all data): English title "Delete all data?", a three-line message, actions "Cancel" (secondary) and "Delete all data" (solid danger), centred in the 1440 x 900 viewport over a darkened page; the box measures about 420 x 211 (x 510..930, y 345..556), measured exactly in Task 1.
- **The sheet's dialog** ("Save square", a message with a 16 margin, a `Name` field in its focused state, `quiet` Cancel and `primary` Save) exists in **both** themes; the settings screen has no light delete-dialog screenshot from the designer; a light and a Hebrew one are generated from the kit (O5, D10), and the sheet's dialog adds the field and primary-button variant in both themes.
- **Tokens that exist:** `ZodiannRadius.dialog` (16), `ZodiannSpace` (`s2` 8, `s4` 16, `s6` 24), `ZodiannElevation.floating` and `floatingOutline`, `ZodiannSurfaces.surface`, `text`, `text2`, `scrim`, `ZodiannTextStyles.body` and `small`. **Missing:** a dialog width token (420) and a dialog title role (20 / 600): `drawerWordmark` is 20 / 600 but is a wordmark with its own tracking, `panelTitle` is 16.
- **Existing pattern:** `showZodiannDrawer` pushes a custom modal route on the root navigator, reads the scrim from `ZodiannSurfaces.scrim`, ignores a second call while one is open, and instant-switches under reduced motion.
- **Flutter route behaviour (to be proved by Task 3's tests, not assumed):** a `ModalRoute`'s `FocusScope` keeps Tab inside the route; popping restores focus to the previous route's last focused control; the modal barrier dismisses on a tap and on Escape (`DismissIntent`) when dismissible.
- **Consumers:** ZOD-DAT-002 (a naming dialog with a `ZodiannTextField`), ZOD-DAT-004 and ZOD-DAT-010 / ZOD-SET-005 (confirm with a danger action), ZOD-NAV-004 (cites this task's focus-trap pattern for the drawer).

## Product-owner decisions

Taken by the owner on 2026-11-23, after plan-review round 1: **O4** add the `dialogTitle` role; **O5** generate a light delete-dialog reference with headless Chrome (labelled generated, never overriding the kit); **O6** restore focus to whatever held it when the dialog opened (keyboard-opened triggers), not to a tapped trigger. O1 to O3 are still the plan's defaults, awaiting the owner's approval of the plan (see "Open decisions").

## Decisions

- **D1. API:** `showZodiannDialog<T>(BuildContext, {required WidgetBuilder builder, bool barrierDismissible = true}) -> Future<T?>` and `ZodiannDialog({required String title, String? message, Widget? content, required List<Widget> actions})`. The caller localizes every string and builds the buttons (`ZodiannButton`); the shell holds no copy. No built-in confirm helper. *(O1)* **No re-entry guard** (unlike the drawer's): a confirm opened from a dialog must be able to stack, so the doc comment says "callers disable their trigger while the future is pending", and the notes on ZOD-DAT-004, ZOD-DAT-010 / ZOD-SET-005 tell them to guard a double tap.
- **D2. Dismissal returns `null`.** Escape, a scrim tap and the back button pop with no result; a caller treats **only an explicit value** (for example `true` from the confirm button) as consent, so a dismissal can never take the destructive action (acceptance 3).
- **D3. No animation:** the dialog and its scrim appear and disappear at once (MASTER §12). *(O2)*
- **D4. Focus:** the route's scope traps Tab and restores focus on pop (proved by tests, facts above). The route is built with `traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop` (the Navigator default is `parentScope`, which lets Tab at the last control escape to an enclosing non-root scope, whose existence depends on the host app's tree, so a passing test in a bare `MaterialApp` would prove nothing). **Restore means "to whatever control held focus when the dialog opened":** a keyboard-opened trigger gets it back; `ZodiannButton` and `ZodiannPressable` never take focus on a pointer tap, so a pointer-opened trigger held none and nothing is restored (the dialog scope must not be left holding focus). Restoring to the tapped trigger would need `showZodiannDialog` to capture the trigger's context. *(O6)* On open focus lands in the dialog scope; a caller that wants a control focused passes `autofocus: true` to its button (the documented advice for a destructive confirmation is Cancel). The shell sets no initial focus of its own. *(O3)*
- **D5. Layout:** the box is `ConstrainedBox(maxWidth: ZodiannSize.dialogWidth)` and fills the width it is given: under the route's centring that is `min(420, screen - 32)` (16, `ZodiannSpace.s4`, each side, added to `MediaQuery.viewPaddingOf` so a notch does not eat the margin), and under a tight parent (the sheet's `width: auto` Save-square dialog) it adopts the parent's width. No `LayoutBuilder` inside the box. Padding `s6`, radius `ZodiannRadius.dialog`, title then message separated by `s2`, an optional free `content` between the message and the actions, actions in a `Wrap` with `alignment: WrapAlignment.end`, `runAlignment: WrapAlignment.end`, the ambient `textDirection`, spacing `s2`, run spacing `s2` and a 24 gap above. **The route centres the box inside a full-viewport `SingleChildScrollView` built with `hitTestBehavior: HitTestBehavior.translucent`**, so a tap in the empty area falls through to the barrier (the default `opaque` would swallow scrim taps and fail acceptance 3), the box scrolls when it does not fit (a short landscape phone, a large text scale), the shadow (blur 64, offset 24) and the outside outline are not clipped to the box, and the whole thing rises above the keyboard (`MediaQuery.viewInsets`), which the save dialog's name field needs.
- **D6. Floating layer:** `ZodiannElevation.floating` plus `floatingOutline` painted **outside** the box (a `BoxShadow` spread of the outline width after `floating`), in both themes (ZOD-UI-003).
- **D7. Scrim:** `ZodiannSurfaces.scrim`, read from the theme when the dialog opens, covering the whole screen including the top bar (root navigator).
- **D8. Semantics:** `RawDialogRoute` only adds `scopesRoute` and `explicitChildNodes`, and knows nothing of the title, so **`ZodiannDialog` wraps its box in `Semantics(namesRoute: true, label: title, explicitChildNodes: true)`** and the title inside is `header: true`; a builder that returns something other than `ZodiannDialog` gets no route name (documented). The route is a private subclass of `RawDialogRoute` that overrides `semanticsDismissible => false` (as `_ZodiannDrawerRoute` does), so the scrim adds no node of its own: the Cancel button is the labelled way out for a screen reader.
- **D9. Title role:** add `ZodiannTextStyles.dialogTitle` rather than building a style from scratch: **20 / 1.45 / 600 / 0 em** (kit.css gives `.dialog h3` only `font-size: 20px; font-weight: 600; margin-bottom: 8px`, so it inherits `body`'s line height 1.45 and no tracking; the measurement in Task 1 is a check, not a source). It is a kit-derived role, not in MASTER §3 (MASTER §10 says only "title 20/600"). *(O4)* A new role touches `zodiann_text_styles.dart` (constructor, field, `roles` map, `copyWith`, `lerp`, `==`, the `buildZodiannTextStyles` call), `test/theme/typography_test.dart` (`_master`, whose key order is pinned, and `_withRole`, which throws for an unknown role) and, optionally, the "Other roles" list in `test/support/typography_specimen.dart`; `typography_rendering_test.dart` iterates the roles generically.
- **D10. Proof:** the dark delete dialog against the designer's 1440 x 900 screenshot (box geometry, fill, outline, shadow reach, text positions, button positions, scrim over the page); the **light** delete dialog and a **Hebrew** delete dialog against references generated from the kit by `tool/dialog/render_dialog_references.dart` (headless Chrome from `_source/settings.html?dialog=delete&theme=…&lang=…`, as ZOD-NAV-002's drawer tool does; the tool's dark output is compared with the designer's PNG to prove it reproduces it; the images are labelled generated and never override `kit.css` or MASTER); and the sheet's Save-square dialog in both themes (the field and the primary button variant). *(O5, decided)*

## Design (API)

```dart
/// The dialog box.
class ZodiannDialog extends StatelessWidget {
  const ZodiannDialog({
    super.key,
    required this.title,        // 20/600, a semantics header
    this.message,               // body, text-2
    this.content,               // any widget between message and actions (a field)
    required this.actions,      // buttons, end-aligned, 8 apart
  });
}

/// Shows it modally on the root navigator; the future completes with the
/// value the dialog pops with, or null when it was dismissed.
Future<T?> showZodiannDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
});
```

- The builder returns a `ZodiannDialog`; a button closes it with `Navigator.of(context).pop(value)`. The route wraps the builder's widget in the centring, scrolling and keyboard padding of D5, so the widget itself is only the box.
- New tokens: `ZodiannSize.dialogWidth` (420.0), `ZodiannSize.dialogMargin` is **not** added (it is `ZodiannSpace.s4`).

## Global Constraints

- Values from tokens, never literals (`no_magic_dimensions_test`, `no_color_literals_test`); text styles derived with `copyWith` from `ZodiannTextStyles` roles; sentence case; no string literal in shipped `lib/` text (`no_text_literals_test`): every string comes from the caller.
- Material types from `package:material_ui`, never `flutter/material.dart`; directional geometry only (`EdgeInsetsDirectional`, `AlignmentDirectional`).
- Buttons keep at least 4 px of clear, unclipped space for their focus ring (ZOD-UI-004): the dialog's padding (24) provides it and the box must not clip.
- Run `test/architecture` with `dart test test/architecture`, never `flutter test`; Flutter commands as `fvm flutter …`, Melos as `fvm dart run melos …`; one long process at a time. Keyboard tests use `pumpInApp` (a `MaterialApp` gives the tree its shortcuts and traversal actions).

## Review Focus

Inputs the task implies and no acceptance criterion exercises; each has a test in the named task.

1. **A control outside the dialog while it is open:** Tab never reaches it, and a tap on it (through the scrim) does not activate it. (Task 3)
2. **Focus return after every way of closing** (Cancel, Escape, scrim tap, back button, a result button): the trigger is focused again, also when the trigger scrolled away. (Task 3)
3. **A dialog with a text field and the keyboard open** (view insets), and a very short viewport: the box stays reachable (scrolls), never overflows. (Task 2)
4. **Hebrew and RTL:** the actions' order and end edge, the title and message alignment. (Task 2, Task 4)
5. **Text scale 2x and a long message or a long button label:** wraps and scrolls, never clips. (Task 2)
6. **A second `showZodiannDialog` while one is open** (a confirm opened from a dialog), and a dialog opened from a dialog's route: stacks, and closing the top returns to the one below. (Task 3)
7. **Dismissal never returns consent:** the future completes with `null`, and a confirm callback that sits on the button is not called by Escape, scrim or back. (Task 3)
8. **`barrierDismissible: false`:** Escape and a scrim tap do nothing, the buttons still close it. (Task 3)

## Out of scope

- A confirm helper with built-in copy and buttons (ZOD-DAT-004 and ZOD-DAT-010 compose their own).
- The drawer's own focus work (ZOD-NAV-004 follows this task's pattern).
- The settings screen itself, and a mobile (390 px) dialog reference (the generated tool renders desktop 1440 x 900 only; the phone width is covered by the max-width tests).
- Any entrance animation (D3).

## File structure

- Modify `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart`: `ZodiannSize.dialogWidth`.
- Modify `packages/shared_ui/lib/src/theme/zodiann_text_styles.dart`: `dialogTitle` role (constructor, field, `roles` map with `'dialogTitle'` inserted right after `'drawerWordmark'`, in the same position as the `_master` entry, and the map's doc comment amended to note a kit-derived role, `copyWith`, `lerp`, `==`, the `buildZodiannTextStyles` call; `hashCode` follows `roles`). Modify `packages/shared_ui/test/theme/typography_test.dart` (`_master` entry after `drawerWordmark`, with a comment that it is kit-derived and not in MASTER §3; the `_withRole` case) and optionally `test/support/typography_specimen.dart`.
- Create `packages/shared_ui/lib/src/widgets/zodiann_dialog.dart`: `ZodiannDialog` (the box).
- Create `packages/shared_ui/lib/src/widgets/zodiann_dialog_route.dart`: `showZodiannDialog` and the private route.
- Modify `packages/shared_ui/lib/shared_ui.dart` (exports).
- Create `tool/dialog/render_dialog_references.dart` (modelled on `tool/drawer/render_drawer_references.dart`: Chrome from `C:/Program Files/Google/Chrome/Application/chrome.exe` or `CHROME`; writes `packages/shared_ui/test/fixtures/dialog/generated_<theme>_<lang>_desktop.png` for dark and light, English and Hebrew, plus `manifest.json` with the Chrome version and the SHA-256 of `settings.html`, `kit.css`, `kit.js`, `assets/fonts/fonts.css` and both logo SVGs, LF-normalised; the same Chrome flags and device as the drawer tool, `--headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --force-color-profile=srgb --font-render-hinting=none --force-device-scale-factor=1 --window-size=1440,900 --virtual-time-budget=5000`; URL `settings.html?lang=<lang>&theme=<theme>&dialog=delete`, the designer's own job in `_source/render/jobs.json`; assert a 1440 x 900 PNG) and a `README.md` beside the images saying they are generated, not designer assets.
- Create tests: `test/widgets/dialog_test.dart` (layout, RTL, text scale, keyboard inset, semantics), `test/widgets/dialog_route_test.dart` (dismissal, focus trap and restore, stacking, results), `test/widgets/dialog_sheet_test.dart` (pixels), support `test/support/dialog_features.dart` if the run helpers need more than `table_features.dart`.
- Documentation: the task file (Completion notes), `docs/development/TASKS.md`, notes on ZOD-NAV-004, ZOD-DAT-002, ZOD-DAT-004, ZOD-DAT-010 / ZOD-SET-005, `docs/PROGRESS.md` (Architecture Conventions "Dialog", Technical Decisions, Verification, Git State, the record that PR #60 (ZOD-L10-002) merged as `5e60667`).

## Tasks

### Task 1: Tokens and the measured oracle

**Files:** modify `zodiann_dimensions.dart`, `zodiann_text_styles.dart`; tests in `packages/shared_ui/test/theme/dimensions_test.dart` and the typography test that pins the roles; a throwaway measurement test (not committed) whose results go under "Measured facts".

**Interfaces:** Produces `ZodiannSize.dialogWidth` (420.0) and `ZodiannTextStyles.dialogTitle`.

- [ ] **Step 1: RED.** In `dimensions_test.dart`, parse `kit.css` (`_rule(css, '.dialog')`, `.dialog h3`, `.dialog .actions`) and assert the 420 width (`_px` matches `width: 420px` and not `max-width`), and, resolving `var(--s6)`, `var(--s2)` and `--r-xl` through `_kitPx`, the 24 padding (`ZodiannSpace.s6`), the 16 radius (`ZodiannRadius.xl`), the 8 gaps and the 24 actions margin; assert `ZodiannSize.dialogWidth == 420`. In `typography_test.dart` add the `dialogTitle` entry to `_master` (20 / 1.45 / 600 / 0 em, after `drawerWordmark`) and the `_withRole` case. Run `cd packages/shared_ui; fvm flutter test test/theme`; expected: compile errors, `dialogWidth` and `dialogTitle` undefined.
- [ ] **Step 2: Implement** the constant and the role (20 / 1.45 / 600 / 0 em, built with the helper the other roles use, `ui(20, 1.45, semibold, 0)`; no `TextStyle` from scratch), in every place D9 lists.
- [ ] **Step 3: Run** the same command and `dart test test/architecture` from the root; pass.
- [ ] **Step 4: Measure** with a throwaway `flutter_test` file (decode PNGs with `dart:ui` as `test/support/tag_features.dart` does): in the delete-dialog screenshot, the box's left, right, top, bottom, the fill colour, the 1 px outline colour, how far the shadow reaches and its colour at the box's bottom, the title's cap-height row and left edge, the message's three line positions, each button's box and the gap between them, the scrim-blended page colour at a point with no panel under it (compare with `Color.alphaBlend(scrim, bg)`); in both sheets the Save-square dialog's box, the title and message, the 16 gap, the field, the buttons. Write each into "Measured facts" as a literal, then delete the file. Where a measured value differs from the plan's expectation (box 420 wide, padding 24, title to message 8, message to actions 24, button gap 8), the measured value is the oracle and the difference is recorded; confirm the title's line pitch against the 20 / 1.45 role (hand arithmetic from the kit values gives a box about 210 high against the screenshot's 211). **Record the sheet dialog's own box width explicitly** (it is rendered with `width: auto` inside a three-column board, so it is not 420) and the shadow's reach below the box.
- [ ] **Step 5: Commit** `feat(ZOD-UI-013): add the dialog width token and title role`.

#### Measured facts (filled in Task 1, Step 4)

Measured 2026-11-23 by pixel scans (throwaway test, deleted) of the designer's `screens/04-settings_delete-dialog_desktop_en_dark.png` (1440 x 900) and `components/components_{dark,light}.png` (1440 wide):

- **Delete dialog (dark), box:** fill `111114` over x 510..929 (**420 wide**) and y 345..554 (**210 high**), centred in the viewport (centre y 449.5). A 1 px ring sits **outside** the fill at x 509 and 930, y 344 and 555.
- **The ring is darkened by the shadow over it:** `242429` at the top (y 344), `1d1d22` at the sides (x 509, 930), `161619` at the bottom (y 555). The kit stacks the shadow **above** the ring (CSS paints the first listed shadow on top), so a flat `line` ring on top of the shadow would differ at the bottom. **Task 2 does not pin the order of `ZodiannElevation.floating` and the outline in `boxShadow`; Task 4's pixels decide it** (UI-003's note says "after `floating`"; if Flutter's list order paints the ring on top, put the outline first).
- **Scrim and shadow (dark):** the page under the scrim reads `020203` (page `08080a`, so the scrim is about 72 % black) and just below the box `010101`, easing back to `020203` about 57 px below (y 556 `010101` to y 577 `020202`): the dark shadow is nearly invisible (1 level), so its check is weak in dark.
- **Vertical rhythm:** the title's ink spans rows 376..390 (a 29 px line box, 20 x 1.45, from y 369), the message's three lines 411..423, 431..443, 452..464 (pitch 20.3 = 14 x 1.45) from y 405, the buttons' boxes 491..530 (**40 high**, border `2a2a30`), 24 px of padding below (y 531..554). That is padding 24, title 29, gap 8, message 61, gap 24, button 40, padding 24 = **210**, so the `dialogTitle` role is 20 / 1.45.
- **Horizontal:** title ink starts at x 535 (padding 24 plus a 1 px side bearing from x 510); Cancel `18181c` fill, border `2a2a30`, x 694..770 (**77 wide**); a **8 px gap** (771..778); Delete all data solid `f2555a` from x 779 to the content edge x 905 (**127 wide**); the right padding is 24 (906..929).
- **Sheet Save-square dialog:** box fill x 65..487 (**423 wide**, not 420: `width: auto` in a three-column board), outline ring at x 64 and 488. Dark: fill `111114` y 5190..5438 (**249 high**), ring `242429` / `25252a` at y 5189 and `19191c` at y 5439; the focused field's border `f4f5f7` at y 5311 and 5350. Light: ring `cfd2d7` / `d3d6db` at x 64 and y 5172, `c1c4c8` at y 5421, fill y 5173..5420 (**248 high**, the same layout snapped differently), field border `0b0c0e` at y 5293 and 5332.
- **Not yet measured:** the generated light and Hebrew delete-dialog images (Task 4 Step 0 adds their literals before Step 1).

### Task 2: The dialog box (RED first)

**Files:** create `zodiann_dialog.dart`; modify `shared_ui.dart`; test `test/widgets/dialog_test.dart`.

**Interfaces:** Consumes the tokens above, `ZodiannButton`, `ZodiannTextField`. Produces `ZodiannDialog`.

- [ ] **Step 1: Write the failing tests** (names, with assertions):
  - `the box is 420 wide with 24 padding and a 16 radius` (size, padding offsets of the title, the decoration radius); `it is never wider than the screen less 16 each side` (a 300 px viewport gives 268).
  - `the title is the dialog title style and a semantics header`; `the box names the route`: its semantics node has `namesRoute` and the title as its label (Task 3 proves it through the route); `the box fills a tight parent's width up to 420` (a `SizedBox(width: 300)` parent gives 300, a loose parent gives 420); `the message is body in text-2`; `an empty message and an absent content leave no gap` (title then actions at 24).
  - `the gaps are 8 between title and message, 24 above the actions, 8 between buttons`.
  - `the actions sit at the end edge` (LTR right, RTL left), `their order follows reading order` (first action nearest the start).
  - `a long button row wraps`, `a message with 2x text scale wraps and the box grows`, `a content taller than the viewport scrolls and does not overflow` (a 300 px high viewport and 400 px of content: no `FlutterError`, the last action reachable by scrolling).
  - `the box rises above the keyboard`: a `MediaQuery` with `viewInsets.bottom` 300 on a 600 px viewport keeps the box inside the visible area, with a `ZodiannTextField` inside it.
  - `the floating shadow and the outside outline are painted`: the decoration's `boxShadow` contains `ZodiannElevation.floating`'s shadows and a spread of `floatingOutline.width` in its colour, in both themes; their order is **not** pinned here (Task 4's pixels decide it, see Measured facts).
  - `an empty actions list asserts` (a dialog without an action is a bug).
- [ ] **Step 2: Run** `cd packages/shared_ui; fvm flutter test test/widgets/dialog_test.dart`; expected: a compile failure (`ZodiannDialog` undefined).
- [ ] **Step 3: Implement** `ZodiannDialog` per D5, D6 and D8's header, and export it.
- [ ] **Step 4: Run** the same command; all pass; `fvm flutter analyze --fatal-infos`.
- [ ] **Step 5: Commit** `feat(ZOD-UI-013): add the dialog box`.

### Task 3: The modal route (RED first)

**Files:** create `zodiann_dialog_route.dart`; modify `shared_ui.dart`; test `test/widgets/dialog_route_test.dart`.

**Interfaces:** Consumes `ZodiannDialog`. Produces `showZodiannDialog<T>`.

- [ ] **Step 1: Write the failing tests** (a `MaterialApp` harness with a screen of focusable buttons, via `pumpInApp`):
  - `the dialog opens on the root navigator, centred, over the scrim` (the scrim colour is `ZodiannSurfaces.scrim` in both themes).
  - `a result button closes it and the future completes with its value`; `Escape, a scrim tap and the back button complete with null and call no button callback` (Review Focus 7), and `a tap in the empty area beside, above and below the box dismisses it` (four points outside the box, not only a corner: the full-viewport scroll view must let them through, D5).
  - `focus returns to the trigger` (Review Focus 2), after each way of closing, for a **keyboard-opened** trigger (focus it by Tab, open by Enter or Space, close, expect `FocusManager.instance.primaryFocus` to be the trigger's node), also with the trigger scrolled out of view (a `SingleChildScrollView` with a `Column`, **not** a lazy `ListView.builder`, which would dispose the trigger); and for a **pointer-opened** trigger (a tap on a button that holds no focus): after closing, primary focus is not left in the dead dialog scope and no exception is thrown (D4, O6).
  - `Tab stays inside the dialog` (press Tab more times than there are controls: focus cycles over the dialog's buttons only, never a control behind it) and `Shift+Tab` the same, **also when the dialog is opened inside an extra `FocusScope` wrapper** (the Navigator default `parentScope` would let focus escape; the route uses `closedLoop`); `a tap on a control behind the scrim does not activate it` (Review Focus 1).
  - `Escape right after open, with nothing focused inside the dialog, dismisses it`; `Escape while a ZodiannTextField inside the dialog has focus dismisses it` (the save dialog's case, ZOD-DAT-002).
  - `barrierDismissible false ignores Escape and a scrim tap, buttons still close it` (Review Focus 8).
  - `a second dialog opened from the first stacks and closing it returns to the first` (Review Focus 6), the first still focus-trapped.
  - `the route scopes and names itself`: the dialog's semantics node has `scopesRoute` (from the route) and `namesRoute` with the title as its label (from `ZodiannDialog`), the scrim adds no node (`semanticsDismissible` false), a screen behind it is excluded from the tree while it is open; a builder that returns a plain widget gets `scopesRoute` but no name.
  - `no animation`: the dialog is fully visible on the first pumped frame and gone on the first frame after closing (no `pumpAndSettle` needed).
- [ ] **Step 2: Run** `cd packages/shared_ui; fvm flutter test test/widgets/dialog_route_test.dart`; expected: a compile failure (`showZodiannDialog` undefined). If an assumed Flutter behaviour is false (focus restore, Escape on the barrier, Tab confinement), the failing test names it and Step 3 adds the minimal route code that makes it true (for example an explicit `FocusScopeNode` restore in the route's `didPop`), recorded as a ruling.
- [ ] **Step 3: Implement** `showZodiannDialog` on a private subclass of `RawDialogRoute` (`RawDialogRoute(pageBuilder: …, barrierDismissible: …, barrierColor: …, transitionDuration: Duration.zero, requestFocus: true, traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop)`; the subclass overrides `semanticsDismissible => false`), pushed on the root navigator, `barrierColor` read from the theme when it opens, the D5 centring in a full-viewport translucent `SingleChildScrollView` with the keyboard and view-padding insets around the builder's widget; document the re-entry note of D1. Export it.
- [ ] **Step 4: Run** the same command; all pass; `fvm flutter analyze --fatal-infos`.
- [ ] **Step 5: Commit** `feat(ZOD-UI-013): add the modal dialog route`.

### Task 4: Pixel proof against the designer's and the generated references, both themes

**Files:** create `tool/dialog/render_dialog_references.dart`, `packages/shared_ui/test/fixtures/dialog/` (generated PNGs, `manifest.json`, `README.md`), `test/widgets/dialog_sheet_test.dart` (and a support file if needed).

- [ ] **Step 0: Generate the references.** Write the tool (see File structure) and run `fvm dart run tool/dialog/render_dialog_references.dart` from the root; commit the PNGs, the manifest and the README. Check that the tool's **dark English** render equals the designer's `04-settings_delete-dialog_desktop_en_dark.png` (same box, fill, outline and text within 1 per channel over the dialog area), which proves the tool reproduces the designer's image; if it does not, stop and report before relying on its light and Hebrew output. **Then run the Task 1 Step 4 measurements on the generated light and Hebrew images** (box, fill, outline, shadow, text and button positions), add the literals to "Measured facts", and check the box height against the 210 hand arithmetic; the Task 4 test asserts those values. **The test file's header and the Completion notes state that the light and Hebrew images are generated, not the designer's.**
- [ ] **Step 1: Write the test** (acceptance 1), the dark delete dialog against the **designer's** screenshot and the **light** and **Hebrew** delete dialogs against the generated references, through one extractor. Dark delete dialog: render the same page behind the dialog is not possible, so compare the dialog against the screenshot by the Task 1 features: box left, right, top, bottom (420 x measured height), fill (±1 per channel), outline pixel, shadow reach and colour at the bottom edge (the shadow must not be clipped to the box: it reaches beyond it, as in the screenshot), the title and message text positions and colour (ink ±3), both buttons' boxes and the 8 gap, the box centred in the viewport; and the scrim: `Color.alphaBlend(scrim, bg)` against the screenshot's page colour at a point with no panel under it. Sheet Save-square dialog in **both** themes (rendered inside a `SizedBox` of the sheet box's measured width, which is not 420, D5): the same box, fill, outline, title, message, the 16 gap, the focused field box and the two buttons, through one extractor on the sheet and on the render.
- [ ] **Step 2: Add the Hebrew case:** the dialog in RTL against the generated Hebrew reference (actions at the left edge, text aligned to the start), and the geometry mirrored from the LTR measurement.
- [ ] **Step 3: Run** `cd packages/shared_ui; fvm flutter test test/widgets/dialog_sheet_test.dart`; a geometry failure is fixed in the implementation, never in a tolerance; if the reference and the kit disagree record it (the kit wins over MASTER's prose, as in UI-009 and UI-010).
- [ ] **Step 4: Mutation check:** change the radius, the padding and the action alignment in turn; each must fail a test.
- [ ] **Step 5: Commit** `test(ZOD-UI-013): match the delete and save dialogs in both themes`.

### Task 5: Verification, review, documentation

- [ ] **Step 1: Verification:** from the root, one process at a time: `fvm dart run melos run lint`, `fvm dart run melos run test`; record counts, exit codes and the head commit. If `ephemeris_swiss` fails with a `PathAccessException` on `test.dart.snapshot` (a parallel-run file lock seen in ZOD-L10-002), rerun once and record both runs.
- [ ] **Step 2: Whole-branch review** by a fresh reviewer (`requesting-code-review`), given the Review Focus; fix Critical and Important findings test-first.
- [ ] **Step 3: Documentation** after verification: the task file (tick the criteria, Completion notes), `TASKS.md`, notes on ZOD-NAV-004 (this task's route and focus pattern), ZOD-DAT-002 (the naming dialog: a field inside `content`, a result of the saved name), ZOD-DAT-004 and ZOD-DAT-010 / ZOD-SET-005 (confirm returns `true`, dismissal `null`, `autofocus` on Cancel, and **guard a double tap on the trigger: a second `showZodiannDialog` stacks, there is no re-entry guard**), `docs/PROGRESS.md` (Architecture Conventions "Dialog", Technical Decisions D1 to D10, Verification, Git State, the record that PR #60 merged as `5e60667`).
- [ ] **Step 4: Commit, push, open the PR** per the workflow; record the PR link in `docs/PROGRESS.md` as a small follow-up commit.

## Acceptance criteria mapping

1. The dialog matches `04-settings_delete-dialog_*` in both themes: Task 4. **Dark:** the designer's delete-dialog screenshot. **Light and Hebrew:** references generated from the kit with headless Chrome (O5), labelled generated; the sheet's Save-square dialog adds the field and primary-button variant in both themes. The Completion notes and the PR say which images are the designer's and which are generated.
2. Focus is trapped inside while open and returns to the trigger on close: Task 3 (Tab and Shift+Tab confinement, a tap behind the scrim, restore after every way of closing).
3. Escape and a backdrop tap close it without taking the destructive action: Task 3 (the future completes with `null`, no button callback runs).

## Execution mode

Sequential, native (`executing-plans`). No independent work: the route builds on the box and the proof on both. Subagents only for the mandatory plan review and the whole-branch review.

## Risks

- **Flutter 3.50's modal-route focus behaviour** may differ from the assumption (restore, Tab confinement, Escape on the barrier). Task 3's tests are the early check, and the plan allows minimal explicit code for any gap.
- **The light and Hebrew references are generated, not the designer's:** they come from `kit.css` through headless Chrome (O5). Only the dark English image is the designer's. The tool's dark output is compared with it (Task 4 Step 0) before the light and Hebrew output is relied on. The phone (390 px) width has no reference and is covered by the max-width tests.
- **The scrim colour over a real page** can only be checked against the screenshot's page colours (the page is not rebuilt here).
- **Keyboard insets in tests** are simulated with `MediaQuery`; a real soft keyboard is not exercised (no device).
- **A dialog opened while another route's animation runs** (a drawer closing) is not specially handled.
- **A warm link pops "whatever route is on top"** (ZOD-NAV-003, a known minor), so a dialog over the drawer or a screen would be popped as a dismissal: it returns `null`, which is safe by D2.
- **A double tap on a trigger stacks two dialogs** (D1): consumers guard it; notes are added to the DAT and SET tasks.

## Open decisions (O1 to O3: for the owner, defaults implemented; O4 to O6: decided 2026-11-23)

- **O1 (D1):** the minimal surface: the box and the show function, no built-in confirm helper; the DAT tasks compose their own buttons. Alternative: also ship `showZodiannConfirmDialog(title:, message:, confirmLabel:, cancelLabel:, danger:)` returning a `bool`.
- **O2 (D3):** no animation (MASTER §12 forbids entrance animations). Alternative: the scrim and box fade in over 120 ms, instant under reduced motion.
- **O3 (D4):** the shell sets no initial focus beyond the dialog scope; callers pass `autofocus: true` to a button (Cancel for a destructive confirmation). Alternative: focus the first action automatically.
- **O4 (D9), decided:** add a `dialogTitle` role (20 / 1.45 / 600) to `ZodiannTextStyles` (rejected: deriving from `drawerWordmark`).
- **O5 (D10), decided:** generate a light (and a Hebrew) delete-dialog reference with headless Chrome, labelled generated (rejected: proving light only from the sheet's Save-square dialog).
- **O6 (D4), decided:** restore focus to whatever held it when the dialog opened (keyboard-opened triggers); a pointer-opened trigger held none, so nothing is restored (rejected: capturing the tapped trigger's context).

## Plan review

### Round 1 (comprehensive) - verdict: needs user decision (O4, O5), then approve after corrections

| ID | Severity | Finding | Done |
|---|---|---|---|
| I1 | Important | A full-viewport scroll view would swallow scrim taps (`SingleChildScrollView` is opaque) | Applied: translucent hit-test behaviour, full-viewport so the shadow is not clipped (D5); test of taps at four points outside the box; shadow reach in Task 4 |
| I2 | Important | `RawDialogRoute` never sets `namesRoute` and its barrier adds a semantics node | Applied: `ZodiannDialog` carries `namesRoute` and the label; a private route subclass with `semanticsDismissible => false` (D8, Tasks 2 and 3) |
| I3 | Important | The Navigator's default `parentScope` traversal edge lets Tab escape to an enclosing scope | Applied: `traversalEdgeBehavior: closedLoop`; a test inside an extra `FocusScope` (D4, Task 3) |
| I4 | Important | Focus restore is only provable for keyboard-opened triggers (buttons take no focus on a tap) | Applied: D4 reworded, tests for both paths, the lazy-list pitfall; **O6 decided by the owner** (keyboard-opened only) |
| I5 | Important | The sheet's Save-square dialog is `width: auto`, not 420 | Applied: width resolution in D5, the sheet box width recorded in Task 1 and wrapped in a `SizedBox` in Task 4 |
| I6 | Important | `dialogTitle` line height is 1.45 (inherited), and the role touches more files than listed | Applied: 20 / 1.45 / 600 / 0 em, every place listed, `_master` and `_withRole`; **O4 decided by the owner** (add the role) |
| I7 | Important | No guard against a second `showZodiannDialog` | Applied: documented, notes for DAT-004, DAT-010 / SET-005 (D1, Task 5, Risks) |
| I8 | Important | Missing tests: Escape at open, Escape inside a `ZodiannTextField` | Applied (Task 3) |
| I9 | Important | "Pixel-for-pixel in both themes" cannot be claimed with only a dark image | Applied: acceptance mapping reworded; **O5 decided by the owner** (generate a light and a Hebrew reference; Task 4 Step 0 and a new tool) |
| M1 to M5 | Minor | Constructor form, `Wrap` alignment and view padding, the placeholder, explicit RED text, the warm-link risk | Applied |

Needs user decision: O4, O5 and the focus-return question (O6) were put to the owner and answered (2026-11-23); see "Open decisions".

### Round 2 (focused on the revision, `a831088..20c38c8`) - verdict: approve after corrections

| ID | Severity | Finding | Done |
|---|---|---|---|
| I1 | Important | A stale Risks bullet still said light is proved from the sheet | Applied: replaced by the generated-reference wording |
| I2 | Important | The Facts bullet said the same | Applied |
| I3 | Important | The generated light and Hebrew images were not measured anywhere before the test | Applied: Task 4 Step 0 measures them after the dark equality check, adds the literals to Measured facts, and the placeholder now says "before Task 4 Step 1" |
| M1 | Minor | The manifest inputs were not named | Applied (`settings.html`, `kit.css`, `kit.js`, `assets/fonts/fonts.css`, both logo SVGs) |
| M2 | Minor | Chrome flags, the dpr 1 device and the URL | Applied (the drawer tool's flags; `settings.html?lang=…&theme=…&dialog=delete`, the designer's own job in `jobs.json`; a 1440 x 900 assertion) |
| M3 | Minor | The `roles` map position | Applied (`dialogTitle` right after `drawerWordmark`, doc comment amended) |
| M4 | Minor | Typography contracts | Verified by the reviewer, no change |
| M5 | Minor | "Label generated" needs a mechanism | Applied (test file header and Completion notes) |

Open items after two rounds: none. Needs user decision: none new; O1 to O3 stand as plan defaults.
