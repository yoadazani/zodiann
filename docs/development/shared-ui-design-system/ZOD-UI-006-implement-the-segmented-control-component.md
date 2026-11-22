# ZOD-UI-006 - Implement the segmented control component

## Metadata

- **ID:** ZOD-UI-006
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done
- **Scope:** MVP

## Description

Build the segmented control used for mode switches (drag mode, square mode, size presets, step size, language, theme, etc.), including its "planned/disabled option" state.

## Implementation Details

- `bg-raised` track with 3px inset; selected thumb is `surface-3` with an inset 1px `accent-line` ring, icon/text at full `text` strength when selected.
- A planned-but-unavailable option (e.g., Sidereal zodiac) renders at 40% opacity and is non-interactive.
- Must stretch full-width on phone (per breakpoint rules, MASTER.md §6) and wrap into a reasonable width on desktop/tablet.

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Segmented control"; `design-reference/zodiann/components/components_dark.png`/`_light.png` ("Segmented, mode" row shows Dates/Date and time selected states, plus Tropical/Sidereal(planned) showing the disabled-option treatment).

## Acceptance Criteria

- [x] Selected/unselected/disabled-planned states match the component sheet pixel-for-pixel. (`segmented_control_sheet_test.dart`: the three sheet rows in both themes through one extractor; see Completion notes.)
- [x] On a phone-width layout the control stretches to fill its row (per MASTER.md §6). (Equal segments filling 390 px, and stacking correctly inside a panel head.)
- [x] The disabled "planned" option cannot be selected by tap, mouse, or keyboard. (Tap, mouse, Enter, Space, Tab and arrow keys, with semantics enabled false.)

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Segmented control"
- MASTER.md §6 "Breakpoints"
- D19

## Notes

_No additional notes._


## Completion notes

- **Delivered:** `ZodiannSegmentedControl<T>` and `ZodiannSegment<T>` (`packages/shared_ui/lib/src/widgets/zodiann_segmented_control.dart`), the tokens `segmentGap`, `segmentIconGap`, `plannedOpacity` and `selectionDuration`, and three additive parameters on the shared pressable (`inMutuallyExclusiveGroup`, `disabledOpacity`, `focusRing`; defaults leave every existing control unchanged). Plan: [`docs/plans/ZOD-UI-006-segmented-control.md`](../../plans/ZOD-UI-006-segmented-control.md).
- **Owner-approved defaults (2026-11-22):** automatic stretch on a phone (`expand` overrides); each enabled segment is a tab stop, Left and Right move focus without selecting; the selected icon is `accent-strong` as in kit.css and the component sheet (the Implementation Details and MASTER section 10 say full-strength `text`; the sheet decides the pixel-for-pixel criterion and the difference is about 11 channel values); the planned option is 40 percent opacity (not the 42 percent of other disabled controls); a narrower parent ellipsizes labels on one line.
- **Layout:** the drawn track is 40 high inside a 44 high layout box, so each segment has a 44 high hit slot; the thumb is 32 high and grows with the text scale (the track and the box grow with it, the thumb stays 4 px inside).
- **Keyboard (a deviation from the plan, recorded in `docs/PROGRESS.md`):** in Flutter 3.50 an `Action` that reports itself disabled does not let a key reach an outer handler, so the control handles all four arrow directions itself and passes Up and Down explicitly to the next enclosing handler.
- **Focus ring:** drawn by the control above the whole row (the next segment can be the selected one, whose opaque thumb would otherwise cover the ring), measured from the thumb.
- **Not covered:** which screens use which control and their strings (D19, whether Sidereal stays visible, is a screen decision); a segment narrower than 44 px keeps its natural width in a 44 px slot, so the visible gap beside it is wider than 2 px.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
