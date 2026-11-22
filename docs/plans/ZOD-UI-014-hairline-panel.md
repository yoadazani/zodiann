# ZOD-UI-014 Hairline Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (sequential, native; see "Execution mode"). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build `ZodiannPanel` (the 1 px `line-soft` bordered, 12 px radius, `surface` shell) and `ZodiannPanelHead` (the 56 / 52 px head with its bottom hairline), so every screen's content sections sit in one component with no shadow and no per-screen re-implementation.

**Architecture:** Two small stateless widgets in `packages/shared_ui/lib/src/widgets/`. All geometry comes from existing tokens (`ZodiannLayout.of(context)`, `ZodiannRadius.panel`, `ZodiannSurfaces`, `ZodiannTextStyles`), plus one new size token, `ZodiannSize.hairline` (1.0), which the UI-003 review minors already ask for. The UI-003 test harness (`token_panel_harness.dart`, which says "ZOD-UI-014 builds the real panel") is switched to the real widget, so UI-003's existing pixel measurements (`panel_spacing_test.dart`) become regression tests of the component without being rewritten.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `shared_ui` theme extensions, headless pixel measurement as in `panel_spacing_test.dart`.

**Task:** `docs/development/shared-ui-design-system/ZOD-UI-014-implement-the-hairline-panel-component.md`. **Design:** `design-reference/zodiann/MASTER.md` §1 (hairlines over boxes) and §4; `design-reference/zodiann/_source/kit.css:177-182` (`.panel`, `.panel-head`, `.panel-body`) and the phone overrides `_source/settings.html:33`, `_source/wheel.html:55-57`; head usages in `wheel.html`, `settings.html`, `saved.html`; screens in `design-reference/zodiann/screens/`.

## Facts established while planning (2026-11-22)

- **kit.css:** `.panel` = `surface` fill, `1px solid line-soft`, radius 12, no shadow, **no overflow clip**. `.panel-head` (desktop) = flex row, gap 12, padding 16 20, bottom `1px line-soft`, `min-height: 56`; `h2` 16/600; `.meta` 13 `text-2`; `.end` pushed to the end (`margin-inline-start: auto`). `.panel-body` padding 20.
- **Phone overrides:** `settings.html:33` and `wheel.html:55` set `.panel-head { padding: 12 16 }`, and `wheel.html` adds `min-height: 52px`; `wheel.html:56-57` makes the wheel panel's head `flex-wrap: wrap` with the segmented control at 100 % width.
- **Head content varies by screen:** title only (Time, settings sections), title + meta (Positions), title + meta + end action (Degree crossings), and a segmented control + end hint with **no title** (wheel panel). Some panels have no head (`panel note`, `panel empty`), and table / list panels have **no body padding** (the table runs edge to edge).
- **Tokens that exist:** `ZodiannLayout` (`panelPadding` 20 / 16, `panelHeadHeight` 56 / 52, "including its 1 px bottom rule"), `ZodiannRadius.panel`, `ZodiannSurfaces.surface` / `lineSoft`, `ZodiannTextStyles.panelTitle` (16 / 1.3, 600) and `small` (13), `ZodiannSpace.s3` / `s4`. **Missing:** a 1 px hairline width (UI-003 review minor: "a hairline-width token would be needed for `Border.all(width: 1)`").
- **Known small difference:** kit.css gives the panel `h2` `letter-spacing: -.005em` (about 0.08 px); `ZodiannTextStyles.panelTitle` (UI-002) has 0. The token is UI-002's; the panel does not override it.
- **`token_panel_harness.dart`** already builds two panels with boxes only and measures them border-box (padding inside the 1 px border, head including its rule). `panel_spacing_test.dart` measures it at 1440 and 390 (Graphite) and is its only consumer. `_Pixels` there is private (Task 4 moves it).
- **Mobile reference mismatch** (task Notes): `settings_mobile_he_dark.png` shows 20 / 56 on a phone; MASTER §4's 16 / 52 apply.
- **Elevation:** `ZodiannElevation` carries only the floating layers' shadow. A panel takes no elevation input, so "no shadow in dark" is by construction; it is proved by pixels.
- **Existing consumers:** none. Panels today are ad hoc `DecoratedBox`es only in the test harness. No production code changes.

