# ZOD-UI-013 Dialog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (sequential, native; see "Execution mode"). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build the modal dialog shell, `ZodiannDialog` and `showZodiannDialog`: a centred 420 px box (16 radius, 20/600 title, message, actions at the end) over a scrim, on the floating-layer elevation. Escape, a tap on the scrim and the back button close it **without** taking any action; focus stays inside while it is open and returns to the control that opened it. Delete confirmation (ZOD-DAT-004, ZOD-DAT-010 via SET-005), save-square naming (ZOD-DAT-002) and any other confirm/cancel flow build on it.

**Architecture:** One stateless widget for the box and one function that pushes a modal route on the **root** navigator, as `showZodiannDrawer` does. The route comes from Flutter's `RawDialogRoute`, which already gives a `FocusScope` that traps Tab traversal and a pop that restores the previous route's focus, a dismissible barrier that handles Escape and a tap, and the back button; this plan adds the Zodiann scrim, no animation, semantics, the layout and the pixel proof. All geometry comes from existing tokens plus two new size tokens and one new text role.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_ui` theme extensions (`ZodiannSurfaces`, `ZodiannElevation`, `ZodiannTextStyles`), `ZodiannButton`, `ZodiannTextField`, headless pixel measurement as in `table_sheet_test.dart`.

**Task:** `docs/development/shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md`. **Design:** `design-reference/zodiann/MASTER.md` §10 "Dialog" and §12 (motion), `_source/kit.css:284-287` (`.dialog`) and `:150` (`.scrim`), `screens/04-settings_delete-dialog_desktop_en_dark.png` (the one mocked instance, 1440 x 900), and the component sheet's "Save square" dialog (`components/components_{dark,light}.png`, section "Dialogs, drawer items and empty state").

## Facts established while planning (2026-11-23)

- **kit.css:** `.dialog` = `surface` fill, radius `--r-xl` (16), `--shadow-float`, padding `--s6` (24), width 420, `max-width: calc(100vw - 32px)`. `h3` 20 (`--fs-xl`) / 600, margin-bottom `--s2` (8); `p` `text-2`; `.actions` = flex, `justify-content: flex-end`, `gap: --s2` (8), `margin-top: --s6` (24). `.scrim` = `position: fixed; inset: 0; background: var(--scrim)`. No animation is specified for the dialog; MASTER §12 says "No decorative or ambient motion, ... no entrance animations", and its only dialog-like motion is the drawer's.
- **The mocked dialog** (settings, delete all data): English title "Delete all data?", a three-line message, actions "Cancel" (secondary) and "Delete all data" (solid danger), centred in the 1440 x 900 viewport over a darkened page; the box measures about 420 x 211 (x 510..930, y 345..556), measured exactly in Task 1.
- **The sheet's dialog** ("Save square", a message with a 16 margin, a `Name` field in its focused state, `quiet` Cancel and `primary` Save) exists in **both** themes; the settings screen has **no** light delete-dialog screenshot, so light is proved from the sheet.
- **Tokens that exist:** `ZodiannRadius.dialog` (16), `ZodiannSpace` (`s2` 8, `s4` 16, `s6` 24), `ZodiannElevation.floating` and `floatingOutline`, `ZodiannSurfaces.surface`, `text`, `text2`, `scrim`, `ZodiannTextStyles.body` and `small`. **Missing:** a dialog width token (420) and a dialog title role (20 / 600): `drawerWordmark` is 20 / 600 but is a wordmark with its own tracking, `panelTitle` is 16.
- **Existing pattern:** `showZodiannDrawer` pushes a custom modal route on the root navigator, reads the scrim from `ZodiannSurfaces.scrim`, ignores a second call while one is open, and instant-switches under reduced motion.
- **Flutter route behaviour (to be proved by Task 3's tests, not assumed):** a `ModalRoute`'s `FocusScope` keeps Tab inside the route; popping restores focus to the previous route's last focused control; the modal barrier dismisses on a tap and on Escape (`DismissIntent`) when dismissible.
- **Consumers:** ZOD-DAT-002 (a naming dialog with a `ZodiannTextField`), ZOD-DAT-004 and ZOD-DAT-010 / ZOD-SET-005 (confirm with a danger action), ZOD-NAV-004 (cites this task's focus-trap pattern for the drawer).

## Product-owner decisions

None taken yet. The defaults below are what the plan implements unless the owner says otherwise (see "Open decisions").

## Decisions

- **D1. API:** `showZodiannDialog<T>(BuildContext, {required WidgetBuilder builder, bool barrierDismissible = true}) -> Future<T?>` and `ZodiannDialog({required String title, String? message, Widget? content, required List<Widget> actions})`. The caller localizes every string and builds the buttons (`ZodiannButton`); the shell holds no copy. No built-in confirm helper. *(O1)*
- **D2. Dismissal returns `null`.** Escape, a scrim tap and the back button pop with no result; a caller treats **only an explicit value** (for example `true` from the confirm button) as consent, so a dismissal can never take the destructive action (acceptance 3).
- **D3. No animation:** the dialog and its scrim appear and disappear at once (MASTER §12). *(O2)*
- **D4. Focus:** the route's scope traps Tab and restores the trigger on pop (proved by tests, D-facts above). On open focus lands in the dialog scope; a caller that wants a control focused passes `autofocus: true` to its button (the documented advice for a destructive confirmation is Cancel). The shell sets no initial focus of its own. *(O3)*
- **D5. Layout:** width 420, never wider than the screen less 16 each side (`ZodiannSpace.s4`), padding `s6`, radius `ZodiannRadius.dialog`, title then message separated by `s2`, an optional free `content` between the message and the actions, actions in a `Wrap` aligned to the **end** (directional) with spacing `s2` and a 24 gap above. The box is centred and scrolls when it does not fit (a short landscape phone, a large text scale) and rises above the keyboard (`MediaQuery.viewInsets`), which the save dialog's name field needs.
- **D6. Floating layer:** `ZodiannElevation.floating` plus `floatingOutline` painted **outside** the box (a `BoxShadow` spread of the outline width after `floating`), in both themes (ZOD-UI-003).
- **D7. Scrim:** `ZodiannSurfaces.scrim`, read from the theme when the dialog opens, covering the whole screen including the top bar (root navigator).
- **D8. Semantics:** the route scopes and names itself (`scopesRoute`, `namesRoute`, labelled with the title), the title is a semantics header, and the scrim adds no node of its own (the Cancel button is the labelled way out for a screen reader), as the drawer's route does.
- **D9. Title role:** add `ZodiannTextStyles.dialogTitle` (20 / 600, line height measured in Task 1) rather than building a style from scratch. *(O4)*
- **D10. Proof:** the dark delete dialog against the 1440 x 900 screenshot (box geometry, fill, outline, shadow reach, text positions, button positions, scrim over the page), and the sheet's Save-square dialog against both themes (which also pins the light theme). A light delete-dialog reference is not generated. *(O5)*

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
- A light delete-dialog reference image, and the settings screen itself.
- Any entrance animation (D3).

## File structure

- Modify `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart`: `ZodiannSize.dialogWidth`.
- Modify `packages/shared_ui/lib/src/theme/zodiann_text_styles.dart`: `dialogTitle` role (constructor, field, `copyWith`, `lerp`, `==`, hash, `tokens` map, the default build) and its token tests.
- Create `packages/shared_ui/lib/src/widgets/zodiann_dialog.dart`: `ZodiannDialog` (the box).
- Create `packages/shared_ui/lib/src/widgets/zodiann_dialog_route.dart`: `showZodiannDialog` and the private route.
- Modify `packages/shared_ui/lib/shared_ui.dart` (exports).
- Create tests: `test/widgets/dialog_test.dart` (layout, RTL, text scale, keyboard inset, semantics), `test/widgets/dialog_route_test.dart` (dismissal, focus trap and restore, stacking, results), `test/widgets/dialog_sheet_test.dart` (pixels), support `test/support/dialog_features.dart` if the run helpers need more than `table_features.dart`.
- Documentation: the task file (Completion notes), `docs/development/TASKS.md`, notes on ZOD-NAV-004, ZOD-DAT-002, ZOD-DAT-004, ZOD-DAT-010 / ZOD-SET-005, `docs/PROGRESS.md` (Architecture Conventions "Dialog", Technical Decisions, Verification, Git State, the record that PR #60 (ZOD-L10-002) merged as `5e60667`).

## Tasks

### Task 1: Tokens and the measured oracle

**Files:** modify `zodiann_dimensions.dart`, `zodiann_text_styles.dart`; tests in `packages/shared_ui/test/theme/dimensions_test.dart` and the typography test that pins the roles; a throwaway measurement test (not committed) whose results go under "Measured facts".

**Interfaces:** Produces `ZodiannSize.dialogWidth` (420.0) and `ZodiannTextStyles.dialogTitle`.

- [ ] **Step 1: RED.** In `dimensions_test.dart`, parse `kit.css` (`_rule(css, '.dialog')`) and assert the 420 width, the 24 padding (`ZodiannSpace.s6`), the radius (`ZodiannRadius.xl`), the 8 gaps and the 24 actions margin; assert `ZodiannSize.dialogWidth == 420`. In the typography tests add the `dialogTitle` role (20, weight 600, the `ZodiannTextStyles.tokens` map key). Run `cd packages/shared_ui; fvm flutter test test/theme`; expected: compile failures naming the missing members.
- [ ] **Step 2: Implement** the constant and the role (line height from Step 4's measurement, default 1.3 until then; the role is built from the same helper the other roles use; no `TextStyle` from scratch), including `copyWith`, `lerp`, equality and the `tokens` map.
- [ ] **Step 3: Run** the same command and `dart test test/architecture` from the root; pass.
- [ ] **Step 4: Measure** with a throwaway `flutter_test` file (decode PNGs with `dart:ui` as `test/support/tag_features.dart` does): in the delete-dialog screenshot, the box's left, right, top, bottom, the fill colour, the 1 px outline colour, how far the shadow reaches and its colour at the box's bottom, the title's cap-height row and left edge, the message's three line positions, each button's box and the gap between them, the scrim-blended page colour at a point with no panel under it (compare with `Color.alphaBlend(scrim, bg)`); in both sheets the Save-square dialog's box, the title and message, the 16 gap, the field, the buttons. Write each into "Measured facts" as a literal, then delete the file. Where a measured value differs from the plan's expectation (box 420 wide, padding 24, title to message 8, message to actions 24, button gap 8), the measured value is the oracle and the difference is recorded; set the `dialogTitle` line height from the title's measured line pitch.
- [ ] **Step 5: Commit** `feat(ZOD-UI-013): add the dialog width token and title role`.

#### Measured facts (filled in Task 1, Step 4)

_Placeholders, to be replaced by measured literals before Task 4: box geometry, fill and outline colours, shadow reach, title and message positions, button boxes, the scrim over the page; the sheet dialog's geometry in both themes._

### Task 2: The dialog box (RED first)

**Files:** create `zodiann_dialog.dart`; modify `shared_ui.dart`; test `test/widgets/dialog_test.dart`.

**Interfaces:** Consumes the tokens above, `ZodiannButton`, `ZodiannTextField`. Produces `ZodiannDialog`.

- [ ] **Step 1: Write the failing tests** (names, with assertions):
  - `the box is 420 wide with 24 padding and a 16 radius` (size, padding offsets of the title, the decoration radius); `it is never wider than the screen less 16 each side` (a 300 px viewport gives 268).
  - `the title is the dialog title style and a semantics header`; `the message is body in text-2`; `an empty message and an absent content leave no gap` (title then actions at 24).
  - `the gaps are 8 between title and message, 24 above the actions, 8 between buttons`.
  - `the actions sit at the end edge` (LTR right, RTL left), `their order follows reading order` (first action nearest the start).
  - `a long button row wraps`, `a message with 2x text scale wraps and the box grows`, `a content taller than the viewport scrolls and does not overflow` (a 300 px high viewport and 400 px of content: no `FlutterError`, the last action reachable by scrolling).
  - `the box rises above the keyboard`: a `MediaQuery` with `viewInsets.bottom` 300 on a 600 px viewport keeps the box inside the visible area, with a `ZodiannTextField` inside it.
  - `the floating shadow and the outside outline are painted`: the decoration's `boxShadow` is `ZodiannElevation.floating` followed by a spread of `floatingOutline.width` in its colour, in both themes.
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
  - `a result button closes it and the future completes with its value`; `Escape, a scrim tap and the back button complete with null and call no button callback` (Review Focus 7), each followed by `focus returns to the trigger` (Review Focus 2): focus the trigger by keyboard, open, close by each way, expect `FocusManager.instance.primaryFocus` to be the trigger's node; also with the trigger scrolled out of view.
  - `Tab stays inside the dialog` (press Tab more times than there are controls: focus cycles over the dialog's buttons only, never a control behind it) and `Shift+Tab` the same; `a tap on a control behind the scrim does not activate it` (Review Focus 1).
  - `barrierDismissible false ignores Escape and a scrim tap, buttons still close it` (Review Focus 8).
  - `a second dialog opened from the first stacks and closing it returns to the first` (Review Focus 6), the first still focus-trapped.
  - `the route scopes and names itself`: the dialog's semantics node has `scopesRoute` and `namesRoute` with the title as its label, the scrim adds no node, a screen behind it is excluded from the tree while it is open.
  - `no animation`: the dialog is fully visible on the first pumped frame and gone on the first frame after closing (no `pumpAndSettle` needed).
- [ ] **Step 2: Run** `cd packages/shared_ui; fvm flutter test test/widgets/dialog_route_test.dart`; expected: a compile failure (`showZodiannDialog` undefined). If an assumed Flutter behaviour is false (focus restore, Escape on the barrier, Tab confinement), the failing test names it and Step 3 adds the minimal route code that makes it true (for example an explicit `FocusScopeNode` restore in the route's `didPop`), recorded as a ruling.
- [ ] **Step 3: Implement** `showZodiannDialog` on a `RawDialogRoute` (root navigator, `barrierDismissible`, `barrierColor` from the theme at open, zero transition duration, the D5 centring, scrolling and keyboard padding around the builder's widget, the D8 semantics) and export it.
- [ ] **Step 4: Run** the same command; all pass; `fvm flutter analyze --fatal-infos`.
- [ ] **Step 5: Commit** `feat(ZOD-UI-013): add the modal dialog route`.

### Task 4: Pixel proof against the designer's references, both themes

**Files:** create `test/widgets/dialog_sheet_test.dart` (and a support file if needed).

- [ ] **Step 1: Write the test** (acceptance 1). Dark delete dialog: render the same page behind the dialog is not possible, so compare the dialog against the screenshot by the Task 1 features: box left, right, top, bottom (420 x measured height), fill (±1 per channel), outline pixel, shadow reach and colour at the bottom edge, the title and message text positions and colour (ink ±3), both buttons' boxes and the 8 gap, the box centred in the viewport; and the scrim: `Color.alphaBlend(scrim, bg)` against the screenshot's page colour at a point with no panel under it. Sheet Save-square dialog in **both** themes: the same box, fill, outline, title, message, the 16 gap, the focused field box and the two buttons, through one extractor on the sheet and on the render.
- [ ] **Step 2: Add the Hebrew case:** the same dialog with the actions at the left edge in RTL (no designer image exists; assert geometry mirrored from the LTR measurement).
- [ ] **Step 3: Run** `cd packages/shared_ui; fvm flutter test test/widgets/dialog_sheet_test.dart`; a geometry failure is fixed in the implementation, never in a tolerance; if the reference and the kit disagree record it (the kit wins over MASTER's prose, as in UI-009 and UI-010).
- [ ] **Step 4: Mutation check:** change the radius, the padding and the action alignment in turn; each must fail a test.
- [ ] **Step 5: Commit** `test(ZOD-UI-013): match the delete and save dialogs in both themes`.

### Task 5: Verification, review, documentation

- [ ] **Step 1: Verification:** from the root, one process at a time: `fvm dart run melos run lint`, `fvm dart run melos run test`; record counts, exit codes and the head commit. If `ephemeris_swiss` fails with a `PathAccessException` on `test.dart.snapshot` (a parallel-run file lock seen in ZOD-L10-002), rerun once and record both runs.
- [ ] **Step 2: Whole-branch review** by a fresh reviewer (`requesting-code-review`), given the Review Focus; fix Critical and Important findings test-first.
- [ ] **Step 3: Documentation** after verification: the task file (tick the criteria, Completion notes), `TASKS.md`, notes on ZOD-NAV-004 (this task's route and focus pattern), ZOD-DAT-002 (the naming dialog: a field inside `content`, a result of the saved name), ZOD-DAT-004 and ZOD-DAT-010 / ZOD-SET-005 (confirm returns `true`, dismissal `null`, `autofocus` on Cancel), `docs/PROGRESS.md` (Architecture Conventions "Dialog", Technical Decisions D1 to D10, Verification, Git State, the record that PR #60 merged as `5e60667`).
- [ ] **Step 4: Commit, push, open the PR** per the workflow; record the PR link in `docs/PROGRESS.md` as a small follow-up commit.

## Acceptance criteria mapping

1. The dialog matches `04-settings_delete-dialog_*` in both themes: Task 4 (the dark screenshot, and the sheet's dialog in both themes because no light delete-dialog image exists); Tasks 1 and 2 for the geometry.
2. Focus is trapped inside while open and returns to the trigger on close: Task 3 (Tab and Shift+Tab confinement, a tap behind the scrim, restore after every way of closing).
3. Escape and a backdrop tap close it without taking the destructive action: Task 3 (the future completes with `null`, no button callback runs).

## Execution mode

Sequential, native (`executing-plans`). No independent work: the route builds on the box and the proof on both. Subagents only for the mandatory plan review and the whole-branch review.

## Risks

- **Flutter 3.50's modal-route focus behaviour** may differ from the assumption (restore, Tab confinement, Escape on the barrier). Task 3's tests are the early check, and the plan allows minimal explicit code for any gap.
- **No light delete-dialog reference:** light is proved from the sheet's Save-square dialog, which has a field and a primary button rather than a danger button; the danger button's light look is covered by UI-004's sheet.
- **The scrim colour over a real page** can only be checked against the screenshot's page colours (the page is not rebuilt here).
- **Keyboard insets in tests** are simulated with `MediaQuery`; a real soft keyboard is not exercised (no device).
- **A dialog opened while another route's animation runs** (a drawer closing) is not specially handled.

## Open decisions (for the owner; defaults are implemented)

- **O1 (D1):** the minimal surface: the box and the show function, no built-in confirm helper; the DAT tasks compose their own buttons. Alternative: also ship `showZodiannConfirmDialog(title:, message:, confirmLabel:, cancelLabel:, danger:)` returning a `bool`.
- **O2 (D3):** no animation (MASTER §12 forbids entrance animations). Alternative: the scrim and box fade in over 120 ms, instant under reduced motion.
- **O3 (D4):** the shell sets no initial focus beyond the dialog scope; callers pass `autofocus: true` to a button (Cancel for a destructive confirmation). Alternative: focus the first action automatically.
- **O4 (D9):** add a `dialogTitle` role (20 / 600) to `ZodiannTextStyles`. Alternative: derive it from `drawerWordmark` with its tracking removed.
- **O5 (D10):** prove light from the sheet's Save-square dialog, with no generated delete-dialog reference. Alternative: render a light delete-dialog reference from `_source/settings.html` with headless Chrome, labelled generated, as ZOD-NAV-002 did for the drawer.

## Plan review

_Pending: the `plan-reviewer` cycle runs next (at most two rounds); the record is added here._
