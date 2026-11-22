# ZOD-UI-006 Segmented Control Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (sequential, native; see "Execution mode"). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build `ZodiannSegmentedControl<T>`: a `bg-raised` track with a 3 px inset, a `surface-3` thumb with an inset 1 px `accent-line` ring on the selected segment, a 40 % opacity inert "planned" option, equal-width stretch on a phone, and a 120 ms selection crossfade (instant under reduced motion).

**Architecture:** One stateful control (one `FocusNode` per enabled segment, for arrow-key focus movement) plus a small segment value class in `packages/shared_ui/lib/src/widgets/`. Every segment reuses `ZodiannPressable` (hover, press, keyboard focus ring, Enter / Space / tap, disabled inertness), so the control behaves like every other Zodiann control. Colours come from `ZodiannSurfaces`, text from `ZodiannTextStyles.small`, icons from `ZodiannIcon`, geometry from existing tokens plus four new ones. Fidelity is proved against the component sheet with a feature extractor, the UI-004 / UI-009 method.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_ui` theme extensions, PNG feature extraction (`Rgba` and helpers as in `test/support/tag_features.dart`).

**Task:** `docs/development/shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md`. **Design:** `design-reference/zodiann/MASTER.md` §10 "Segmented control", §4 (segment thumbs 32 inside a 3 px track, radius 6), §6 (phone: segmented controls stretch evenly), §12 (120 ms selection crossfade, reduced motion), §14 (44 px touch target); `DESIGN_DECISIONS.md` D2, D19; `_source/kit.css:211-220` (`.seg`); `components/components_{dark,light}.png` rows "Segmented, mode", "Segmented with icons, drag mode", "Segmented with a planned option" (`_source/components.html:114-116`).

## Facts established while planning (2026-11-22)

- **kit.css `.seg`:** `inline-flex`, padding 3, gap 2, radius 8 (`--r-md`), `bg-raised` fill, `1px line-soft` border. Segment: height 32, `padding-inline` 12, gap 6, radius 6, 13 px / 500 `text-2`, `nowrap`. `.on`: `surface-3` fill, `text` colour, `inset 0 0 0 1px accent-line`; its icon is `accent-strong` (kit.css; MASTER §10 says "full-strength `text`", a known small conflict, see O3). `.dis`: opacity 0.4. `.full`: `display: flex`, segments `flex: 1`, centred.
- **Drawn size:** track = 3 + 32 + 3 + the 1 px border each side = **40 high**; width = content.
- **Wheel panel head (`wheel.html:55-57`)** uses the control full width on a phone (`.seg { width: 100% }`, segments `flex: 1`), inside ZOD-UI-014's `ZodiannPanelHead(leading: …)`.
- **Tokens that exist:** `ZodiannSize.segmentThumb` (32), `ZodiannSize.segmentTrackInset` (3), `ZodiannRadius.segmentThumb` (6), `ZodiannRadius.control` (8), `ZodiannSize.iconSmall` (16), `ZodiannSize.minTouchTarget` (44), `ZodiannSize.hairline` (1), `ZodiannSpace.s3` (12), `ZodiannStates.hoverBrightness` / `hoverDuration`, `ZodiannSurfaces` (`bgRaised`, `surface3`, `accentLine`, `accentStrong`, `text`, `text2`, `lineSoft`), `ZodiannTextStyles.small` (13 / 400; weight 500 via `copyWith`). **Missing:** segment gap 2, icon-to-label gap 6, planned opacity 0.4 (the shared `disabledOpacity` is 0.42), selection crossfade 120 ms.
- **`ZodiannPressable`** gives hover / press / focus ring / Enter / Space / tap / disabled and a **44 × 44 minimum layout and hit box** with the drawn child centred (UI-004 D3). A 32 px thumb therefore sits in a 44 px high slot, as a 40 px button does. It has a `selected` flag; it has no mutually-exclusive-group flag.
- **Shared consumers of `ZodiannPressable`:** `ZodiannButton`, `ZodiannIconButton`, the drawer items; their tests must stay green.
- **Where the control is used later:** wheel drag mode (WHL), time step (WHL), square mode and size (SQR), saved-squares filter (DAT), settings language / theme / defaults (SET, L10), ephemeris source. D19: whether Sidereal stays visible is a **screen** decision (needs approval); this component only supports the planned state.
- **Typography:** `small` is 13 / 400; the segment is 13 / **500** (kit.css), so the weight comes from `copyWith(fontWeight: …)`, as the tag does.

## Product-owner decisions

None taken yet. Open items are listed at the end; defaults below are implemented unless the owner changes them.

## Design (API)

```dart
final class ZodiannSegment<T> {
  const ZodiannSegment({required this.value, required this.label, this.icon, this.planned = false});
  final T value;
  final String label;            // localized by the caller
  final ZodiannIconData? icon;   // 16 px, optional
  final bool planned;            // 40 % opacity, not focusable, not selectable
}

