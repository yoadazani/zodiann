# ZOD-UI-005 - Implement the input/field component

## Metadata

- **ID:** ZOD-UI-005
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done
- **Scope:** MVP

## Description

Build the text/date/number input used throughout (anchor field, time field, cells field, etc.) with its label, leading icon, and state treatments.

## Implementation Details

- Label above the field, 12/500 in `text-2`; field 40px high on `bg-raised` with a `line` border; optional leading icon in `text-3`.
- Focus: `accent` border + 3px `accent-soft` halo. Error: `danger` border + halo, with a message under the field explaining how to fix the value (NFR-R2). Disabled: 45% opacity.

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Inputs"; `design-reference/zodiann/components/components_dark.png`/`_light.png` "Inputs and selectors" section (shows default, focused, and error states for the Anchor and Cells fields specifically).

## Acceptance Criteria

- [x] Default/focus/error/disabled states match the component sheet. (`text_field_sheet_test.dart`: the four sheet text fields (Anchor, Anchor focused, Cells in error, Cells disabled) in both themes through one extractor, plus widget tests of every state; see Completion notes.)
- [x] Error state always renders an explanatory message, never color alone (NFR-X4 principle applied to forms). (Border, halo, alert icon and the message row; an empty or blank message asserts; the message is a live region and part of the field's hint.)
- [x] Invalid input (e.g., text in a date field) triggers the error state rather than crashing (NFR-R2). (Proven at the component boundary only: `errorText` drives the error state and arbitrary typed or pasted text, including unpaired surrogates, never throws. Detecting an invalid date or number is the consumer's job (SQR-002, SQR-003, WHL-014, SET-008, NFR-015): owner decision O2.)

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Inputs"
- NFR-R2

## Notes

_No additional notes._

## Completion notes

- **Delivered:** `ZodiannTextField` (`packages/shared_ui/lib/src/widgets/zodiann_text_field.dart`) on `EditableText`: label, 40 px input, optional 16 px leading icon, placeholder, focus and error halos painted outside the border, the error message row, disabled at 45 %, `ltr` for dates and numbers (L-7), a merged semantics node. Tokens `ZodiannSize.fieldGap` (6) and `fieldHalo` (3), `ZodiannStates.fieldDisabledOpacity` (0.45), and `ZodiannSurfaces.dangerSoft`.
- **Owner-approved defaults (2026-11-23):** O1 `dangerSoft` is a kit.css-only token outside MASTER's token map and pinned against kit.css (MASTER section 10 says only "a halo"; MASTER is not edited); O2 no built-in validator, the caller passes `errorText`; O3 the select field with a chevron is not built here; O4 disabled opacity 0.45; O5 a tap on the label focuses the field.
- **Deviations from the approved plan, all ruled and recorded in `docs/PROGRESS.md`:** an optional `inputWidth` (the sheet narrows only the input box to 120 px, the label keeps the column); an internal sanitizer that removes unpaired UTF-16 surrogates (the engine throws on them); a non-const constructor; a disabled field ignores `errorText` instead of asserting; iOS uses Material's round selection handles because Cupertino's need `cupertino_ui` as a direct dependency (owner decision, open).
- **Not covered:** the Body select (O3); parsing and validating values and their messages; Cupertino-native iOS handles; a device check of touch typing, the selection toolbar in English and Hebrew and the soft keyboard types (no device was authorized); screen-reader announcement of the error message.

- **iOS split (2026-11-24, owner decision):** the open owner decision on Cupertino-native iOS selection handles and the iOS device checks (touch typing, selection toolbar in English and Hebrew, keyboard types) moved to [ZOD-IOS-006](../ios/tasks/ZOD-IOS-006-decide-and-implement-native-ios-selection-handles-and-verify-text-input.md). The Android and host scope here is unchanged.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