## Product-owner decisions

None taken yet. Open items for the owner are listed at the end ("Open decisions"); the defaults below are what the plan implements unless the owner says otherwise.

## Design (API)

```dart
/// The panel shell.
ZodiannPanel({
  Key? key,
  ZodiannPanelHead? head,            // null: no head, no rule
  EdgeInsetsGeometry? bodyPadding,   // null = EdgeInsets.all(layout.panelPadding); EdgeInsets.zero for tables/lists
  Clip clipBehavior = Clip.none,     // CSS has no clip; opt in for full-bleed content
  required Widget child,
})

/// The head row: [leading | title + meta] ... [end]
ZodiannPanelHead({
  Key? key,
  String? title,         // panelTitle style, wraps (never truncated), semantics header
  String? meta,          // small / text-2, wraps
  Widget? leading,       // any widget; replaces title/meta (wheel panel's segmented control)
  Widget? end,           // any widget; pushed to the end edge, wraps below when it does not fit
})
```

- Shell paints `surface` fill, `Border.all(color: lineSoft, width: ZodiannSize.hairline)`, `ZodiannRadius.panel`, **no `boxShadow`, no elevation parameter**.
- Border-box: content sits inside the 1 px border.
- Head padding follows the reference: horizontal = `layout.panelPadding` (20 / 16); vertical = `ZodiannSpace.s4` (16) on regular and `ZodiannSpace.s3` (12) on phone, branching on `layout == ZodiannLayout.phone`. Gap between head children 12 (`ZodiannSpace.s3`). Directional padding only.
- Head height = `max(layout.panelHeadHeight, 2 × verticalPadding + content + hairline)`. Built as `ConstrainedBox(constraints: BoxConstraints(minHeight: panelHeadHeight - hairline))` over the padded, vertically centred content, then the 1 px bottom rule, so the rule sits **inside** the 56 / 52 and an empty head is exactly 56 / 52. Arithmetic: a titled head is 16 + 20.8 + 16 + 1 = 53.8 (regular) and 12 + 20.8 + 12 + 1 = 45.8 (phone), both below the minimum, so 56 / 52 govern; a 40 px child gives 73 (regular) and 65 (phone). An empty head is exactly 56 / 52.
- Head layout: a private `CustomMultiChildLayout` (one `MultiChildLayoutDelegate`; `Wrap` cannot push `end` to the end edge). The head **fills the panel width** (the delegate sizes itself to `constraints.maxWidth`; no `SizedBox(width: …)`). Rules, with gap `ZodiannSpace.s3` (12) between start and `end` and `ZodiannSpace.s2` (8) between lines:
  1. measure `end` at its intrinsic width and the start group (`leading`, or title + meta) at its natural width;
  2. if `start + 12 + end` fits, one line, start at the start edge, `end` at the end edge (directional), both vertically centred;
  3. otherwise, on **regular** widths (kit.css has no wrap there): `end` stays beside the start group, which is laid out in `max − end − 12` and wraps its text;
  4. otherwise, on **phone** (`wheel.html:56-57`): `end` goes on a second line below the start group, at the end edge, and the start group takes the full width.
  Title and meta wrap rather than ellipsize (O4 default).
- The panel is a plain box that takes its parent's width; it never stacks itself and sets no margin (the page owns `panelGap` and `gutter`).
- Focus-ring contract (UI-004): the panel adds **no clip by default**, so a button's 4 px focus ring in a head or body is never cut off. A caller that sets `clipBehavior` owns keeping 4 px of clear space around buttons; the doc comment says so.

## Global Constraints

