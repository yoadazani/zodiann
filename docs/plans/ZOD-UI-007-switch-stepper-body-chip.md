# ZOD-UI-007 Switch, Orb Stepper and Body Chip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (sequential, native; see "Execution mode"). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build three small selection controls in `shared_ui`: `ZodiannSwitch` (40 × 24), `ZodiannOrbStepper` (36 high, `− value +`, min / max bounds) and `ZodiannBodyChip` (pill, `accent-soft` fill and `accent-line` border when on), each matching the component sheet's "Others" row in both themes.

**Architecture:** Three small widgets in `packages/shared_ui/lib/src/widgets/`, each built on `ZodiannPressable` (hover, press, keyboard focus ring, Enter / Space / tap, disabled inertness, 44 × 44 hit slot). Colours from `ZodiannSurfaces` / `BodyColors`, text from `ZodiannTextStyles` via `copyWith`, glyphs from `ZodiannGlyphs`, geometry from new `ZodiannSize` tokens, motion from the existing `ZodiannStates.selectionDuration` (120 ms, MASTER §12). Four additive `ZodiannPressable` parameters whose defaults reproduce today's behaviour: `toggled`, `checked` (semantics), `slotAlignment` (default centre) and `focusRingRadius` (default `ZodiannRadius.md`). Fidelity is proved against `components_{dark,light}.png` with a feature extractor (UI-006 / UI-009 method).

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_ui` theme extensions, PNG feature extraction (`test/support/tag_features.dart` helpers).

**Task:** `docs/development/shared-ui-design-system/ZOD-UI-007-implement-switch-stepper-and-body-chip-components.md`. **Design:** `design-reference/zodiann/MASTER.md` §4 (Switch 40 × 24, Orb stepper 36 high), §10 "Others", §12 (120 ms selection crossfade; reduced motion = instant), §14 (44 px touch target); `_source/kit.css:237-251` (`.stepper`, `.switch`, `.chk`); `_source/components.html:117-119` (the sheet row); `_source/settings.html:42-43` (orb steppers in context); `components/components_{dark,light}.png`, `screens/04-settings_desktop_en_dark.png`.

## Facts established while planning (2026-11-24)

- **kit.css `.switch`:** 40 × 24, radius 12, `surface-3` fill, 1 px `line` border; a 16 px circle `text-3` at 3 px inside the border (`top: 3px; inset-inline-start: 3px`, so 4 px from the outer edge). `.on`: `accent` fill and border, thumb moves to `inset-inline-start: 19px` (20 px from the outer edge, 4 px from the far side) and is `on-accent`. No transition in kit.css; MASTER §12 says selection changes are a 120 ms crossfade, so the thumb and colours animate over 120 ms (instant under reduced motion). Thumb position follows the inline direction (mirrors in RTL).
- **kit.css `.stepper`:** inline-flex, 36 high, 1 px `line` border, radius 8, `bg-raised`. Buttons: 34 wide, full height, transparent, `text-2`, 18 px glyph (`−` U+2212 and `+`). Value: `min-width: 52`, centred, weight 500, `num` (tabular figures), text like `±8°`. Drawn width with a short value: 1 + 34 + 52 + 34 + 1 = 122. Row order follows the inline direction.
- **kit.css `.chk`:** inline-flex, 34 high, `padding-inline: 10px 12px`, gap 8, pill radius, 1 px `line` border, 13 px (`fs-sm`); glyph 15 px in the body's colour (`BodyColors`). `.on`: `accent-line` border and `accent-soft` fill. Sheet shows five chips (Sun, Moon, Mercury, Venus on; Mean node off). No check mark in the reference.
- **Existing tokens:** `ZodiannSize.minTouchTarget` 44, `hairline` 1, `ZodiannSpace`, `ZodiannRadius.control` (8) and `chip` (pill), `ZodiannStates.selectionDuration`, `disabledOpacity`, `ZodiannSurfaces` (`surface3`, `line`, `accent`, `accentSoft`, `accentLine`, `onAccent`, `text2`, `text3`, `bgRaised`), `BodyColors.of(Body)`, `ZodiannGlyphs.body(Body)`, `ZodiannTextStyles.small` / `body` / `glyph`. **Already existing (UI-003, pinned against kit.css in `dimensions_test`):** `ZodiannSize.switchWidth` (40), `switchHeight` (24), `stepper` (36); the switch radius 12 is `ZodiannRadius.lg`. **Missing:** switch thumb / inset, stepper button width / value min width, chip height / paddings / gap / glyph size.
- **`ZodiannPressable`** has `selected`, `inMutuallyExclusiveGroup`, `disabledOpacity`, `focusRing` (UI-006) but no `toggled` (switch role) or `checked` (checkbox role). It always centres its drawn child in the 44 × 44 slot (`_RenderTouchTarget`) and its focus ring is a fixed `ZodiannRadius.md` (8) rounded rectangle around the drawn child (`ZodiannFocusRingPainter`). Every `ZodiannTextStyles` role already sets tabular figures.
- **Orb bounds are undecided:** D-1 (are orbs editable at all) is open (TASKS §6; ZOD-ASP-002, D18). The component therefore takes `min` / `max` as parameters with no built-in default; it never decides a bound. The sheet and settings screen show 8, 4, 6, 6, 8 degrees, whole numbers with `±` and `°`.
- **Consumers (later tasks):** Reduced-motion override switch (ZOD-SET-003 area), orb steppers (ZOD-SET-006, ZOD-ASP-002), "Visible bodies" chips (ZOD-SET-006). The "degree-table body filter styling cues" wording in the task file has no filter in the design; this task only provides the chip, WHL-018 / WHL-021 decide their use.

## Product-owner decisions

**O1 (owner, 2026-11-24): sheet-exact chips, no check icon;** accessibility rests on `checked` semantics, the tint and border change and the focus ring, and the faint contrast is recorded for ZOD-NFR-008. The remaining open items (O2 to O7) are listed at the end; their defaults are implemented unless the owner changes them.

## Design (API)

```dart
class ZodiannSwitch extends StatelessWidget {
  const ZodiannSwitch({super.key, required this.value, required this.onChanged,
      required this.semanticLabel, this.focusNode, this.autofocus = false});
  final bool value;
  final ValueChanged<bool>? onChanged;   // null disables (0.42 opacity, inert)
  final String semanticLabel;            // localized by the caller
}

