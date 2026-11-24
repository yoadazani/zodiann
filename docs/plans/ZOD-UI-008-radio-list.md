# ZOD-UI-008 Radio List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (sequential, native; see "Execution mode"). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build `ZodiannRadioList<T>` in `shared_ui`: a single-selection list of rows, each a round dot, a label and an optional trailing badge ("Recommended", "Backup"), matching the "Ephemeris source" block of the settings screens, with full keyboard support (Tab enters the group once, arrow keys move the selection).

**Architecture:** One widget file in `packages/shared_ui/lib/src/widgets/`, built on `ZodiannPressable` per row (hover, press, keyboard focus ring, Enter / Space / tap, 44 px slot, disabled inertness). `ZodiannPressable` already has `checked`, `inMutuallyExclusiveGroup`, `focusNode` and `semanticHint`, so **no pressable change is needed**. Colours from `ZodiannSurfaces`, text from `ZodiannTextStyles` via `copyWith`, geometry from new `ZodiannSize` tokens, motion from `ZodiannStates.selectionDuration`. Roving tab stop plus arrow-key selection is implemented in the widget (the ARIA radio-group pattern). Fidelity is proved against the three settings screens (`04-settings_desktop_{en_dark,he_dark,he_light}.png`) with the feature-extractor method of UI-006 / UI-007.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_ui` theme extensions, PNG feature extraction (`test/support/` helpers).

**Task:** `docs/development/shared-ui-design-system/ZOD-UI-008-implement-the-radio-list-component-ephemeris-source-selector.md`. **Design:** `design-reference/zodiann/MASTER.md` §9 "Settings" (long controls such as ephemeris radios stack below the label), §10 "Others" (radio list for the ephemeris source), §12 (120 ms selection crossfade, reduced motion instant), §14 (touch targets at least 44, at least 8 between targets); `_source/settings.html:21-25` and `:71` (the `.radio` rules and the exact markup); `screens/04-settings_desktop_{en_dark,he_dark,he_light}.png`; NFR-X2.

## Facts established while planning (2026-11-24)

- **Source CSS (`settings.html`):** `.radio` is a grid with `gap: 2px`. Each `label` is a flex row, `gap: var(--s3)` (12), `align-items: center`, `padding: 8px 0`. `.dot` is 18 × 18, round, `1.5px solid var(--line)`; the selected row's dot has `5px solid var(--accent)` (an 8 px hole showing the panel fill; no inner disc). `small` (the badge) is `text-3`, `font-size: var(--fs-xs)` (12), `margin-inline-start: auto`. The label text is the body default (14 px, line-height 1.45, weight 400, `text`). The kit defines no hover, focus or transition for it. Copy in the mock: "Swiss Ephemeris, data files" + "Recommended", "Swiss Ephemeris, built-in (Moshier)" (no badge), "astronomy-engine" + "Backup" (Hebrew: מומלץ / גיבוי).
- **Measured on the English settings screen (1440 px wide, 1×, by eye; exact numbers come from Task 4):** dot centres at y 716, 754, 793 (row pitch about 38.3 = 20.3 line + 16 padding + 2 gap); dot spans x 751 to 769; label starts at x 781 (gap 12 confirmed); badge ends at the panel's inner edge x 1265. **In Hebrew** the dot sits at the right edge, the label right-aligned beside it, the badge at the left edge; the label's comma and the parenthesised "(Moshier)" keep the bidi order the browser gave them (the label is plain text in the line's direction).
- **The component sheet has no radio list.** MASTER §10 and the task file say the "Others" row shows it, but `components_{dark,light}.png` shows only the switch, stepper and chips there. The settings screens are therefore the only visual source; there is no light English screen, so the light theme is proved against `04-settings_desktop_he_light.png`. Recorded, not blocking; the task file's design reference is not edited.
- **The mock's row pitch (about 38) is below the 44 px touch target** MASTER §14 requires, and the 2 px gap is below the 8 px it asks for. Owner decision O1.
- **Existing building blocks:** `ZodiannPressable` (button node, `checked`, `inMutuallyExclusiveGroup`, `semanticHint`, `focusNode`, `autofocus`, 44 × 44 minimum slot, stretches to a tight width); `ZodiannSegmentedControl` (keyboard precedent: one tab stop per enabled segment, `_SideAction`, Flutter 3.50 `Actions.maybeFind` behaviour); `ZodiannSwitch` (120 ms animation precedent, reduced motion); tokens `ZodiannSize.minTouchTarget`, `hairline`, `ZodiannSpace`, `ZodiannStates.selectionDuration` / `disabledOpacity`, `ZodiannSurfaces` (`line`, `accent`, `text`, `text3`).
- **Consumers (later tasks):** ZOD-SET-006 (ephemeris source: data files / Moshier / astronomy-engine, wired to EPH-002 / 003 / 004 by DI). ZOD-UI-015 (visual regression harness) waits on this task. The component takes generic `T` values and knows nothing about ephemerides.
- **Arrow keys select, they do not only move focus** (criterion 2: "arrow keys move selection"). This differs from the segmented control (focus only, Space / Enter selects) on purpose: it is the radio-group pattern.

## Product-owner decisions

None yet. O1 to O7 at the end carry defaults that are implemented unless the owner changes them. O1 (row height) is the one that changes what is drawn.

## Design (API)

```dart
final class ZodiannRadioOption<T> {
  const ZodiannRadioOption({required this.value, required this.label, this.badge});
  final T value;
  final String label;      // localized by the caller; wraps, never ellipsizes
  final String? badge;     // "Recommended", "Backup"; localized by the caller
}