- No new dependency, no pubspec change. `no_network_test.dart` unchanged and green.
- Sizes only from `ZodiannSize` / `ZodiannSpace` / `ZodiannLayout` tokens, no numeric literals in `lib/` (UI-003 guard). Colours only from theme extensions (ARCH-7 guard). Text styles derive from `ZodiannTextStyles` roles via `copyWith`.
- Directional geometry only (`EdgeInsetsDirectional`, `AlignmentDirectional`), no `Transform` mirroring.
- Staging: explicit paths per commit; never `git add -A` / `.` / `commit -a`. `.fvmrc` and the untracked `grep.exe.stackdump` stay unstaged.
- Commands: `fvm dart …` / `fvm flutter …`; Melos as `fvm dart run melos run <script>` (gates `lint`, `test`). A root `fvm flutter pub get` deletes the tracked generated l10n files in `packages/shared_ui/lib/l10n/`; restore with `git checkout -- packages/shared_ui/lib/l10n`.
- Naming: project prefix `Zodiann`.

## Out of scope

- Panel **content** (tables, forms, lists, segmented control, hint text): UI-005, UI-006, UI-010 and the screen tasks. The panel takes any child.
- Responsive composition of panels on a page (grid, stacking, order): screen tasks (WHL-025, SQR-*).
- Sticky or scrolling heads, collapsible panels, selected / highlighted panel variants (not in the design).
- Screenshot regression harness: ZOD-UI-015.

## File structure

| File | Action |
|---|---|
| `packages/shared_ui/lib/src/theme/tokens/zodiann_dimensions.dart` | add `ZodiannSize.hairline = 1.0` |
| `packages/shared_ui/lib/src/widgets/zodiann_panel.dart` | new: `ZodiannPanel`, `ZodiannPanelHead` |
| `packages/shared_ui/lib/shared_ui.dart` | export `zodiann_panel.dart` |
| `packages/shared_ui/test/theme/dimensions_test.dart` | pin `hairline` |
| `packages/shared_ui/test/support/token_panel_harness.dart` | build panels with the real widget (boxes as content) |
| `packages/shared_ui/test/support/pixels.dart` | new: `_Pixels` moved out of `panel_spacing_test.dart` and renamed public `Pixels` |
| `packages/shared_ui/test/widgets/panel_test.dart` | new: decoration, head sizing, wrap, RTL, text scale, semantics, clip |
| `packages/shared_ui/test/widgets/panel_pixels_test.dart` | new: border, radius, padding, head, no shadow by pixels, both themes |
| `packages/shared_ui/test/widgets/panel_reference_test.dart` | new, conditional (Task 5) |
| task file, `docs/development/TASKS.md`, `docs/PROGRESS.md` | status and records after verification |

## Tasks

All commands run from `packages/shared_ui` unless marked **root** (tests read `../../design-reference/...`, so the working directory matters). The literal guard is the root test `test/architecture/no_magic_dimensions_test.dart`; it flags literals inside `BorderSide(`, `EdgeInsets*(`, `SizedBox(`, `BoxConstraints(`, `BorderRadius.circular(`, so the widget uses tokens only in those calls (`Border.all(width: ZodiannSize.hairline)` passes).

### Task 1: Hairline token (TDD)

- [ ] **Step 1 (RED):** in `test/theme/dimensions_test.dart` add `ZodiannSize.hairline == 1.0` (MASTER §4 "1 px rules"). Run `fvm flutter test test/theme/dimensions_test.dart`. Expected: fails to compile, `The getter 'hairline' isn't defined for the type 'ZodiannSize'`.
- [ ] **Step 2 (GREEN):** add `static const double hairline = 1.0;` with a doc comment to `ZodiannSize`. Re-run: passes. **Root:** `fvm dart test test/architecture/no_magic_dimensions_test.dart`: passes.
- [ ] **Step 3:** commit `feat(ZOD-UI-014): add the hairline size token`.

### Task 2: Shell and head, RED first

