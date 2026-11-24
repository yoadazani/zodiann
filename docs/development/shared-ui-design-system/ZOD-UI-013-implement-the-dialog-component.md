# ZOD-UI-013 - Implement the dialog component

## Metadata

- **ID:** ZOD-UI-013
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Done
- **Scope:** MVP

## Description

Build the modal dialog shell used for delete confirmation, save-square naming, and any other confirm/cancel flow.

## Implementation Details

- 420px wide, 16px radius, 20/600 title, actions aligned to the end.
- Must trap focus while open and restore focus to the triggering control on close (accessibility parity with the drawer's NFR-X3 requirement).

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Dialog"; `design-reference/zodiann/screens/04-settings_delete-dialog_desktop_en_dark.png` (the one fully mocked dialog instance — use it as the literal reference for spacing, button placement, and copy tone).

## Acceptance Criteria

- [x] Dialog matches `04-settings_delete-dialog_*` in both themes. (`dialog_sheet_test.dart`: dark English against the designer's screenshot; light and Hebrew against generated references; the sheet's Save-square dialog in both themes; see Completion notes for which images are generated.)
- [x] Focus is trapped inside the dialog while open and returns to the trigger on close. (`dialog_route_test.dart`: Tab and Shift+Tab, also under an extra focus scope, restore after every way of closing for a keyboard-opened trigger; a pointer-opened trigger holds no focus, owner decision O6.)
- [x] Escape/backdrop-tap closes the dialog without taking the destructive action. (`dialog_route_test.dart`: Escape, scrim taps at four points and the back button complete with `null` and call no button callback.)

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens
- [ZOD-UI-004](../shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md) — Implement the button components (primary, secondary, accent-outline, quiet, danger) and their states

## Specification References

- DATA-10
- MASTER.md §10 "Dialog"
- NFR-X3 (focus parity)

## Notes

- **Floating layer (ZOD-UI-003):** use `ZodiannElevation.floating` (the theme extension) for the shadow, plus `floatingOutline` (1 px `line`) painted *outside* the box, e.g. as `BoxShadow(color: side.color, spreadRadius: side.width)` after `floating`. The outline applies in both themes (product-owner decision, 2026-11-13).

- **Buttons (ZOD-UI-004):** use `ZodiannButtonVariant.dangerSolid` for the destructive confirmation and `quiet` / `secondary` for Cancel; actions sit 8 apart horizontally. Focus-ring contract: the button paints its complete focus ring, 4 px beyond the drawn box, whenever no ancestor clips it, and it cannot override an ancestor's clip. Keep at least 4 px of clear, unclipped space around each button wherever the ring can appear; if the layout must clip, adjust its padding so keyboard focus stays visible.

## Completion notes

- **Delivered:** `ZodiannDialog` (the box) and `showZodiannDialog<T>` (the modal route), `packages/shared_ui/lib/src/widgets/zodiann_dialog.dart` and `zodiann_dialog_route.dart`; the token `ZodiannSize.dialogWidth` (420) and the text role `ZodiannTextStyles.dialogTitle` (20 / 1.45 / 600, kit-derived, not a row of MASTER section 3); `tool/dialog/render_dialog_references.dart` and its generated light and Hebrew delete-dialog images (`packages/shared_ui/test/fixtures/dialog/`, README says they are generated).
- **Which images are the designer's:** only the dark English delete dialog (`screens/04-settings_delete-dialog_desktop_en_dark.png`) and the component sheet's Save-square dialog (both themes). The **light and Hebrew delete dialogs are generated** from the kit with headless Chrome, not the designer's; the generator's dark English output is compared with the designer's image first.
- **Owner decisions (2026-11-23):** O1 no built-in confirm helper; O2 no animation; O3 no automatic initial focus (pass `autofocus: true` to a button, Cancel for a destructive confirmation); O4 a `dialogTitle` role; O5 a generated light and Hebrew reference; O6 focus returns to whatever held it when the dialog opened (a keyboard-opened trigger), a pointer-opened trigger held none.
- **Behaviour worth knowing:** Escape, a scrim tap and the back button close the dialog with `null` and run no button callback, so treat only an explicit value (say `true`) as consent. There is **no re-entry guard**: disable the trigger while the future is pending, or a second tap stacks a second dialog. Tab and Shift+Tab loop over the dialog's controls (`closedLoop`); the route sits on the root navigator, covers the top bar, scrolls when the box does not fit and rises above the keyboard. The box adds the regular button's 2 px tap margin to the gaps so drawn buttons sit where the reference has them (it assumes regular, 40 high buttons).
- **Rulings and limits:** the ring and the floating shadow are two nested layers so the shadow paints over the ring as in the kit; flutter_test turns shadows off (`debugDisableShadows`), so the pixel tests turn them back on (`_withShadows`); Flutter rounds the message's three lines to 60 px where Chrome gets 60.9, so the box is 209 high against 210 and sits on a half pixel (height within 2, ring compared on the left side, buttons measured from the bottom); the `closedLoop` flag and the `semanticsDismissible` override are defensive, because the tests cannot observe their removal (this SDK already keeps Tab in the dialog, and the scrim adds no node without a `barrierLabel`).
- **Not covered:** a device (touch, the soft keyboard, TalkBack and VoiceOver wording, how the shadow looks on screen); the dialog under `go_router`'s back handling (tests use a plain `MaterialApp`); a 320 dp screen at 2x text with a long Hebrew confirm label, which `ZodiannButton`'s one-line ellipsis contract cuts off (a UI-004 follow-up); the title may be announced twice by a screen reader (the route name and the header both carry it); a phone-width (390 px) reference image (covered by the max-width tests).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