class ZodiannRadioList<T> extends StatefulWidget {
  const ZodiannRadioList({super.key, required this.options, required this.value,
      required this.onChanged, required this.semanticLabel, this.autofocus = false});
  final List<ZodiannRadioOption<T>> options; // asserts: not empty, values unique, labels not blank
  final T? value;                            // null = nothing selected; else must be one of the options (assert)
  final ValueChanged<T>? onChanged;          // null disables the whole list (0.42, inert, not focusable)
  final String semanticLabel;                // the group's name, e.g. "Ephemeris source"
}
```

- **Row (drawn):** `Row` in the inline direction: dot (18, `Border.all`, round) · 12 · label (`Expanded`-style, wraps, 14 px `body` role, `text`) · 12 minimum · badge (12 px, `text-3`, trailing, never wraps its own line away from the row: it takes its natural width, and the label gets the rest). Vertical padding 8 around the content, as the kit. Dot colours: off `line` border at 1.5; on `accent` border at 5. `BoxBorder` interpolates between the two widths and colours, so the 120 ms crossfade is one `AnimatedContainer` (`Curves.linear`; `Duration.zero` under `MediaQuery.disableAnimationsOf`).
- **Layout and hit slot:** each row is a `ZodiannPressable`, so its slot is at least 44 high and as wide as the list (tight width: the rows stack in a `Column` with `crossAxisAlignment: stretch`). Per O1 the list has no extra gap between rows; the drawn row (about 36.3 at 14 px) sits centred in its 44 slot. A row grows with the text scale and with a wrapped label.
- **Behaviour:** tap, mouse click, Enter, Space on a row call `onChanged(option.value)` once. Activating the already selected row does nothing (no call). A controlled parent updates `value`; the widget keeps no selection state of its own.
- **Keyboard (roving tab stop, NFR-X2):** exactly one row is in the Tab order: the selected row, or the first row when `value` is null. Tab enters the group at that row and the next Tab leaves it. **Down and Right** select and focus the next row, **Up and Left** the previous one; in RTL, Left and Right swap (Left is next). Selection wraps at the ends (O2). Each arrow press calls `onChanged` with the new value and moves focus to that row. Home and End are not handled (not in the criterion). Mechanism: one `FocusNode` per row, owned by the state; a row's node has `canRequestFocus` true when it is the tab stop or currently focused; the arrow handler makes the target requestable, requests focus, then calls `onChanged` (so a controlled parent rejecting the change leaves the tab stop on the selected row, and focus returns to it on the next Tab). Arrow handling is an `Actions` entry for `DirectionalFocusIntent` above the rows, following the segmented control's `_SideAction`, except that all four directions are consumed inside the group only while a row has focus; a key pressed with no row focused falls through to the enclosing handler.
- **Semantics:** one group node (`container`, `explicitChildNodes`, label `semanticLabel`) with one node per row: button role, label = the option's label, `checked` = selected, `inMutuallyExclusiveGroup: true` (Flutter exposes this combination as a radio button on Android and iOS), `semanticHint` = the badge text when present (read after the label, no hard-coded separator). The dot and the visible badge text are excluded from the tree (the pressable already excludes its subtree). Disabled rows report `enabled: false`.
- **Disabled:** `onChanged: null` disables all rows (0.42, inert by tap, key, focus traversal, `forbidden` cursor); the selected row keeps its on look at the lower opacity.
- **Directionality:** `Row` and `AlignmentDirectional` only, no mirroring `Transform`. The dot never mirrors (it is round). Badge and label follow the inline direction (the Hebrew screen).
- **Text scale:** the label grows and wraps; the badge grows; rows grow; no clipping or overflow at 2x. The dot stays 18.

## Global Constraints

- No new dependency, no pubspec change; `no_network_test.dart` unchanged and green.
- Sizes only from `ZodiannSize` / `ZodiannSpace` tokens (UI-003 magic-number guard), colours only from the theme extensions (ARCH-7 guard), text styles via `copyWith` of a `ZodiannTextStyles` role, no string literals in `Text`.
- `ZodiannPressable` is **not modified**; every existing consumer is untouched.
- Sentence case (no `toUpperCase(`).
- Staging: explicit paths per commit; never `git add -A` / `.` / `commit -a`. `.fvmrc` and `grep.exe.stackdump` stay unstaged.
- Commands: `fvm flutter test <file>` from `packages/shared_ui` (tests read `../../design-reference/...`); **root** `fvm dart run melos run lint` / `test`; `fvm dart test test/architecture` for architecture tests. Use the Write tool for files with apostrophes.
- Naming: project prefix `Zodiann`.

## Out of scope

- The Settings screen, its strings, the three ephemeris options, persistence and DI (ZOD-SET-006, EPH-002 / 003 / 004).
- Per-option disabling (an option that is unavailable), option descriptions or sub-labels, a horizontal layout, a checkbox group, Home / End keys, type-ahead (O6).
- Updating the design reference; a radio-list entry in the component sheet.

## File structure

| File | Action |
|---|---|
| `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart` | add `radioDot` (18), `radioDotBorder` (1.5), `radioDotSelectedBorder` (5), `radioRowPadding` (8) |
| `packages/shared_ui/lib/src/widgets/zodiann_radio_list.dart` | new (`ZodiannRadioOption<T>`, `ZodiannRadioList<T>`) |
| `packages/shared_ui/lib/shared_ui.dart` | export the new file |
| `test/theme/dimensions_test.dart` | pin the new size tokens against `settings.html` |
| `test/widgets/radio_list_test.dart` | new: behaviour, keyboard, semantics, layout, RTL, text scale, motion |
| `test/support/radio_features.dart`, `test/widgets/radio_sheet_test.dart` | new: fidelity to the settings screens, both themes and both languages |
| task file, `docs/development/TASKS.md`, `docs/PROGRESS.md` | status and records after verification |

## Tasks

Commands run from `packages/shared_ui` unless marked **root**.

### Task 1: Tokens (TDD)

- [ ] **Step 1 (RED):** in `dimensions_test.dart` pin `radioDot 18`, `radioDotBorder 1.5`, `radioDotSelectedBorder 5`, `radioRowPadding 8`, and extend the kit.css cross-check there to read `settings.html` `.radio .dot` and `.radio label`. Expected: compile errors `Member not found`.
- [ ] **Step 2 (GREEN):** add the constants with doc comments citing `settings.html` lines. Run: pass. **Root:** `fvm dart test test/architecture/no_magic_dimensions_test.dart`.
- [ ] **Step 3:** commit `feat(ZOD-UI-008): add the radio list tokens`.

### Task 2: Selection, keyboard and semantics, RED first

- [ ] **Step 1 (RED), `test/widgets/radio_list_test.dart`** against an empty stub (assertion failures, not compile errors):
  1. Tap, mouse click, Enter and Space on an unselected row call `onChanged(value)` once; on the selected row they call nothing; a controlled rebuild moves the dot.
  2. Roving tab stop: with a selection, Tab from before the group focuses the selected row, the next Tab leaves the group (focus lands on a probe after it), Shift+Tab re-enters at the selected row; with `value: null` Tab enters at the first row.
  3. Arrow keys (LTR): Down and Right select and focus the next row, Up and Left the previous; the callback receives each value once per press; wrap from last to first and first to last; Home, End and other keys do nothing.
  4. Arrow keys (RTL): Left is next, Right is previous; Up and Down unchanged.
  5. A parent that ignores `onChanged`: focus moves to the pressed row's neighbour, the selection stays, Tab from there leaves the group and Shift+Tab returns to the selected row (the roving stop did not move).
  6. A key with no row focused falls through to an enclosing `Actions` handler (the segmented control's outer-handler precedent); with a row focused, an outer handler does not see the four directions.
  7. Semantics: one group node labelled `semanticLabel`; per row a node with the option label, `isChecked` / unchecked, `inMutuallyExclusiveGroup`, a hint equal to the badge when present and none otherwise; no node for the dot or the badge text.
  8. Disabled (`onChanged: null`): all rows `enabled: false`, 0.42 opacity, inert by tap, Enter, Space and arrows, not in the Tab order, cursor `forbidden`; the selected row keeps its on look.
  9. Asserts: empty options, duplicate values, blank label, `value` not among the options.
  10. Focus ring appears for keyboard focus only (pinned like the UI-006 / UI-007 tests); `autofocus` focuses the tab-stop row.
- [ ] **Step 2 (GREEN):** implement `zodiann_radio_list.dart` (state, focus nodes, `Actions`, semantics); run: pass.
- [ ] **Step 3:** doc comments (roving stop, arrows select, wrap); commit `feat(ZOD-UI-008): add ZodiannRadioList`.

### Task 3: Layout, motion and theming, RED first

- [ ] **Step 1 (RED), same file:**
  1. Geometry (LTR, Graphite): dot 18 × 18 round; off border 1.5 `line`, on border 5 `accent` with an 8 px hole; label starts 12 after the dot; badge ends at the list's end edge; each row slot is at least 44 high and full width; a tap 2 px above and below the drawn row still hits its own row and does not hit the neighbour's.
  2. Colours both themes from tokens: label `text`, badge `text-3`, dot per state.
  3. RTL (Hebrew): dot at the right edge, badge at the left, offsets equal the mirrored LTR offsets; a label with a comma and parentheses is laid out as plain text in the line's direction.
  4. Long label wraps onto a second line, the row grows, the badge stays on the first line's baseline side without clipping; a row with a badge and a very narrow parent gives the label the leftover width, no overflow.
  5. Text scale 2: rows grow, nothing clips or overflows, the dot stays 18.
  6. Motion: after the selection changes the dot border is mid-way at 60 ms and final at 120 ms (`Curves.linear`); instant under `disableAnimations`; the off dot's endpoint colour is a real colour with alpha, not `Colors.transparent` (UI-006 lesson).
  7. Live theme switch (no stale colours).
- [ ] **Step 2 (GREEN):** finish the drawn row; run: pass.
- [ ] **Step 3:** commit `feat(ZOD-UI-008): draw the radio rows as the settings screen does`.

### Task 4: Fidelity to the settings screens

- [ ] **Step 1:** measure the "Ephemeris source" block on `04-settings_desktop_en_dark.png`, `_he_dark.png` and `_he_light.png`: for each row the dot box (left, top, size), the border colours (1.5 px ring off, 5 px ring on, hole colour), the label ink box, the badge ink box and colour, and the row pitch. Record the numbers in the test header and in `test/fixtures/radio/README.md` (UI-006 precedent), together with Chrome's actual text widths. The mock's vertical pitch (about 38.3) is **recorded, not matched**: per O1 the widget's rows are 44 apart; vertical positions are compared relative to each row's own centre.
- [ ] **Step 2 (RED then GREEN):** `test/support/radio_features.dart` extracts the features from the PNGs and from a widget render placed at an integer origin in a panel of the screen's width; `radio_sheet_test.dart` compares, in Graphite (English and Hebrew) and Porcelain (Hebrew): dot box and ring colours (±1 per channel), horizontal position of dot, label start and badge end (±1 px), label and badge ink colours and ink height (±3 per UI-007's text rule), each row's ink vertical centre against the row centre. The first run exposes token mismatches (RED); fix the widget, not the tolerance.
- [ ] **Step 3:** commit `test(ZOD-UI-008): compare the radio list with the settings screens`.

### Task 5: Mutation proof

- [ ] **Step 1:** throw-away edits, each reverted, each named, each must fail a test: R1 selected border 4; R2 off border 2; R3 selected dot colour `accentSoft`; R4 no 120 ms animation; R5 arrows move focus only (no `onChanged`); R6 no wrap-around; R7 Left and Right not swapped in RTL; R8 every row in the Tab order; R9 the roving stop on the first row instead of the selected one; R10 `checked` dropped; R11 `inMutuallyExclusiveGroup` dropped; R12 badge not exposed as the hint; R13 tapping the selected row calls `onChanged`; R14 disabled list still reacts to arrows; R15 label ellipsized instead of wrapped; R16 badge colour `text2`; R17 gap 8 instead of 12; R18 row slot below 44; R19 `Colors.transparent` endpoint; R20 arrow keys leak to an outer handler while a row has focus.
- [ ] **Step 2:** no commit unless a mutant survives (then add the killing test first). Record the catching tests in PROGRESS Verification.

### Task 6: Verification, review, documentation

- [ ] **Step 1 (root):** `fvm dart run melos run lint`, `fvm dart run melos run test`, `fvm dart test test/architecture`. Record exit codes and counts.
- [ ] **Step 2:** `requesting-code-review`: one fresh-reviewer pass over the whole branch; fix Important findings test-first.
- [ ] **Step 3:** `verification-before-completion`; update the task file (status, ticked criteria with evidence), `TASKS.md`, `PROGRESS.md` (plan path, decisions, verification with commands and head commit, git state; the Current Task header still describes UI-007 as an open PR although it merged as `aae9176`); push, open the PR, add the PR link in a follow-up commit.

## Acceptance criteria mapping

| Criterion | Proof |
|---|---|
| 1. Renders and behaves per the settings screenshot (single selection, trailing badges) | Task 4 (English dark, Hebrew dark, Hebrew light; dot, ring colours, label, badge); Task 3 tests 1 to 3; Task 2 tests 1 and 8; mutants R1 to R3, R13, R16, R17 |
| 2. Keyboard-navigable, arrow keys move selection (NFR-X2) | Task 2 tests 2 to 6 (roving stop, all four arrows, RTL, wrap, rejected change, outer handler); mutants R5 to R9, R14, R20; semantics test 7 and mutants R10 to R12 for the screen-reader half of NFR-X2 |

## Execution mode

Sequential, native. One new widget, one token edit, one export and one test file set; there is **no independent work** worth a subagent.

## Risks

- **Row pitch against the mock (O1):** at 44 px rows the Ephemeris block grows by about 17 px (three rows, 44 against about 38.3), a visible deviation from the mock that follows MASTER §14. The pixel test compares positions relative to each row, not the absolute pitch. If the owner prefers the mock's pitch, the hit slot would fall under 44 and the §14 rule is knowingly broken for these rows.
- **Roving tab stop under a controlled parent:** the target row is made requestable and focused before `onChanged` runs; Flutter's focus scope must accept a node whose `canRequestFocus` flips in the same frame. A probe in Task 2 step 1 (test 5) proves it; if it fails the fallback is a `FocusTraversalGroup` policy that filters descendants to the tab stop.
- **Arrow keys and ancestors:** Flutter 3.50 resolves `Actions.maybeFind` to the nearest action even when disabled (UI-006 finding), so the widget must consume the four directions itself while a row has focus; test 6 pins both sides.
- **Radio role wording:** `checked` plus `inMutuallyExclusiveGroup` should read as "radio button, selected" on TalkBack and VoiceOver; wording needs a device and is not verified here (recorded as not done).
- **Hover is a brightness filter** on the whole row, including text, as for every `ZodiannPressable`; the kit defines no radio hover.
- **No radio sheet exists:** fidelity rests on three screenshots of one block; the light theme only through the Hebrew light screen.

## Open decisions (for the owner; defaults are implemented)

- **O1: row height.** Default: each row is a 44 px touch target with no extra gap (MASTER §14), so rows are 44 apart where the mock shows about 38. Alternative: the mock's pitch (about 38.3, 2 px gap), which breaks the 44 px rule for these rows.
- **O2: arrow keys at the ends.** Default: selection wraps (ARIA radio group). Alternative: stop at the first and last row.
- **O3: focus ring.** Default: the keyboard ring surrounds the whole row (the hit target), radius 8. Alternative: a ring around the dot only.
- **O4: motion.** Default: 120 ms linear crossfade of the dot's border (MASTER §12), instant under reduced motion; the kit has none. Alternative: instant.
- **O5: badge for screen readers.** Default: the badge is the row's semantic hint, read after the label. Alternative: not announced (it would stay visual only).
- **O6: scope.** Default: no per-option disabling and no option sub-labels; `value` may be null. Alternative: add `enabled` per option now (needs the roving stop to skip disabled rows).
- **O7: long labels.** Default: labels wrap and the row grows (the Hebrew "Swiss Ephemeris, built-in (Moshier)" on a phone). Alternative: ellipsize on one line.

## Review Focus

Roving tab stop and focus when the parent rejects a change; RTL arrow direction against the Hebrew screen; whether the list works inside `ZodiannPanel` (`stack` row) at phone width; arrow keys while a row inside a scrolling parent is focused (scroll into view); the radio semantics flags; the O1 vertical deviation against the pixel test.