- [ ] **Step 1 (RED), `test/widgets/panel_test.dart`:** write the tests below against a stub `ZodiannPanel` / `ZodiannPanelHead` (empty classes with the final constructors, in `lib/src/widgets/zodiann_panel.dart`, exported) so they compile. Run `fvm flutter test test/widgets/panel_test.dart`. Expected: every test fails on its **assertion** (finder finds nothing / size is 0), not on a compile error.
  1. decoration: colour `surface`, border all sides `lineSoft` width 1, radius `ZodiannRadius.panel`, `boxShadow` null or empty, in Graphite and Porcelain;
  2. a head-less panel has no rule; the child's top offset is 1 + padding;
  3. `bodyPadding: EdgeInsets.zero` puts the child flush inside the border (table case);
  4. an empty head is exactly `panelHeadHeight` tall (56 / 52), rule included (this is what the UI-003 harness measures);
  5. a titled head (one line) is 56 / 52; a head with a 40 px child is 73 on regular and 65 on phone (16 + 40 + 16 + 1; 12 + 40 + 12 + 1); a 72 px child grows it further, never shrinks;
  6. head variants lay out without overflow at 1440 and 390: title only; title + meta; title + meta + a 96 px button as `end`; `leading` only;
  7. placement: (a) at 1440, a short `leading` plus a 96 px `end` sit on one line, `end` at the end edge; (b) at 1440, a 200-character title with a 96 px `end`: `end` stays on the first line at the end edge and the title wraps; (c) at 390, a `leading` that fills the width (a `SizedBox(width: double.infinity)` built **in the test** from a `LayoutBuilder`, not a pixel literal) plus a 120-character `end` text lays out without overflow with `end` **below** `leading`; each case in LTR and RTL (mirrored offsets as in test 8); the head always spans the panel's inner width;
  8. RTL: title at the right (start) edge, `end` at the left (end) edge; each child's offset equals `width − (LTR offset + child width)`;
  9. text scale 2.0: head grows, no overflow; a 200-character title wraps over several lines and is fully present (no ellipsis);
  10. semantics: the title is a header node; meta and `end` are not marked as headers;
  11. clip contract: a child placed 4 px outside the panel's outer edge with `Transform.translate(Offset(-4, 0))` and a coloured box. By pixels: with the default `clipBehavior` that 4 px strip is painted (a focus ring is not cut); with `Clip.antiAlias` the strip is the page `bg`. No hit-test assertion unless verified while writing.
- [ ] **Step 2 (GREEN):** implement `zodiann_panel.dart` minimally; run `fvm flutter test test/widgets/panel_test.dart`: all pass.
- [ ] **Step 3 (REFACTOR):** doc comments (focus-ring contract, border-box rule, "no elevation by design", full-bleed guidance); **root:** `fvm dart run melos run lint`; fix findings.
- [ ] **Step 4:** commit `feat(ZOD-UI-014): add ZodiannPanel and ZodiannPanelHead`.

### Task 3: Switch the harness to the real widget (regression of UI-003)

- [ ] **Step 1:** rewrite `_Panel` in `test/support/token_panel_harness.dart` to `ZodiannPanel(head: ZodiannPanelHead(), child: <the 40 px accent block>)`, keeping the public keys and updating the header comment. This changes what the spacing test measures: the head is now the real min-height path (an empty head is exactly `panelHeadHeight` including its rule, proved by Task 2 test 4), not a hand-built `SizedBox` plus rule. The panel must still stretch to its parent's width (`Column(crossAxisAlignment: stretch)` on phone, `Expanded` on desktop) and the head must not shrink-wrap; the unchanged spacing test's content offsets at 1440 and 390 prove it.
- [ ] **Step 2:** run `fvm flutter test test/theme/panel_spacing_test.dart` with **no edits to its expectations**: passes at 1440 and 390.
- [ ] **Step 3:** `grep -rn TokenPanelHarness` across the repo; run every other consumer unchanged (only `panel_spacing_test.dart` was found while planning).
- [ ] **Step 4:** commit `test(ZOD-UI-014): measure the real panel in the token harness`.

### Task 4: Pixel proof of border, radius, padding, head, and no shadow (both themes)

