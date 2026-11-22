# ZOD-UI-005 Input Field Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (sequential, native; see "Execution mode"). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build `ZodiannTextField`: a labelled 40 px text, date or number input on `bg-raised` with a `line` border, an optional 16 px leading icon, and four treatments (default, focus, error with a message, disabled), matching the "Inputs and selectors" section of the component sheet in both themes.

**Architecture:** One stateful widget in `packages/shared_ui/lib/src/widgets/` built on Flutter's `EditableText` (real text entry, IME, selection, accessibility) inside a Zodiann-drawn shell. The shell paints the border and the outside 3 px halo itself; the widget owns no validation and no parsing. The caller passes `errorText`, and the field turns its error state on and shows that message. Colours come from `ZodiannSurfaces`, the text style from a `ZodiannTextStyles` role, sizes from tokens.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_ui` theme extensions, PNG feature extraction (`Rgba` and helpers as in `test/support/tag_features.dart` and `segment_features.dart`).

**Task:** `docs/development/shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md`. **Design:** `design-reference/zodiann/MASTER.md` §10 "Inputs", §4 (radius 8, control height 40, icons 16 inside fields), §14 (44 px touch target); `_source/kit.css` lines 223-236 (`.field`, `.input`, `.err`); `_source/components.html` lines 104-112; `components/components_{dark,light}.png`. **Spec:** NFR-R2 (invalid input is rejected with a clear message, no crash), NFR-X4 (colour never alone), L-7 (numbers and dates stay left to right and are direction-isolated in Hebrew).

## Facts established while planning (2026-11-23)

- **kit.css (the pixel source):** `.field` is a grid with a 6 px gap; label 12 / 500 `text-2`. `.input`: height 40, radius 8, 1 px `line` border, `bg-raised`, row with gap 8 and `padding-inline` 12, value text 14 `text`, icon `text-3`. `.focus`: `accent` border and `0 0 0 3px accent-soft`. `.error`: `danger` border and `0 0 0 3px danger-soft`. `.disabled`: opacity 0.45 on the **input box only** (the label stays at full strength in the sheet). `.ph`: placeholder in `text-3`. `.err`: 12 px `danger`, row with gap 6, 16 px `alert` icon, then the message.
- **Gap in MASTER:** `danger-soft` (`rgba(242,85,90,.12)` dark, `rgba(220,53,69,.08)` light) is in kit.css but **not** in MASTER §2.1, and no such token exists in `ZodiannSurfaces`. MASTER only says "danger border plus a halo". See decision O1.
- **Tokens that exist:** `ZodiannSize.control` (40), `ZodiannSize.iconSmall` (16), `ZodiannSize.hairline` (1), `ZodiannRadius.control` (8), `ZodiannSpace.s2` (8), `s3` (12), `ZodiannStates.disabledOpacity` (0.42, a different value), `ZodiannSurfaces` (`bgRaised`, `line`, `text`, `text2`, `text3`, `accent`, `accentSoft`, `danger`), `ZodiannTextStyles.body` (14) and `label` (12 / 500), `ZodiannIcons.alert`, `calendar`, `clock`. `ZodiannTextStyles` has a tabular-figures variant used for readouts (`zodiann_text_styles.dart:214`).
- **No text input exists yet** in `apps/` or `packages/` (grep for `TextField`, `EditableText`, `TextFormField`), so there is no consumer to keep green. Later consumers: ZOD-SQR-002 (anchor), ZOD-SQR-003 (custom cells), ZOD-WHL-014 (time field), ZOD-WHL-020, ZOD-DAT-003 (inline rename), ZOD-SET-008, ZOD-NFR-015 (audit of invalid input).
- **Not an input field in this task:** the "Body" row in the sheet is a select with a chevron (`.input.select`). It is a selector, not text entry; see O3.

## Product-owner decisions

None taken yet. Open items are listed at the end; the defaults below are implemented unless the owner changes them.

## Design (API)

```dart
class ZodiannTextField extends StatefulWidget {
  const ZodiannTextField({
    super.key,
    required this.label,            // localized by the caller; always visible above the field
    this.controller,                // null: the field owns one
    this.focusNode,                 // null: the field owns one
    this.leadingIcon,               // ZodiannIconData?, 16 px, text-3
    this.hintText,                  // placeholder, text-3
    this.errorText,                 // non-null: error state + message; asserts non-empty
    this.enabled = true,
    this.ltr = false,               // dates and numbers (L-7): LTR, isolated, tabular figures
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });
}
```