class ZodiannSegmentedControl<T> extends StatefulWidget {
  const ZodiannSegmentedControl({
    super.key,
    required this.segments,       // asserts: non-empty, unique values
    required this.value,          // asserts: names an existing, non-planned segment
    required this.onChanged,      // ValueChanged<T>; null disables the whole control
    this.expand,                  // null = auto: stretch on phone, content-wide above
    this.semanticLabel,           // names the group for screen readers
  });
}
```

- **Draws:** outer `bg-raised` track, radius 8, 1 px `line-soft` border, 3 px inset; segments 32 high, 12 horizontal padding, 6 gap icon-to-label, radius 6, gap 2 between segments. Selected: `surface-3` fill, `text` label and an inside 1 px `accent-line` ring (painted inside the thumb, as `inset box-shadow`), icon `accent-strong` (O3). Unselected: transparent, `text-2`. Planned: whole segment at 0.4.
- **Layout (touch target):** the control's layout height is 44, with the 40 px track centred, so each segment's hit slot is 44 high (the same pattern as the 40 px button in a 44 px box). The track decoration is painted behind the segment row; segment widths are content widths (never narrower than their label), or equal flex shares when expanded.
- **Expansion:** `expand ?? (ZodiannLayout.of(context) == ZodiannLayout.phone)`. Expanded: the control fills its parent's width and every segment gets an equal share, content centred. Not expanded: content width, never wider than the parent (a narrower parent ellipsizes labels, single line).
- **Behaviour:** tap or mouse on an enabled, unselected segment calls `onChanged(value)`. A selected segment tapped again does nothing (no repeated call). A planned segment is inert by every route: tap, mouse, Enter / Space, focus traversal, arrow keys, screen reader (`enabled: false`).
- **Keyboard (O2 default):** each enabled segment is a tab stop; Enter / Space selects it; Left / Right (start / end by direction) move focus to the previous / next **enabled** segment without selecting.
  - **Keyboard mechanism:** the control is a `StatefulWidget` owning one `FocusNode` per **enabled** segment (created, reused by value and disposed as `segments` change). Each segment's `ZodiannPressable` receives its node. The segment row is wrapped in `Actions` handling `DirectionalFocusIntent`: Left / Right (swapped by `Directionality`) request focus on the previous / next enabled node and are **consumed at the ends** (the default geometric traversal would leave the control); Up / Down fall through to the default traversal (custom action, see below). No arrow key calls `onChanged`. Tab uses normal traversal, which skips planned segments because a disabled `ZodiannPressable` is not focusable.
- **Semantics:** a group node (`explicitChildNodes`, label `semanticLabel`) with one node per segment: button, `selected` for the current one, mutually-exclusive-group flag, `enabled` false for planned. Planned labels keep their "(planned)" wording supplied by the caller.
- **Motion:** the thumb's fill, ring and ink crossfade over 120 ms (`ZodiannStates.selectionDuration`), instant when `MediaQuery.disableAnimationsOf`.
  - **Motion mechanism:** `Curves.linear` over 120 ms, so "mid-way at 60 ms" is exact. Every segment is an `AnimatedContainer` (fill, plus a 1 px border that is transparent when unselected and `accent-line` when selected, so it lerps and takes no extra layout), its label an `AnimatedDefaultTextStyle`, its icon coloured through an `IconTheme` inside a `TweenAnimationBuilder<Color?>`. All use `Duration.zero` when `MediaQuery.disableAnimationsOf`.
  - **Opacity:** a planned segment is passed to `ZodiannPressable` with `onPressed: null` and `disabledOpacity: ZodiannStates.plannedOpacity` (0.4). The Pressable owns the one `Opacity`; the control adds none (a second would compound to about 0.17). With `onChanged: null` every non-planned segment falls back to the shared 0.42 and a planned one stays at 0.4.
  - **Unbounded width:** an expanded control in an unbounded-width parent falls back to content width (no throw). A segment slot is at least 44 wide (the shared touch target), so a very short label keeps its content-wide thumb centred in a 44 slot and the drawn gap is wider than 2 there; accepted, no label in the design is that short.
  - **Accepted deviations (the reference defines no segment focus or press visuals):** the shared focus ring has an 8 radius (the thumb is 6), and a press moves the thumb 1 px down inside the track; both are asserted in tests so they are documented behaviour.
  - **Segment box (round 2 C1):** Flutter's `Container` adds a decoration's border width to its padding, so the segment's horizontal padding is `ZodiannSpace.s3 - ZodiannSize.hairline` (11) on each side, making border plus padding the sheet's 12. The height is fixed at `ZodiannSize.segmentThumb` (32) with the border inside it. The content box is therefore unchanged by the selection state, and test 5 asserts the label starts 12 px inside the thumb.
  - **Crossfade endpoints (round 2 I1):** the unselected fill and ring are the **same colours with alpha 0** (`surface3.withAlpha(0)`, `accentLine.withAlpha(0)`), never `Colors.transparent` (0x00000000 would lerp through black). The weight is 500 in both states; `AnimatedDefaultTextStyle` animates colour only, so metrics never jump.
  - **Arrow-key action (round 2 I2):** a custom `Action<DirectionalFocusIntent>` whose `isEnabled` is true only for `TraversalDirection.left` and `right` (physical directions, so the mirrored `Row` swaps them in RTL without extra code); `CallbackAction` cannot be used because it is always enabled and would swallow Up and Down. `invoke` finds the focused node by `primaryFocus` identity in the control's enabled-node list, requests focus on the neighbour, and does nothing at the ends.
  - **Focus-node lifecycle (round 2 I3):** nodes are keyed by segment `value`; stale ones are disposed after the frame (`addPostFrameCallback`), never while the old detector still holds them; when `onChanged` is null no nodes are created and none are passed.
- **Mirroring:** `Row` order and directional geometry only; no `Transform`.
- **Text scale:** segments grow in height beyond 32 (the slot minimum), as the tag and buttons do; labels stay single-line.

## Global Constraints

- No new dependency, no pubspec change; `no_network_test.dart` unchanged and green.
- Sizes only from `ZodiannSize` / `ZodiannSpace` tokens (UI-003 guard), colours only from the theme extensions (ARCH-7 guard), text styles via `copyWith` of a `ZodiannTextStyles` role, no string literals in `Text`.
- `ZodiannPressable`'s existing behaviour is unchanged for its current consumers (two additive edits with defaults that reproduce today's behaviour: `inMutuallyExclusiveGroup` false, `disabledOpacity` null meaning 0.42).
- Staging: explicit paths per commit; never `git add -A` / `.` / `commit -a`. `.fvmrc` and `grep.exe.stackdump` stay unstaged.
- Commands: `fvm flutter test <file>` from `packages/shared_ui`; **root** `fvm dart run melos run lint` / `test`. Tests that read `../../design-reference/...` need the package as working directory. Use the Write tool for files containing apostrophes (shell heredocs reject them here).
- Naming: project prefix `Zodiann`.

## Out of scope

- Which screen shows which segmented control, their strings, and whether Sidereal stays (D19): screen tasks.
- Controlled state, persistence, localization of labels: the caller.
- A multi-select variant, vertical orientation, scrolling when it overflows (not in the design).
- The panel head's stacking rule: ZOD-UI-014 (already merged); this task only adds one test that the two work together on a phone.

## File structure

| File | Action |
|---|---|
| `lib/src/theme/tokens/zodiann_dimensions.dart` | add `ZodiannSize.segmentGap` (2), `segmentIconGap` (6) |
| `lib/src/theme/tokens/zodiann_states.dart` | add `plannedOpacity` (0.4), `selectionDuration` (120 ms) |
| `lib/src/widgets/zodiann_pressable.dart` | add `inMutuallyExclusiveGroup` (default false, passed to `Semantics`) and `disabledOpacity` (`double?`, null = `ZodiannStates.disabledOpacity`) |
| `lib/src/widgets/zodiann_segmented_control.dart` | new: `ZodiannSegment`, `ZodiannSegmentedControl` |
| `lib/shared_ui.dart` | export it |
| `test/theme/dimensions_test.dart`, `test/widgets/button_colors_test.dart` | pin the size tokens; pin the state tokens beside the existing `disabledOpacity` pin (line 27), the only place it is pinned |
| `test/widgets/pressable_selected_test.dart` | cover the new flag |
| `test/widgets/segmented_control_test.dart` | new: behaviour, keyboard, semantics, layout, RTL, text scale, motion |
| `test/support/segment_features.dart`, `test/widgets/segmented_control_sheet_test.dart` | new: sheet fidelity (both themes) |
| task file, `docs/development/TASKS.md`, `docs/PROGRESS.md` | status and records after verification |

## Tasks

Commands run from `packages/shared_ui` unless marked **root**.

### Task 1: Tokens (TDD)

- [ ] **Step 1 (RED):** pin `segmentGap == 2`, `segmentIconGap == 6` in `dimensions_test.dart` and `plannedOpacity == 0.4`, `selectionDuration == 120 ms` in the existing states test (`test/widgets/button_colors_test.dart`, next to the existing `disabledOpacity` pin; there is no theme states test). Run both files. Expected: compile errors `Member not found: 'segmentGap'` etc.
- [ ] **Step 2 (GREEN):** add the four constants with doc comments (kit.css `.seg` and MASTER §12 as sources). Re-run: pass. **Root command** (run from the repository root, not the package): `fvm dart test test/architecture/no_magic_dimensions_test.dart`: pass.
- [ ] **Step 3:** commit `feat(ZOD-UI-006): add the segmented-control tokens`.

### Task 2: Pressable group flag and disabled opacity (TDD)

- [ ] **Step 1 (RED):** in `pressable_selected_test.dart` add: a `ZodiannPressable(inMutuallyExclusiveGroup: true, selected: true, …)` exposes `isInMutuallyExclusiveGroup`; the default exposes none (matcher on the semantics flags); existing button, icon button and drawer semantics tests unchanged. Run. Expected: compile error `No named parameter 'inMutuallyExclusiveGroup'`.
- [ ] **Step 2 (GREEN):** add the field, pass it to `Semantics(inMutuallyExclusiveGroup: …)` (null when false, so existing nodes are unchanged). Run `fvm flutter test test/widgets/pressable_selected_test.dart test/widgets/pressable_test.dart test/widgets/button_test.dart test/widgets/button_behavior_test.dart test/widgets/icon_button_test.dart test/widgets/drawer_test.dart test/widgets/top_bar_test.dart`: pass (these assert `disabledOpacity` today).
- [ ] **Step 1b (RED):** in `pressable_test.dart` (where the existing opacity test is) add: a disabled `ZodiannPressable` has an `Opacity` of 0.42 by default (unchanged); with `disabledOpacity: 0.4` the `Opacity` widget's value is 0.4; an enabled one is 1 in both cases. Expected: compile error `No named parameter 'disabledOpacity'`.
- [ ] **Step 2b (GREEN):** add `disabledOpacity` and use `widget.disabledOpacity ?? ZodiannStates.disabledOpacity` where the disabled opacity is applied. Re-run the same seven files: pass. Update the Pressable doc comment ("42 % opacity") to mention the `disabledOpacity` override.
- [ ] **Step 3:** commit `feat(ZOD-UI-006): extend the pressable for segmented controls`.

### Task 3: The control, RED first

- [ ] **Step 1 (RED), `test/widgets/segmented_control_test.dart`:** write the tests below against a stub (`ZodiannSegment`, `ZodiannSegmentedControl` with the final constructors, an empty build, exported). Run `fvm flutter test test/widgets/segmented_control_test.dart`. Expected: every test fails on its **assertion**, not on compilation.
  1. **Selection:** tapping an unselected enabled segment calls `onChanged` once with its value; tapping the selected one calls nothing; mouse click (a `TestPointer` of kind mouse) does the same.
  2. **Planned is inert by every route:** tap, mouse click, Enter and Space with focus forced onto the neighbour, Tab traversal skips it, arrow keys skip it, `tester.getSemantics` shows `enabled: false`; `onChanged` is never called; cursor is `forbidden`.
  3. **Keyboard:** Tab reaches each enabled segment in order (RTL: visual order mirrored, focus order is logical order); Enter and Space select the focused segment; Right / Left move focus to the next / previous enabled segment (swapped in RTL) and wrap nowhere (stop at the ends); moving focus does not call `onChanged`.
  4. **Semantics:** group node with `semanticLabel`; each segment is a button; only the current one is `selected`; all are in a mutually exclusive group; the planned one is disabled; the label read is the segment's label.
  5. **Geometry (LTR, Graphite):** the label starts 12 px inside the thumb (11 padding plus the 1 px border); track 40 high (3 + 32 + 3 + 2 borders), layout height 44, thumb 32 high, 12 horizontal padding, gap 2 between segments, 6 between icon and label, track radius 8 / thumb radius 6.
  6. **Hit target:** a tap 2 px above and 2 px below the drawn track, over a segment, selects it (44 px slot).
  7. **Expansion:** at 390 (phone) the control fills the parent width and the segments are equal width (±0.5 px); at 1440 it is content-wide; `expand: true` / `false` override both; at a parent narrower than the content the labels ellipsize on one line and nothing overflows.
  8. **Panel head:** inside `ZodiannPanelHead(leading: control, end: short hint)` at 390 the hint drops below the control; at 1440 they share a row (proves UI-014 and UI-006 compose).
  9. **RTL / Hebrew:** segment order mirrors; the thumb and ring stay on the selected segment; offsets equal the mirrored LTR ones.
  10. **Text scale 2:** the track is found and the segments grow past 32 (an assertion that fails on the empty stub), no overflow exception.
  11. **Motion:** after changing `value`, the selected fill is mid-way at 60 ms and final at 120 ms; with `disableAnimations` it is final immediately.
  12. **Live theme switch:** Graphite to Porcelain rebuilds with the new colours (no stale colours).
  13. **Asserts:** empty segments, duplicate values, a `value` that names no segment or a planned one all fail an assert; `onChanged: null` disables every segment.
  14. **Planned and focus:** Up and Down still follow the default traversal (not consumed); with the neighbour focused, Tab and the arrow keys never land on the planned segment; a planned segment given a directly requested `FocusNode` cannot take focus; arrow keys at the first and last enabled segment keep focus where it is and do not leave the control; no arrow key calls `onChanged`.
  15. **Planned opacity:** the planned segment's single `Opacity` is 0.4 (not 0.42, not 0.17); with `onChanged: null` a non-planned segment is 0.42 and the planned one stays 0.4.
  16. **Semantics detail:** unselected segments carry no selected state at all (as the drawer: selected is true or absent), so the matcher is `isSelected` for the current one only.
  17. **Accepted deviations are pinned:** a press moves the thumb 1 px down; the shared focus ring is drawn for keyboard focus only.
  18. **Dynamic changes:** `segments` changing length or order between builds keeps one live `FocusNode` per enabled segment (none leaked: the test disposes the tree and expects no framework error); a `value` that changes while a segment is focused or pressed keeps focus; the selected segment becoming planned in a rebuild trips the assert in debug.
  19. **Unbounded width:** an expanded control inside an unbounded-width parent (a horizontal `SingleChildScrollView`) is found, lays out at the sum of its segments' content widths and throws nothing.
  20. **Curve:** at 60 ms the fill and ring equal the linear mid-point between the alpha-0 and final token colours, composited over the track (±1 per channel); `Colors.transparent` endpoints fail it (M19).
- [ ] **Step 2 (GREEN):** implement `zodiann_segmented_control.dart` minimally, export it; run the file: pass.
- [ ] **Step 3 (REFACTOR):** doc comments (O1 to O5 behaviour, hit-target layout, focus-ring contract: the ring paints 4 px beyond a segment, over the track; the control never clips); **root:** `fvm dart run melos run lint`.
- [ ] **Step 4:** commit `feat(ZOD-UI-006): add ZodiannSegmentedControl`.

### Task 4: Fidelity to the component sheet (both themes)

- [ ] **Step 1:** measure the three sheet rows in `components_dark.png` and `components_light.png` (track left, top, width, 40 high; each thumb; ring; text colours; the planned option's blended colours) with a throw-away scan, as UI-009 did for tags; record the numbers and Chrome's fractional layout widths (headless Chrome on `_source/components.html`) in the test header. Confirm the sheet scale is 1× from a known element; if it is not, derive it and say so.
- [ ] **Step 2 (RED then GREEN):** `test/support/segment_features.dart` extracts the same features from both PNGs and from the widget render: track box (left, top, width, height ±1 on width, exact top and height), track border and fill (±1 per channel), thumb box inside the track, ring pixels (±3), label and icon pixels (±3 per channel), planned option's blended fill and text. `segmented_control_sheet_test.dart` renders each of the three sheet rows in Graphite and Porcelain at an integer origin and compares. Run; the first run is expected to expose any token or weight mismatch (RED), then fix the widget, not the tolerance.
- [ ] **Step 2b:** the icon assertion samples the stroke's core pixels (solid ink), because `accent-strong` and `text` differ by only about 11 channel values and anti-aliased edge pixels would hide it; mutant M15 proves it.
- [ ] **Step 3:** the icon colour (O3) is decided here by what the sheet shows: assert it, and if it is `accent-strong`, say so in the widget's doc comment.
- [ ] **Step 4:** commit `test(ZOD-UI-006): compare the segmented control with the component sheet`.

### Task 5: Mutation proof

- [ ] **Step 1:** throw-away edits, each reverted, each run named: M1 thumb ring dropped; M2 thumb fill `surface-2`; M3 track fill `surface`; M4 planned opacity 0.42; M5 planned segment tappable; M6 planned segment focusable; M7 selected segment re-fires `onChanged`; M8 expansion by `flex` removed on phone; M9 hit slot 32 instead of 44; M10 crossfade 0 ms; M11 RTL order not mirrored; M12 selected `semantics.selected` dropped; M13 gap 2 to 4; M14 track inset 3 to 4; M15 selected icon colour `text` instead of `accent-strong`; M16 a second `Opacity` of 0.4 around a planned segment (compounds to 0.17); M17 arrow keys not consumed at the ends; M18 curve `ease` instead of linear; M19 `Colors.transparent` as the unselected endpoint; M20 segment padding 12 beside the 1 px border (14 wide: test 5 and the sheet test).  (M4 is caught by the Task 2 disabled-opacity test and Task 3 test 15.) Each must fail at least one test; record the catching tests under Verification in PROGRESS.
- [ ] **Step 2:** no commit unless a mutant survives (then add the test that kills it first).

### Task 6: Verification, review, documentation

- [ ] **Step 1 (root):** `fvm dart run melos run lint` and `fvm dart run melos run test`. Record exit codes and counts.
- [ ] **Step 2:** `requesting-code-review`: one fresh-reviewer pass over the whole branch; fix Important findings test-first.
- [ ] **Step 3:** `verification-before-completion`; update the task file (status, ticked criteria with evidence), `TASKS.md`, `PROGRESS.md` (plan path, decisions, verification with commands and head commit, git state, and correct the UI-014 PR line to merged `edc45cf`); push, open the PR, add the PR link in a follow-up commit.

## Acceptance criteria mapping

| Criterion | Proof |
|---|---|
| 1. Selected / unselected / planned match the component sheet pixel-for-pixel | Task 4 (three rows, two themes, extractor on both sides); Task 3 test 5 (geometry) and 11 (final state of the crossfade); mutants M1 to M4, M13, M14 |
| 2. On a phone the control stretches to fill its row | Task 3 tests 7 and 8; mutant M8 |
| 3. The planned option cannot be selected by tap, mouse or keyboard | Task 3 tests 2, 3 and 14; mutants M5, M6, M17 |

## Execution mode

Sequential, native. Tasks 1 to 4 build on each other and the widget shares `ZodiannPressable` with its consumers, so there is **no independent work** and no subagent justification.

## Risks

- **Touch-target layout (44) around a 40 px track:** the track decoration is painted behind a 44 px high segment row, so a segment's pixels are drawn in a box taller than the visible control; the pixel tests measure the drawn track, the hit-target test measures the slot.
- **Hover on unselected segments:** they are transparent, so `ZodiannPressable`'s 12 % brightness filter changes nothing visible there; the reference defines no segment hover. The cursor and the focus ring still respond. Accepted and documented; revisit with the designer if wanted.
- **Focus ring on a segment** paints 4 px beyond the thumb, over the track's 3 px inset and its border; it is not clipped by the control. Inside `ZodiannPanel` with the default no-clip this is visible; a caller that clips must keep 4 px clear (as for buttons).
- **Shared `ZodiannPressable` edit:** additive and default-off, but it touches the button, icon button and drawer; their tests are re-run in Task 2.
- **Sheet scale and Chrome widths** must be confirmed in Task 4 step 1; if the sheet is not 1×, the tolerances are derived rather than assumed.

## Open decisions (for the owner; defaults are implemented)

- **O1: stretch.** Default: automatic, the control fills its row on a phone and is content-wide above; `expand` overrides. Alternative: always explicit (every screen passes it).
- **O2: keyboard model.** Default: each enabled segment is a tab stop, Enter / Space select, Left / Right move focus (selection follows on activation, not on arrow). Alternative: the radio-group pattern (one tab stop, arrows select immediately).
- **O3: selected icon colour (spec versus reference).** The task file says icon and text "at full `text` strength" and MASTER §10 says `text`; kit.css and the sheet (the pixel-for-pixel criterion) use `accent-strong` for the icon. Default: follow kit.css and the sheet (`accent-strong`), checked against the PNG in Task 4; MASTER §10 says `text` and is not edited (the NAV-002 precedent).
- **O4: planned opacity.** Default: 0.4 as MASTER and kit.css say, as a new `plannedOpacity` token, not the 0.42 of other disabled controls.
- **O5: narrow parent.** The task file says "wrap into a reasonable width on desktop/tablet"; the plan reads that as content-wide, ellipsizing labels on one line in a narrower parent, with no wrapping or scrolling. Alternative: wrap labels to two lines (the control would grow).

## Review Focus

The behaviours the tests do not obviously reach: a `value` that changes while a segment is focused or pressed; `segments` changing length between builds; a planned segment that is currently selected (assert fires, not a silent mismatch); the focus order after the selected segment becomes planned; RTL arrow direction with a planned segment in the middle; `onChanged` that rebuilds with the same value (no loop); the group semantics when `semanticLabel` is null.

## Plan review

**Round 1** (`plan-reviewer`, comprehensive). Verdict: approve after corrections; one Critical, four Important.

| ID | Severity | Finding | Done |
|---|---|---|---|
| C1 | Critical | A planned segment (`onPressed: null`) already gets the Pressable's 0.42 opacity; an extra 0.4 would compound to about 0.17 | Applied: additive `disabledOpacity` on `ZodiannPressable`, Task 2 steps 1b / 2b, Task 3 test 15, mutants M4 and M16 |
| I1 | Important | Keyboard mechanism unspecified; default arrow traversal would leave the control | Applied: stateful control, one `FocusNode` per enabled segment, `Actions` for `DirectionalFocusIntent`, consumed at the ends; tests 14 and 18; M17 |
| I2 | Important | Crossfade curve and widgets unspecified | Applied: `Curves.linear`, `AnimatedContainer` / `AnimatedDefaultTextStyle` / `TweenAnimationBuilder`, zero duration under reduced motion; test 20; M18 |
| I3 | Important | Focus ring radius 8 versus thumb 6; press moves the thumb | Applied: recorded as accepted deviations, pinned by test 17 |
| I4 | Important | Unbounded width; 44 minimum slot width | Applied: content-width fallback, test 19, note on short labels |
| I5 | Important | Thin evidence for the icon colour (O3) | Applied: core-pixel sampling, mutant M15, O3 presented as spec versus reference |
| M1 to M5 | Minor | States test location, root-command label, O5 wording, test 2 wording, semantics `selected` | Applied (Task 1, O5, tests 14 and 16) |
| M6 | Minor | Tech-stack line | Confirmed, no change |

**Round 2** (`plan-reviewer`, focused on the revision, commit `2fa9bd4`). Verdict: approve after corrections; round 1 items confirmed applied.

| ID | Severity | Finding | Done |
|---|---|---|---|
| C1 | Critical | A border in `AnimatedContainer` takes layout (`Container` adds the decoration's border to its padding), so segments would be 2 px wider than the sheet | Applied: padding `s3 - hairline` (11), height fixed at 32, test 5 label offset 12, mutant M20 |
| I1 | Important | `Colors.transparent` endpoints lerp through black; the ring and fill are semi-transparent | Applied: same colour with alpha 0 endpoints, test 20 against them, mutant M19 |
| I2 | Important | `CallbackAction` would swallow Up and Down | Applied: custom `Action<DirectionalFocusIntent>` enabled for left and right only; test 14 asserts Up and Down fall through |
| I3 | Important | Disposing a `FocusNode` while the old detector holds it | Applied: keyed by value, disposed after the frame, none when `onChanged` is null |
| I4 | Important | Task 2 regression list missed files that assert `disabledOpacity` | Applied: seven files named; step 1b names `pressable_test.dart` |
| I5 | Important | RED claim false for tests 10 and 19 (they pass on an empty stub) | Applied: each now asserts something the stub fails |
| M1 to M3 | Minor | Pressable doc comment; colour-only text animation; criterion 3 mapping | Applied |

Two rounds are used. Open items for the owner: O1 to O5 (defaults implemented).

## Execution notes (2026-11-23)

- **Deviation, Flutter 3.50:** round 2 of the plan review (I2) specified a custom `Action` whose `isEnabled` is true only for Left and Right so that Up and Down fall through to ancestors. In Flutter 3.50 `Actions.maybeFind` returns the nearest action by intent type even when it is disabled, and the shortcut manager would then report the key as unhandled for the whole chain, so Up and Down would never reach the default traversal or an outer handler. The implemented action is enabled for all four directions: Left and Right move focus between enabled segments (mirrored in RTL, stopping at the ends, scrolling the new segment into view); Up and Down are passed to the next enclosing handler found from a context above the control, and `consumesKey` is true for them only when that handler is enabled and consumes the key. Tests: an outer handler sees Up and Down and never Left and Right; with a disabled outer handler Up and Down are reported unhandled; mutants M17 and M22.
- **Focus ring (found by the final review):** the planned "ring on each segment" was drawn by `ZodiannPressable` inside each slot, where the selected neighbour (2 px gap, opaque thumb) covered it. `ZodiannPressable` gained `focusRing` (default true) and the control draws the focused thumb's ring in a layer above the row, measured from the thumb (not the 44 px slot). Tests: LTR and RTL pixel tests, a Tab-versus-tap test, a short-segment test; mutant M23.
- **Text scale:** above scale about 1.6 the row sat at the top of the track stack; fixed by centring (tests at scales 2 and 3; mutant M21).
- **Sheet test tolerance:** the unselected icon is compared at 8 per channel (anti-aliasing coverage 95 percent on the sheet against 100 percent here); the selected icon, which separates `accent-strong` from `text`, at 3.
- **Verification:** package by package after a single full run was stopped by the system for low memory (an environment event, not a failure); results and the 23-mutant proof are in `docs/PROGRESS.md` under Verification.