- [ ] **Step 1 (`test/widgets/panel_pixels_test.dart`):** builds **its own** panel on a `bg` page with at least a 32 px margin on every side (the harness's 24 px gutter is too small for the shadow scan). Move `_Pixels` from `panel_spacing_test.dart` to `test/support/pixels.dart` and rename it public `Pixels` (a private class cannot be imported); update its 3 uses and the import in `panel_spacing_test.dart`, no expectation changes, and re-run the spacing test. For Graphite and Porcelain at (1440 × 900, DPR 1) and (390 × 1200, DPR 1):
  - border: the outermost ring pixel away from the corners is `lineSoft` exactly, 1 px wide, then `surface`;
  - radius: pixel (0, 0) is `bg`; the pixel on the diagonal about 3.5 px in (12 × (1 − 1/√2)) is partly covered; the straight edge is full colour from y = 12 down (first fully bordered row equals the radius token within 1 px);
  - padding and head: content offsets 1 + `panelPadding` and 1 + head + `panelPadding` in both themes (the spacing test covers Graphite only);
  - **no shadow:** every pixel in a 32 px ring around the outer edge, excluding the corners' own anti-aliased pixels, equals `bg` in both themes. Control: the same scan on a panel inside a `DecoratedBox` with `ZodiannElevation.floating` must **fail** (proves the detector sees a shadow).
  - Run `fvm flutter test test/widgets/panel_pixels_test.dart`: passes.
- [ ] **Step 2 (mutation proof, throw-away edits, each reverted, each run named):** M1 add a `BoxShadow`; M2 radius 8; M3 border `line`; M4 border width 2; M5 padding 16 on regular; M6 head 56 on phone; M7 drop the head rule; M8 default `Clip.antiAlias` (caught by Task 2 test 11); M9 head vertical padding swapped (caught by Task 2 test 5). Each must fail at least one test; record test names per mutant under Verification in PROGRESS.
- [ ] **Step 3:** commit `test(ZOD-UI-014): prove border, radius, spacing and no shadow by pixels`.

### Task 5: Compare with the designer's screen (conditional)

- [ ] **Step 1:** `04-settings_desktop_en_dark.png` is 1440 wide, so 1× (panel top y = 88, a 56 px head, head rule y = 144, checked by eye by the plan reviewer). Confirm by a pixel scan: panel left / right edge x, top y, head rule y, border and fill colours. If a clean scan is not possible with reasonable effort, **drop the task and record why** (criteria 1 and 2 are already proved by Tasks 3 and 4).
- [ ] **Step 2:** `test/widgets/panel_reference_test.dart` asserts only the shell and head (edges, head rule offset, colours within ±1 px / ±1 channel, as UI-004 / UI-009); the panel's rows are owned by the SET tasks and are not compared. The fixture is read from `design-reference/…`, never copied; the test skips with a stated reason if the file is absent.
- [ ] **Step 3:** commit `test(ZOD-UI-014): compare the panel with the settings reference`.

### Task 6: Verification, review, documentation

- [ ] **Step 1 (root):** `fvm dart run melos run lint` and `fvm dart run melos run test`. Record exit codes and counts.
- [ ] **Step 2:** `requesting-code-review`: one fresh-reviewer pass over the whole branch; fix Important findings test-first.
- [ ] **Step 3:** `verification-before-completion`. Update the task file (status, ticked criteria with evidence), `TASKS.md`, `PROGRESS.md` (plan path, decisions, verification with commands and head commit, git state); push, open the PR, add the PR link in a follow-up commit.

## Acceptance criteria mapping

| Criterion | Proof |
|---|---|
| 1. Padding / radius / border match token values exactly | Task 2 tests 1, 4, 5; Task 3 (`panel_spacing_test` unchanged on the real widget); Task 4 border, radius, padding and head pixels in both themes; mutants M2 to M6, M9 |
| 2. No drop shadow in the dark theme except floating layers | By construction (no elevation input); Task 2 test 1 (no `boxShadow`); Task 4 ring scan with a positive control; mutant M1. Floating layers keep `ZodiannElevation.floating` in their own components (drawer, UI-013, UI-012), unchanged |

## Execution mode

Sequential, native (`executing-plans`). The tasks share two files (`zodiann_panel.dart`, the harness) and each builds on the previous one's tests, so there is **no independent work** and no subagent justification.

## Risks

- Flutter may lay out text lines up to 1 px differently from Chrome; the pixel tests use an empty head (as the UI-003 harness does) for exactness, and the reference test allows ±1 px (measured in Task 5).
- Clipping default (O2): no clip matches the CSS and protects focus rings, but a full-bleed child with its own background paints over the 12 px corners. Callers opt in; UI-010 (tables) must decide at its planning.
- Head layout: a custom layout delegate is the most code in this task and the head's height depends on content width; Task 2 tests 6, 7 and 9 pin the cases that exist in the design. The delegate must report intrinsic sizes sensibly or the panel must not be used inside intrinsic measurement (document it).

## Open decisions (for the owner; defaults are implemented)

- **O1: head vertical sizing.** Settled by the reference, confirm only: padding 16 (regular) / 12 (phone), minimum height 56 / 52, grows for taller content (`kit.css:178`, `settings.html:33`, `wheel.html:55`).
- **O2: clip default.** Default `Clip.none` (faithful to CSS, keeps focus rings), opt-in `Clip.antiAlias`. Alternative: always clip to the 12 px radius (safer for tables, can cut focus rings at the edges).
- **O3: API shape.** Default `ZodiannPanel(head:, bodyPadding:, clipBehavior:, child:)` plus `ZodiannPanelHead(title:, meta:, leading:, end:)`, strings for title and meta so the header semantics and style live in one place; `leading` and `end` accept any widget. Alternative: a free-form `head` widget.
- **O4: title / meta overflow.** Default: wrap, as the CSS does, so nothing is truncated at large text scale or in long Hebrew strings (the head grows). Alternative: one line with ellipsis (predictable height, needs a tooltip or full semantics label).

## Plan review

**Round 1** (`plan-reviewer`, comprehensive). Verdict: needs user decision; no Critical.

| ID | Severity | Finding | Done |
|---|---|---|---|
| I1 | Important | O1 and the head-height risk rested on a wrong reading of kit.css; phone padding is 12 / 16 with `min-height: 52` (`settings.html:33`, `wheel.html:55`) | Applied (checked against the files); head sizing, heights 73 / 65 and test 5 added; O1 reduced to a confirmation |
| I2 | Important | Wrap / overflow behaviour of the head unspecified (wheel panel wraps on phone) | Applied (mechanism replaced in round 2, see I7): tests 6 and 7 |
| I3 | Important | RTL test wording wrong | Applied: test 8 reworded |
| I4 | Important | No exact commands or expected RED reasons | Applied: commands, working directory, expected failures, guard test named |
| I5 | Important | Clip test under-specified | Applied: `Transform.translate` pixel construction; hit-test only if verified; M8 mapped to test 11 |
| I6 | Important | Harness switch changes what is measured | Applied: stated in Task 3; test 4 (empty head is exactly 56 / 52) added |
| M1 | Minor | Ellipsis hides information | Became O4 (default: wrap) |
| M2 | Minor | `letter-spacing` difference | Applied: recorded in Facts |
| M3 | Minor | "Flutter rounds line heights" stated as fact | Applied: reworded in Risks |
| M4 | Minor | Pixel test margin and Graphite-only spacing test | Applied: Task 4 builds its own panel with a 32 px margin |
| M5 | Minor | Task 5: PNG is 1×; only shell and head | Applied |

**Round 2** (`plan-reviewer`, focused on the revision, commits `02a1793..1e05655`). Verdict: approve after corrections; round 1 items I1 to I6 and M1 to M5 confirmed applied.

| ID | Severity | Finding | Done |
|---|---|---|---|
| I7 | Important | `Wrap` cannot push `end` to the end edge, and would drop `end` below a long title on desktop where kit.css does not wrap | Applied: `CustomMultiChildLayout` with explicit rules 1 to 4 (fills panel width; wrap-below only on phone); test 7 split into cases a to c, LTR and RTL |
| I8 | Important | `_Pixels` is library-private; a "pure move" cannot work | Applied: move and rename to public `Pixels`, update 3 uses and the import |
| M6 | Minor | Centring and rule-inside-56/52 construction unstated | Applied: `ConstrainedBox(minHeight: panelHeadHeight - hairline)` plus rule |
| M7 | Minor | Run spacing named as a literal | Applied: `ZodiannSpace.s2` / `s3` named in the layout rules |
| M8 | Minor | Test 7 width derivation | Applied: built from a `LayoutBuilder` in the test |
| M9 | Minor | Harness panel must keep stretching | Applied: sentence in Task 3 |

Two rounds are used. Open items for the owner: O2, O3, O4 (defaults implemented).