class ZodiannOrbStepper extends StatelessWidget {
  const ZodiannOrbStepper({super.key, required this.value, required this.min,
      required this.max, required this.onChanged, required this.valueLabel,
      required this.decrementLabel, required this.incrementLabel,
      this.step = 1, this.semanticLabel});
  final double value, min, max, step;    // asserts: min <= value <= max, step > 0, min < max
  final ValueChanged<double>? onChanged; // null disables both buttons
  final String valueLabel;               // "±8°", formatted and localized by the caller
  final String decrementLabel, incrementLabel;
}

class ZodiannBodyChip extends StatelessWidget {
  const ZodiannBodyChip({super.key, required this.body, required this.label,
      required this.selected, required this.onChanged, this.focusNode});
  final Body body;                       // glyph and colour come from the theme
  final String label;                    // localized body name
  final bool selected;
  final ValueChanged<bool>? onChanged;   // called with the new state; null disables
}
```

- **Switch:** drawn 40 × 24 (see Facts), centred in the pressable's 44 × 44 slot. `Semantics(toggled: value)` plus the pressable's button node; tap, Enter, Space call `onChanged(!value)`. Thumb and fills crossfade over 120 ms, `Curves.linear` (`AnimatedContainer` / `AnimatedAlign` with `AlignmentDirectional`, so RTL mirrors without a `Transform`); `Duration.zero` when `MediaQuery.disableAnimationsOf`.
- **Stepper:** drawn box per Facts, in a 44 high layout. The two buttons are `ZodiannPressable`s whose 44 × 44 slots sit at the two ends of the stepper's bounds (0..44 and 78..122, overlapping the non-interactive value area by 10 px each) with `slotAlignment: AlignmentDirectional.centerStart` / `centerEnd`, so the drawn 34 × 36 glyph area (inside the 1 px border) sits against the outer edge where kit.css puts it (glyph centre 18 px from the edge, not 22). Their focus ring uses `focusRingRadius` 8 around the 34 × 36 area. A bound disables only its own button (0.42 opacity, inert, not focusable). `onChanged` receives `(value ± step).clamp(min, max)`; at a bound it is not called. A `value` outside `[min, max]` trips an assert in debug; in release the buttons enable by the clamped value (so a stale value never enables a button that would step past a bound) and a rebuild never calls `onChanged`. Value text: `body` role via `copyWith(fontWeight: w500)`, tabular figures, centred in a 52 min-width box inside a forced-LTR island (L-7: `±8°` reads the same in Hebrew), `ExcludeSemantics` below the group node. Row order follows `Directionality` (O3). No long-press repeat (not in the design).
  - **Semantics:** a group node (`explicitChildNodes`, label `semanticLabel`, `value` = `valueLabel`, `increasedValue` / `decreasedValue` omitted) with two button children labelled `decrementLabel` / `incrementLabel`; screen-reader increase and decrease actions on the group call the same callbacks.
  - **Floating-point:** `value ± step` is rounded to the number of decimals of `step` before clamping, so 0.1 steps do not drift.
- **Body chip:** drawn per Facts in a 44 high slot; glyph is `ZodiannGlyphs.body(body)` in `BodyColors.of(body)`, 15 px, text-presentation selector included via the glyph role; label 13 px `text`. Fill, border colour crossfade over 120 ms between on (`accent-soft` / `accent-line`) and off (alpha-0 `accent-soft` / `line`; never `Colors.transparent`, UI-006 lesson). `Semantics(checked: selected)` on the button node. **Not colour alone (criterion 3):** the on state is carried by `checked` semantics, a brighter border and a tinted fill (a luminance and shape change visible without hue) and the keyboard focus ring (pill radius, via `focusRingRadius`); the sheet's design gives border-on vs border-off contrast 1.7 to 1.9:1 and fill vs `bg-raised` 1.1 to 1.2:1, well under WCAG 3:1, so this is a recorded design limitation for ZOD-NFR-008 (the colour-independence audit; the task file cites NFR-010, which is the reduced-motion audit, noted here without editing the task file); a check icon is **not** added because the sheet shows none (see O1).
- **Disabled:** `onChanged: null` disables each control at 0.42.
- **Directionality:** `Row` / `AlignmentDirectional` only; no mirroring `Transform`. Glyphs and numbers are never mirrored (icons are not used; `−` and `+` are text).
- **Text scale:** switch is fixed-size (it carries no text); stepper value and chip label grow with the text scale (the stepper and chip heights grow past 36 / 34, as tags and buttons do); no ellipsis on the value (it is short); a chip label ellipsizes on one line in a narrow parent.

## Global Constraints

- No new dependency, no pubspec change; `no_network_test.dart` unchanged and green.
- Sizes only from `ZodiannSize` / `ZodiannSpace` tokens (UI-003 magic-number guard), colours only from the theme extensions (ARCH-7 guard), text styles via `copyWith` of a `ZodiannTextStyles` role, no string literals in `Text` (the `−` / `+` glyph characters are constants in the file, not user copy).
- `ZodiannPressable`'s behaviour for its existing consumers is unchanged (four additive parameters whose defaults reproduce today's behaviour). The `−` and `+` are file constants, never passed as `Text('...')` literals (the text-literal scanner flags only direct literals).
- Sentence case (no `toUpperCase(`).
- Staging: explicit paths per commit; never `git add -A` / `.` / `commit -a`. `.fvmrc` and `grep.exe.stackdump` stay unstaged.
- Commands: `fvm flutter test <file>` from `packages/shared_ui` (tests read `../../design-reference/...`); **root** `fvm dart run melos run lint` / `test`; `fvm dart test test/architecture` for architecture tests. Use the Write tool for files with apostrophes.
- Naming: project prefix `Zodiann`.

## Out of scope

- Which screen shows which control, their strings, ranges and defaults (SET, ASP, WHL tasks); persistence and the reduced-motion setting logic (SET).
- Deciding D-1 / D18 (whether orbs are editable) and the orb min / max (ZOD-ASP-002).
- Press-and-hold repeat on the stepper, a text-entry stepper, a tri-state switch, a chip-with-check-icon variant (needs an owner decision, O1), the radio list (ZOD-UI-008), a body filter built from chips (WHL-018 / WHL-021).
- Updating the design reference.

## File structure

| File | Action |
|---|---|
| `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart` | add switch, stepper and body-chip sizes (tokens listed in Task 1) |
| `packages/shared_ui/lib/src/widgets/zodiann_pressable.dart` | add `toggled`, `checked` (`bool?`, to `Semantics`), `slotAlignment`, `focusRingRadius` |
| `packages/shared_ui/lib/src/widgets/zodiann_switch.dart` | new |
| `packages/shared_ui/lib/src/widgets/zodiann_orb_stepper.dart` | new |
| `packages/shared_ui/lib/src/widgets/zodiann_body_chip.dart` | new |
| `packages/shared_ui/lib/shared_ui.dart` | export the three |
| `test/theme/dimensions_test.dart` | pin the new size tokens |
| `test/widgets/pressable_selected_test.dart` | cover `toggled` / `checked` |
| `test/widgets/switch_test.dart`, `orb_stepper_test.dart`, `body_chip_test.dart` | new: behaviour, semantics, layout, RTL, text scale, motion |
| `test/support/others_features.dart`, `test/widgets/others_sheet_test.dart` | new: sheet fidelity, both themes |
| task file, `docs/development/TASKS.md`, `docs/PROGRESS.md` | status and records after verification |

## Tasks

Commands run from `packages/shared_ui` unless marked **root**.

### Task 1: Tokens (TDD)

- [ ] **Step 1 (RED):** in `dimensions_test.dart` pin: `switchThumb 16`, `switchThumbInset 3` (inside the 1 px border); `stepperButtonWidth 34`, `stepperValueMinWidth 52`; `bodyChipHeight 34`, `bodyChipPaddingStart 10`, `bodyChipPaddingEnd 12`, `bodyChipGap 8`, `bodyChipGlyph 15`. Extend the existing kit.css cross-check there (`.switch::after`, `.stepper button`, `.stepper .v`, `.chk`) to the new tokens; `switchWidth`, `switchHeight`, `stepper` and `ZodiannRadius.lg` already exist and are reused. Run: expected compile errors `Member not found`.
- [ ] **Step 2 (GREEN):** add the constants with doc comments citing kit.css lines. Re-run: pass. **Root:** `fvm dart test test/architecture/no_magic_dimensions_test.dart`.
- [ ] **Step 3:** commit `feat(ZOD-UI-007): add the switch, stepper and body-chip tokens`.

### Task 2: Pressable flags (TDD)

- [ ] **Step 1 (RED):** in `pressable_selected_test.dart`: `toggled: true` / `false` expose `isToggled` on / off; `checked: true` / `false` expose `isChecked` / unchecked; the defaults expose neither (existing button, icon button, segmented, drawer semantics tests unchanged); `slotAlignment: AlignmentDirectional.centerStart` puts a 34-wide child at slot x 0..34 (default stays centred); `focusRingRadius: 12` paints the ring around a 24-high child with the larger corner (pixel check), the default stays 8. Expected: compile error `No named parameter 'toggled'`.
- [ ] **Step 2 (GREEN):** add the four parameters (null / centre / md defaults) and pass them to `Semantics`, the touch-target render object and the ring painter. Run `pressable_selected_test`, `pressable_test`, `button_test`, `button_behavior_test`, `icon_button_test`, `drawer_test`, `top_bar_test`, `segmented_control_test`: pass.
- [ ] **Step 3:** commit `feat(ZOD-UI-007): extend the pressable with toggled and checked semantics`.

### Task 3: Switch, RED first

- [ ] **Step 1 (RED), `test/widgets/switch_test.dart`** against an empty stub (assertion failures, not compile errors):
  1. Tap, mouse click, Enter and Space call `onChanged(!value)` once; a controlled rebuild shows the new state.
  2. Geometry (LTR, Graphite): drawn 40 × 24, thumb 16 at 4 px from the outer edge (off) and 20 (on), vertical centre 12; layout slot 44 × 44; a tap 2 px outside the drawn track still hits.
  3. Colours both states and both themes from tokens: off `surface3` / `line` / `text3`; on `accent` / `accent` / `onAccent`.
  4. RTL: the thumb sits at the end side (right when off), mirrored offsets equal the LTR ones.
  5. Semantics: one button node with `toggled` matching `value`, labelled `semanticLabel`; disabled node `enabled: false`.
  6. Disabled (`onChanged: null`): 0.42 opacity, inert by tap, key, focus traversal; cursor `forbidden`.
  7. Motion: after changing `value` the thumb is mid-way at 60 ms and final at 120 ms (`Curves.linear`); instant under `disableAnimations`.
  8. Focus ring: keyboard-only, as the other controls (pinned like UI-006 test 17).
  9. Live theme switch (no stale colours); text scale 2 leaves the size unchanged.
- [ ] **Step 2 (GREEN):** implement `zodiann_switch.dart`; run: pass.
- [ ] **Step 3:** doc comments (hit slot, motion, no label inside); commit `feat(ZOD-UI-007): add ZodiannSwitch`.

### Task 4: Orb stepper, RED first

- [ ] **Step 1 (RED), `test/widgets/orb_stepper_test.dart`:**
  1. Plus calls `onChanged(value + step)`, minus `value − step`; the clamp at `max` and `min` (the call never exceeds the bounds); at a bound the button is inert, 0.42, not focusable, and `onChanged` is not called.
  2. Decimal step 0.5 and 0.1 do not drift (0.1 × 30 steps equals 3.0 exactly after rounding); a `value` between steps still clamps correctly.
  3. Asserts: `min >= max`, `value` outside the bounds, `step <= 0`, blank labels.
  4. Geometry (Graphite): drawn height 36, border 1, radius 8, buttons 34 wide, value box min 52; layout height 44; the `−` glyph centre and `+` glyph centre at kit.css positions (±1); drawn width 122 for a short label.
  5. Hit targets: each button's slot is 44 × 44 at 0..44 and 78..122 (tap 2 px beyond the drawn top / bottom hits; the glyph centre is 18 px from the outer edge); the value area between 44 and 78 hits nothing; the focus ring is drawn around the 34 × 36 button area, inside the border.
  6. RTL (Hebrew): button order mirrors (O3), the value text stays LTR (`±8°` not reordered), offsets equal the mirrored LTR ones; the buttons' actions do not swap (the `+` button always increments).
  7. Semantics: group node with label and `valueLabel`; two labelled buttons, a bound button disabled; increase / decrease semantic actions call the callbacks and respect the bounds.
  8. Keyboard: Tab visits the enabled buttons in logical order, Enter / Space activate; a focused `+` that reaches `max` after the rebuild is asserted exactly (node disabled, no exception, `primaryFocus` as the framework leaves it, recorded in the test).
  8b. Semantics actions: the group node's increase / decrease actions call `onChanged` with the stepped values and do nothing at the bounds.
  8c. Release path: the enable logic runs on the clamped value (unit-tested directly, since asserts cannot be skipped in a widget test); a rebuild never calls `onChanged`.
  9. Text scale 2: the box grows past 36, the value stays on one line, no overflow; tabular figures: `±8°` and `±6°` have equal width.
  10. `onChanged: null` disables both buttons; theme switch; hover and press follow `ZodiannPressable` (existing behaviour).
- [ ] **Step 2 (GREEN):** implement `zodiann_orb_stepper.dart`; run: pass.
- [ ] **Step 3:** doc comments (bounds are the caller's; D-1); commit `feat(ZOD-UI-007): add ZodiannOrbStepper`.

### Task 5: Body chip, RED first

- [ ] **Step 1 (RED), `test/widgets/body_chip_test.dart`:**
  1. Tap, mouse, Enter, Space call `onChanged(!selected)` once.
  2. Geometry: 34 high drawn, padding 10 / 12 (start / end, mirrored in RTL), glyph 15, gap 8, pill radius, border 1; layout slot 44 high.
  3. Colours: on = `accent-soft` fill and `accent-line` border, off = no fill and `line` border; glyph in `BodyColors.of(body)` for all `Body` values, both themes; label `text`.
  4. Accessibility (criterion 3): `Semantics.checked` follows `selected` (on, off), the on/off difference exists in luminance and border terms: on-border vs off-border contrast at least 1.5:1 and on-fill vs `bg-raised` at least 1.1:1 in both themes (computed 1.92 / 1.69 and 1.17 / 1.14; these measure the sheet's design, not WCAG 3:1), and the focus ring shows for keyboard focus; the label is read, the decorative glyph is excluded from semantics.
  5. Motion: fill and border crossfade 120 ms, instant under reduced motion; alpha-0 endpoint colours (a `Colors.transparent` endpoint fails the mid-point check).
  6. RTL / Hebrew: the glyph sits at the start side, padding mirrored; long label in a narrow parent ellipsizes on one line; text scale 2 grows the chip.
  7. A `Wrap` of the five sheet chips lays out within a phone width without overflow.
  8. Disabled: 0.42 opacity, inert; on and disabled together keep the on colours at the lower opacity.
- [ ] **Step 2 (GREEN):** implement `zodiann_body_chip.dart`; run: pass.
- [ ] **Step 3:** doc comments; commit `feat(ZOD-UI-007): add ZodiannBodyChip`.

### Task 6: Fidelity to the component sheet (both themes)

- [ ] **Step 1:** measure the "Others" row in `components_dark.png` and `components_light.png` (sheet is 1440 px wide, 1× from the kit's 1440 viewport; confirm from a known element): stepper box (left, top, width, height), border, fill, glyph and value ink; the two switches (box, border, fill, thumb centre and colour, both states); the five chips (box, border, fill, glyph colour and centroid, label ink). Record numbers and Chrome's fractional widths (headless Chrome on `_source/components.html`) in the test header and in `test/fixtures/others/README.md` (UI-006 precedent). Also measure the stepper on `04-settings_desktop_en_dark.png` (context check, dark only; the designer's other screens are Hebrew dark / light, use them for the RTL order O3).
- [ ] **Step 2 (RED then GREEN):** `test/support/others_features.dart` extracts the same features from the PNGs and from a widget render at an integer origin; `others_sheet_test.dart` compares each control in Graphite and Porcelain (box ±1 on width where Chrome's fractional width differs, exact top and height, fills ±1, border ±1, ink ±3). The first run exposes any token mismatch (RED); fix the widget, not the tolerance.
- [ ] **Step 3:** assert the stepper's order in Hebrew against the Hebrew settings screen (O3). Commit `test(ZOD-UI-007): compare the switch, stepper and chips with the component sheet`.

### Task 7: Mutation proof

- [ ] **Step 1:** throw-away edits, each reverted, each named, each must fail a test: S1 thumb offset 3 instead of 4 (on: 19); S2 on fill `accentSoft`; S3 thumb colour not `onAccent` when on; S4 no 120 ms animation; S5 `toggled` dropped; S6 switch ignores `onChanged: null`; T1 stepper clamp removed; T2 min bound inert but max not; T3 step rounding removed; T4 button 36 wide; T5 value min width 48; T6 value style overrides `fontFeatures` to none (roles already set tabular figures); T7 `+` and `−` swapped in RTL; T8 value text mirrored in RTL; T9 hit slot 34 wide; C1 chip border `line` when on; C2 fill `surface2` when on; C3 glyph colour not from `BodyColors`; C4 `checked` dropped; C5 `Colors.transparent` endpoint; C6 padding 12 / 10 swapped; C7 chip height 36 (assert the drawn box, not the 44 slot); P1 the `toggled` / `checked` defaults leak onto existing pressable nodes; P2 `slotAlignment` ignored (glyph at 22); P3 focus ring radius 8 on the switch and chip. Record the catching tests in PROGRESS Verification.
- [ ] **Step 2:** no commit unless a mutant survives (then add the killing test first).

### Task 8: Verification, review, documentation

- [ ] **Step 1 (root):** `fvm dart run melos run lint`, `fvm dart run melos run test`, `fvm dart test test/architecture`. Record exit codes and counts.
- [ ] **Step 2:** `requesting-code-review`: one fresh-reviewer pass over the whole branch; fix Important findings test-first.
- [ ] **Step 3:** `verification-before-completion`; update the task file (status, ticked criteria with evidence; criterion 2 is ticked as "proved for caller-supplied bounds", the real bounds stay with ZOD-ASP-002 / D-1), `TASKS.md`, `PROGRESS.md` (plan path, decisions, verification with commands and head commit, git state; fix the Current Task header, which still says UI-013 PR open although it merged as `0782719`); push, open the PR, add the PR link in a follow-up commit.

## Acceptance criteria mapping

| Criterion | Proof |
|---|---|
| 1. All three controls match the component sheet in both themes | Task 6 (sheet row, two themes, extractor on both sides); tests 2 to 3 of Tasks 3 to 5 (geometry and colours); mutants S1 to S3, T4, T5, C1 to C3, C6, C7 |
| 2. Orb stepper respects min / max bounds defined once D-1 is resolved | Task 4 tests 1 to 3 (bounds are parameters; clamp, inert at the bound, no call beyond it); mutants T1, T2. The actual orb limits are ZOD-ASP-002's |
| 3. Body chips reflect on / off accessibly, not colour alone | Task 5 test 4 (`checked` semantics, luminance and border difference, focus ring); mutants C1, C2, C4; O1 records the decision on a check mark |

## Execution mode

Sequential, native. The three widgets are small and disjoint, but they share the Pressable edit, the token file, the export file and the sheet test and extractor, so there is **no independent work** worth a subagent.

## Risks

- **44 px slots around smaller drawn controls:** the switch (24), stepper (36) and chip (34) sit in 44 high slots (UI-004 D3 pattern), so a `Wrap` of chips has 10 px more height per run than the screens' 34 + gap; the screen task sets run spacing. Pixel tests measure the drawn box, the hit tests measure the slot.
- **Stepper slot overlap:** the end slots overlap the value area by 10 px and the layout width stays the drawn 122; hit-testing is limited to the stepper's own bounds, so there is no 5 px outward margin horizontally. Accepted; the vertical 44 and the 44-wide slot meet the target.
- **Hover is invisible on transparent controls** (stepper buttons, an off chip): `ZodiannPressable`'s brightness filter changes nothing on a transparent fill; the reference defines no hover for these. Cursor and focus ring still respond (the UI-006 precedent).
- **Selected-chip contrast:** `accent-soft` on `bg-raised` is a faint tint by design; accessibility rests on the border, `checked` and the focus ring. The test pins a minimum luminance difference; if it fails in Porcelain that is a design finding to raise, not a tolerance to loosen.
- **Switch role:** `ZodiannPressable` always sets `button`; the switch carries `button` and `toggled`. TalkBack / VoiceOver wording (Switch versus Button) needs a device; not verified here.
- **Sheet geometry:** the kit's stepper width depends on the value text; measured in Task 6 step 1 and recorded.

## Open decisions (for the owner; defaults are implemented)

- **O1: chip check mark (DECIDED 2026-11-24: sheet-exact).** Default: sheet-exact chips, with accessibility from `checked` semantics, luminance / border difference and the focus ring. Alternative: add a check icon when on (clear without colour, deviates from the sheet and MASTER §10).
- **O2: switch motion.** Default: 120 ms linear crossfade of thumb and colours (MASTER §12 "selection changes"), instant under reduced motion; kit.css has none. Alternative: instant.
- **O3: stepper in RTL.** Default: the row mirrors (kit.css flex row), so `−` is on the right in Hebrew, the value text stays LTR. To be checked against the Hebrew settings screens in Task 6; if they show `−` on the left, follow them and say so. Alternative: always `−` left.
- **O4: stepper value type.** Default: `double` with `step` (whole degrees in the design); the caller formats `valueLabel`. Alternative: `int` only.
- **O5: stepper API shape.** Default: the stepper does not format or localize; the caller passes `valueLabel`, `decrementLabel`, `incrementLabel` (no new ARB strings in `shared_ui`).
- **O6: stepper hit width.** Default: a Pressable `slotAlignment` parameter keeps 44 × 44 slots with the glyphs where the kit puts them. Alternative: no new parameter, an effective 40 × 44 hit area (departs from MASTER §14).
- **O7: focus ring radius.** Default: additive `focusRingRadius` so the switch and chip rings follow their shape. Alternative: keep the 8 px ring and record the deviation.

## Review Focus

A switch or chip toggled while hovered or pressed; stepper at a bound while its button is focused; `value` outside the bounds after a rebuild (assert in debug, clamp in release?); stepper in a very narrow parent; RTL order of the stepper against the Hebrew screens; chip `Wrap` run height; whether `checked` / `toggled` change any existing node.

## Plan review

**Round 1** (`plan-reviewer`, comprehensive). Verdict: needs user decision; 1 Critical, 5 Important, 5 Minor, 2 for the owner.

- **C1** (three tokens already exist: `switchWidth`, `switchHeight`, `stepper`): applied; Task 1 adds only the missing nine and extends the kit.css cross-check.
- **I1** (stepper slots cannot be placed with a centring Pressable): applied as option (a), `slotAlignment`; the owner may choose (b) (O6).
- **I2** (focus ring radius fixed at 8): applied, `focusRingRadius` (O7).
- **I3** (chip contrast threshold unspecified): applied, 1.5:1 border and 1.1:1 fill pinned, limitation recorded for ZOD-NFR-008.
- **I4** (out-of-bounds value): applied, debug assert plus clamped enabling, no `onChanged` from a rebuild.
- **I5** (tests miss bugs): applied, T6 note, focused-at-bound test, semantics-actions test.
- **M1** to **M5**: applied (NFR-008 note, C7 and P1 to P3 mutants, linear curve stated, fixtures README, text-literal note).
- **D1** (chip on/off without a check mark, criterion 3 against the sheet): **needs owner decision** (O1); the reviewer leans to the sheet-exact default.
- **D2** (stepper hit width): same as O6.

Open items: O6, O7 (defaults implemented). O1 was decided by the owner on 2026-11-24: sheet-exact chips. Round 2 (focused on the revision) follows.
