# ZOD-UI-008 - Implement the radio-list component (ephemeris source selector)

## Metadata

- **ID:** ZOD-UI-008
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** Low
- **Status:** Done
- **Scope:** MVP

## Description

Build the radio-button list used for the three-way ephemeris source choice in Settings.

## Implementation Details

- Standard radio list row: label, optional trailing badge ("Recommended", "Backup").
- Must support the "Swiss Ephemeris, data files" / "Swiss Ephemeris, built-in (Moshier)" / "astronomy-engine" three options per [ZOD-SET-006](../settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md).

## Design Reference

`design-reference/zodiann/screens/04-settings_desktop_en_dark.png` "Ephemeris source" section (shows the exact radio list with "Recommended" and "Backup" trailing labels); `design-reference/zodiann/components/components_dark.png` "Others" row.

## Acceptance Criteria

- [x] Radio list renders and behaves per the settings screenshot (single selection, trailing badges). (`radio_sheet_test.dart`: English dark, Hebrew dark and Hebrew light, one extractor on the screen and on the render: dot 18 x 18, the 5 px accent ring around an 8 px hole and the 1.5 px line ring, label 30 px from the start edge, the badge on the end edge, each relative to its row; `radio_list_test.dart`: single selection, tap, click, Enter, Space, badges. The mock's rows are about 38 px apart and the widget's 44 (owner decision O1); see Completion notes.)
- [x] Keyboard-navigable (arrow keys move selection, matching NFR-X2's external-keyboard requirement). (`radio_list_test.dart`: one tab stop on the selected row, Down and Right select the next row, Up and Left the previous, wrapping, mirrored in Hebrew; a parent that rejects a change; focus kept when options change; the radio-group semantics. Screen-reader wording on a device is not verified.)

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §9 "Settings"
- NFR-X2

## Notes

_No additional notes._

## Completion notes

- **Delivered:** `ZodiannRadioList<T>` and `ZodiannRadioOption<T>` in `packages/shared_ui/lib/src/widgets/zodiann_radio_list.dart`; tokens `radioDot`, `radioDotBorder`, `radioDotSelectedBorder`, `radioRowPadding`, `radioBadgeText`. `ZodiannPressable` is unchanged. Plan: [`docs/plans/ZOD-UI-008-radio-list.md`](../../plans/ZOD-UI-008-radio-list.md).
- **Owner decision (2026-11-24):** O1, 44 px rows with no gap. This meets MASTER §14's 44 px target and waives its 8 px gap between targets for these dense, full-width rows; the block is about 19 px taller than the mock. O2 to O7 at their defaults (arrows wrap; the ring surrounds the row; 120 ms dot animation; the badge is the row's screen-reader hint; no per-option disabling, `value` may be null; long labels wrap).
- **How to use:** `ZodiannRadioList<String>(options: [ZodiannRadioOption(value:, label:, badge:)], value:, onChanged:, semanticLabel:)`. The caller supplies every string. A null `onChanged` disables the list. It needs a bounded width (the label is `Expanded`): inside `ZodiannPanel` or a stacked settings row it is, in a bare `Row` wrap it in `Expanded`.
- **Behaviour worth knowing:** one row is in the Tab order (the selected one, the first when nothing is selected); arrow keys select and focus (wrapping); with nothing selected an arrow selects the first row (Down, Right) or the last (Up, Left); the already selected row calls nothing; rows are keyed by value.
- **Limits recorded:** the component sheet has no radio list (MASTER §10 and the task file say it does), so the settings screens are the only visual source and the light theme is proved with the Hebrew light screen; Chrome sets the comma of a mixed Hebrew and Latin label with about 8 px of space each side, so label width is compared for Latin-only labels (the start edge, height and centre for all); see `test/fixtures/radio/README.md`.
- **Not covered:** a device (touch, TalkBack and VoiceOver wording of a radio row); the real ephemeris wiring (ZOD-SET-006).

- **iOS split (2026-11-24, owner decision):** the VoiceOver half of the "Not covered" device check moved to [ZOD-IOS-011](../ios/tasks/ZOD-IOS-011-audit-voiceover-and-verify-ios-device-behavior.md); the touch and TalkBack half stays here as an Android device check.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