- **Draws:** a column: label (12 / 500 `text-2`), 6 px gap, the input, and, in error only, 6 px gap and the message row. Input: min height 40 (grows with text scale, never shrinks), radius 8, 1 px border, `bg-raised`, row gap 8, horizontal padding 12, the icon (16, `text-3`) then the `EditableText` filling the row. Value text is the `body` role in `text`; the placeholder is `text-3`.
- **States:** default border `line`. Focused (any focus, mouse or keyboard; there is no 2 px focus ring on inputs, MASTER §10): border `accent` plus a 3 px `accent-soft` halo painted **outside** the box (no layout change). Error: border `danger` plus a 3 px `danger-soft` halo, and the message row. Error wins over focus (both borders are 1 px; the halo takes the error colour while the message is shown). Disabled: the input box at 0.45 opacity (new token, kit.css and MASTER say 45 %, not the shared 0.42), not focusable, no cursor, no edit, no tap; the label keeps full strength.
- **Error message (NFR-R2, NFR-X4):** `errorText` renders under the field as a row with the 16 px `alert` icon and the text in 12 px `danger`, in addition to the border and halo, so colour is never the only signal. An empty string asserts. The message wraps to as many lines as it needs (the sheet's message is long). Error plus `enabled: false` asserts (a disabled field is not editable, so it cannot be invalid).
- **Label association:** a tap on the label focuses the field (HTML `label` behaviour). The tappable area is the label and the input together, so the hit area is far above 44 px high even though the drawn input is 40.
- **L-7:** `ltr: true` sets the `EditableText` text direction to LTR with start alignment (as `.num`, `direction: ltr`), so in a Hebrew layout the value sits at the physical left of its box while the icon and label stay at the start edge; it also applies the tabular-figures style. The label and the error message follow the app direction.
- **Semantics:** one text-field node: `textField: true`, label = `label`, hint = the placeholder, `enabled`, `focused`; when in error the message is part of the node's hint and the row is a live region, so a change is announced. The decorative icons are excluded.
- **Never throws (NFR-R2):** the widget accepts any string (empty, very long, RTL marks, emoji, control characters). It does no parsing; validity is the caller's `errorText`.
- **Selection and cursor:** cursor `accent`, selection `accent-line`; selection handles and the toolbar use the platform's controls (Material on Android, the adaptive ones elsewhere), with labels from the app's localization delegates (checked in Task 5).
- **Controller and focus node:** an owned controller or node is created in `initState` and disposed; a supplied one is never disposed; both are swapped correctly in `didUpdateWidget`.

## Global Constraints

- No new dependency, no pubspec change; `no_network_test.dart` unchanged and green.
- Sizes only from `ZodiannSize` / `ZodiannSpace` tokens (UI-003 guard), colours only from the theme extensions (ARCH-7 guard), text styles via `copyWith` of a `ZodiannTextStyles` role, no string literals in `Text` (the l10n scanner), no `InputDecoration(labelText:)`.
- `ZodiannSurfaces.tokens` keeps MASTER's exact set and order (the master-values test); the kit-only `dangerSoft` is a field outside that map and is pinned against `kit.css` by its own test (O1).
- Existing shared widgets are unchanged (this task adds tokens and one widget; `ZodiannPressable` is not touched).
- Staging: explicit paths per commit; never `git add -A` / `.` / `commit -a`. `.fvmrc` and `grep.exe.stackdump` stay unstaged.
- Commands: `fvm flutter test <file>` from `packages/shared_ui`; **root** `fvm dart run melos run lint` / `test`. Tests that read `../../design-reference/...` need the package as working directory. Use the Write tool for files containing apostrophes.
- Naming: project prefix `Zodiann`.

## Out of scope

- Parsing or validating dates, times and numbers, and the messages (SQR-002, SQR-003, WHL-014, SET-008, NFR-015, localization L10-*): the caller supplies `errorText`.
- The select field with a chevron, the stepper, the switch and body chips (UI-007, or the screen that needs a select; O3).
- Obscured text, multi-line, character counters, clear buttons, suffix icons: not in the design.
- A date or time picker: not in the design.

## File structure

| File | Action |
|---|---|
| `lib/src/theme/tokens/zodiann_dimensions.dart` | add `ZodiannSize.fieldGap` (6), `fieldHalo` (3) |
| `lib/src/theme/tokens/zodiann_states.dart` | add `fieldDisabledOpacity` (0.45) |
| `lib/src/theme/zodiann_surfaces.dart`, `tokens/graphite_tokens.dart`, `tokens/porcelain_tokens.dart` | add `dangerSoft` (field, `copyWith`, `lerp`; not in `tokens`) |
| `lib/src/widgets/zodiann_text_field.dart` | new |
| `lib/shared_ui.dart` | export it |
| `test/theme/dimensions_test.dart`, `test/widgets/button_colors_test.dart` | pin the new size and state tokens |
| `test/theme/danger_soft_test.dart` | new: `dangerSoft` equals the kit.css value in both themes, and is absent from MASTER's map |
| `test/widgets/text_field_test.dart` | new: behaviour, states, semantics, keyboard, RTL / L-7, text scale, fuzz, lifecycle |
| `test/support/field_features.dart`, `test/widgets/text_field_sheet_test.dart` | new: sheet fidelity (both themes) |
| task file, `docs/development/TASKS.md`, `docs/PROGRESS.md` | status and records after verification |

## Tasks

### Task 1: Tokens (TDD)

- [ ] Write failing pins: `fieldGap == 6`, `fieldHalo == 3`, `fieldDisabledOpacity == 0.45` beside the existing pins; `dangerSoft` equals `rgba(242,85,90,.12)` (dark, `0x1FF2555A`) and `rgba(220,53,69,.08)` (light, `0x14DC3545`), read from `kit.css` in the test, and `surfaces.tokens` still has MASTER's exact keys.
- [ ] Run RED (compile errors count only as the expected reason), add the tokens, run GREEN, run the theme and architecture guards.
- [ ] Commit `feat(ZOD-UI-005): add field tokens and the kit danger-soft halo colour`.

### Task 2: The field, RED first

Write `test/widgets/text_field_test.dart` before the widget. Each test names the property it kills.

1. Typing calls `onChanged` with the text; the field shows it (`controller.text`).
2. Default: border `line`, no halo; height exactly 40 at text scale 1; label above at 12 / 500 `text-2`.
3. Focus (tap, programmatic, Tab): border `accent` and a halo of width 3 in `accent-soft`; the halo does not change the layout size.
4. Error: border `danger`, halo `danger-soft`, the message row exists with the `alert` icon and the exact text; error plus focus keeps the danger colours.
5. `errorText: ''` asserts; `errorText` with `enabled: false` asserts.
6. Disabled: box opacity 0.45, label at full strength, not focusable, a tap does not focus, `enterText` finds no editable, semantics `enabled: false`.
7. Tapping the label focuses the field.
8. Placeholder shows only while empty, in `text-3`; leading icon is 16 px `text-3`, absent when null.
9. **NFR-R2 without a crash:** a harness validates `dd/MM/yyyy` (test-local parser) and sets `errorText` on `abc`; assert the error message and state appear. A fuzz list (empty, 10 000 characters, RTL and LTR marks, emoji, `\u0000`, newline paste, surrogate halves) goes through `enterText` and a formatter without an exception.
10. `inputFormatters` and `keyboardType` reach the `EditableText`; `onSubmitted` fires on the action key.
11. Text scale 2.0: height grows past 40, the text is not clipped (`didExceedMaxLines` and render-box checks), the message wraps.
12. RTL layout: label, icon and error row mirror; with `ltr: true` the value is LTR and sits at the physical left of its box; the digits use tabular figures; without `ltr` the value follows the app direction.
13. Semantics: text-field flag, label, hint, `focused`, enabled; in error the message is in the node and the row is a live region; the icons are excluded.
14. Lifecycle: an owned controller and node are disposed with the widget; supplied ones are not; swapping the controller, the node or `enabled` in `didUpdateWidget` keeps the text, moves the listeners and drops focus when disabled.
15. Dark and light: each colour above comes from the theme's `ZodiannSurfaces` in both.

- [ ] Run RED and confirm each test fails because the widget does not exist (and, after a stub, for the expected behavioural reason).
- [ ] Implement `ZodiannTextField` (shell painter for border and halo, `EditableText`, label gesture, error row, semantics) with the minimum code; run GREEN.
- [ ] Commit `feat(ZOD-UI-005): add the text field component`.

### Task 3: Fidelity to the component sheet (both themes)

- [ ] `test/support/field_features.dart`: measure on the sheet crop and on a Flutter render, the same way `segment_features.dart` does: the input box (left, top, height, border pixel, fill), the halo band colour 1 to 2 px outside the box, the ink box of the label, value and icon, and the message row's ink. The sheet stretches the field to its grid column, so only left, top and height are compared, never the right edge.
- [ ] `test/widgets/text_field_sheet_test.dart` renders the five sheet fields (Anchor, Anchor focused, Cells in error, Cells disabled; the Body select is not built, O3) with the sheet's strings and compares both themes. Tolerances are measured and justified in the test, as in UI-006.

### Task 4: Mutation proof

- [ ] List and run mutants, each caught by a named test: halo drawn inside (layout grows), halo colour `accent` in error, `line` border in error, error without the message row, message without the icon, disabled opacity 0.42, label dimmed when disabled, 39 or 41 px height, no label tap, `ltr` ignored, icon colour `text-2`, placeholder in `text`, focus on a disabled field, owned controller not disposed, supplied controller disposed. Record the result table in the plan's execution notes.

### Task 5: Verification, review, documentation

- [ ] Run, from the root, `fvm dart run melos run lint` and `fvm dart run melos run test`, and the package's own tests; record commands, counts and the head commit.
- [ ] Device check (Android, only if a device or emulator is authorized): touch typing, the selection toolbar and handles in English and Hebrew, the keyboard type for numbers and dates, the halo look. If not run, say so.
- [ ] Whole-branch review by a fresh reviewer (`requesting-code-review`); fix every Important finding test-first.
- [ ] After verification: task file status and criteria, `docs/development/TASKS.md`, `docs/PROGRESS.md` (plan path, decisions, verification), then commit, push and open the PR per the workflow.

## Acceptance criteria mapping

| Criterion | Proven by |
|---|---|
| 1. Default, focus, error and disabled match the sheet | Task 3 (both themes), tests 2, 3, 4, 6, 15 |
| 2. The error state always renders a message, never colour alone | tests 4 and 5 (the empty string asserts), semantics test 13, mutants "error without message" and "message without icon" |
| 3. Invalid input triggers the error state, not a crash | test 9 (parser harness and fuzz) |

## Execution mode

Sequential, in this session (`executing-plans`). No independent parallel work: one widget and its tokens, tasks depend on each other.

## Risks

- **Kit-only token (O1).** `dangerSoft` is not in MASTER, so the master-values test must not see it; it has its own pin against `kit.css`.
- **`EditableText` is lower level than a Material field.** The platform text-selection controls, the context menu labels (Material localizations, English and Hebrew) and the spell-check and suggestion defaults have to be set deliberately; a numeric or date field should not offer suggestions. Test 12 and Task 5's device check cover it; if the toolbar cannot be verified, the PR says so.
- **Halo painting outside the box.** The halo must not change layout or be clipped by a parent; a parent that clips (a panel with `clipBehavior`) hides it. `ZodiannPanel` does not clip by default (UI-014 O2). Test 3 pins the layout and a test places the field in a panel.
- **Hit box.** The drawn input is 40 px high (design) while MASTER §14 asks for 44; the label-plus-input hit area covers it (test 7), and the 40 px input alone does not.
- **Tolerance of pixel proof.** Text anti-aliasing differs between Chrome and Flutter (see UI-006's tolerances); ink boxes are compared with measured, justified tolerances.

## Open decisions (for the owner; defaults are implemented)

- **O1: the error halo colour.** kit.css defines `danger-soft` (12 % dark, 8 % light) that MASTER §2.1 omits. Default: add a `dangerSoft` field to the theme extension from kit.css, outside MASTER's token map, pinned against kit.css; MASTER is not edited (the same approach as UI-006's O3). Alternative: derive the halo from `danger` with an alpha in code (no new token, but the alpha would be a magic number per theme).
- **O2: validation API.** Default: no validator and no parser in the component; the caller passes `errorText` (so the language of the message and the rules stay with SQR, WHL and SET). Alternative: a built-in `validator` callback that runs on change.
- **O3: the select field.** Default: not built here (the task is text, date and number entry); the screen that needs a select (the Body filter) gets it with its own task or a follow-up. Alternative: add a `ZodiannSelectField` shell with the chevron now.
- **O4: disabled opacity.** Default: 0.45 as MASTER §10 and kit.css say, as a new `fieldDisabledOpacity` token, not the 0.42 of buttons.
- **O5: label tap.** Default: a tap on the label focuses the field. Alternative: the label is plain text.

## Review Focus

The behaviours the tests do not obviously reach: a `controller` swapped while focused; `enabled` flipping to false while the keyboard is open; `errorText` changing between non-null values (live region announcement); an RTL layout with `ltr: true` and a long value; a message that wraps under a large text scale next to a halo; the field inside `ZodiannPanel` and inside a scrolling parent (halo clipping); and the platform text-selection toolbar in Hebrew.

## Plan review

_Pending: `plan-reviewer`, round 1._
