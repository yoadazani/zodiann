# ZOD-UI-004 - Implement the button components (primary, secondary, accent-outline, quiet, danger) and their states

## Metadata

- **ID:** ZOD-UI-004
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done
- **Scope:** MVP

## Description

Build the five button variants and their five interaction states exactly as specified.

## Implementation Details

- Primary: `accent` fill, `on-accent` text, weight 600. Secondary: `surface-2` + `line` border (default look). Accent outline: used for time/anchor shortcuts (Now, Show up to today, Anchor to…). Quiet: Cancel. Danger: outline by default, solid inside a confirmation dialog.
- States: hover lightens +12%; focus shows a 2px `focus` ring offset 2; pressed moves 1px down and darkens 6%; disabled is 42% opacity.
- Enforce "at most one primary per region" as a usage convention (documented, reviewed in PRs — not a runtime check).
- 40px height (32 small variant).

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Buttons"; every state is captured in `design-reference/zodiann/components/components_dark.png` and `components_light.png` under "Buttons" (default/hover/press/disabled columns for each variant, plus icon-only variants like the small primary and hamburger).

## Acceptance Criteria

- [x] All five variants × five states render pixel-matching the component sheet in both themes.
- [x] Keyboard focus ring is visible and matches the `focus` token.
- [x] Disabled buttons are non-interactive (no hover/press feedback, 42% opacity).

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Buttons"
- NFR-X5

## Notes

- **Product-owner decisions (2026-11-13):**
  - **D1 icons:** ZOD-FND-009 is not built yet, so `ZodiannButton` takes an optional leading `icon` in a 16 × 16 slot (8 px gap), tinted with the label colour. The sheet cross-check uses a blank placeholder; FND-009 supplies the real icons.
  - **D2 solid danger:** white label on `danger` as designed (`ZodiannStates.onDangerSolid`). Dark is 3.37:1, below AA for 14 px text (NFR-X5); handed to ZOD-NFR-009 and pinned by `button_colors_test.dart`.
  - **D3 touch target:** drawn at 40 / 32 (content width, or the slot width when stretched), inside a layout and hit box of at least 44 × 44 (MASTER §14). Stack buttons 8 apart vertically for the design's 12 px visual gap.
  - **U1 hover animation:** MASTER §12's 150 ms, `Curves.ease`; instant under reduced motion (NFR-X6). Press is instant.
  - **U2:** the 44 target applies everywhere; dense rows (WHL-021, SET-005, DAT-001) were told in their Notes.
- **State model:** the component sheet draws hover as CSS `brightness(1.12)`, pressed as `translateY(1px) brightness(.94)`, focus as a 2 px `focus` outline at offset 2 and disabled at 42 % (`components.html:50–55`). That matches MASTER; kit.css's `:hover` colour swaps (`surface-3`, `accent-strong`) differ, and MASTER plus the sheet win. The filter applies to the whole button layer, so translucent borders clamp at white.
- **Border-box:** the inline content inset is the 1 px border plus padding (17 / 13), as in CSS.
- **Focus-ring contract:** the button paints its complete ring, 4 px beyond the drawn box, whenever no ancestor clips it, and cannot override an ancestor's clip. Consumers keep at least 4 px of clear, unclipped space around buttons; a layout that must clip adjusts its padding so keyboard focus stays visible (hand-offs in UI-013 / UI-014).
- **Full-width slots:** in a tight-width slot (MASTER §6: phone controls go full width) the drawn box stretches to the slot and centres its content (fixed after code review).
- **"At most one primary per region"** is a usage convention (doc comment on `ZodiannButtonVariant.primary`, PROGRESS conventions), not a runtime check.
- **Out of scope here:** icon-only buttons on the sheet — the hamburger (ZOD-NAV-001), back / forward (ZOD-WHL-016) and play / pause (ZOD-WHL-017); their task Notes point at this state model.
- **Evidence:** `packages/shared_ui/test/widgets/button_sheet_test.dart` renders all 25 sheet cells in both themes, the small row and the dialog's solid danger with real input, and compares them with the PNGs using one feature extractor (width ±1, height and pressed offset exact, fill / border ±1 per channel, focus ring exact, label ±3).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
