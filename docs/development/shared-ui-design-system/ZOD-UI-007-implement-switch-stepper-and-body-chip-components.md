# ZOD-UI-007 - Implement switch, stepper, and body-chip components

## Metadata

- **ID:** ZOD-UI-007
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** Medium
- **Status:** Done
- **Scope:** MVP

## Description

Build three smaller selection controls used in Settings and the wheel's body filter.

## Implementation Details

- Switch: 40×24, used for Reduced motion override, etc.
- Orb stepper: 36px high, `− value +` layout, used for aspect-orb editing ([ZOD-ASP-002](../computation-engine/ZOD-ASP-002-implement-aspect-orb-configuration-data-flow.md)).
- Body chips: toggleable, `accent-soft` fill + `accent-line` border when on, used for "Visible bodies" selection in Settings and degree-table body filter styling cues.

## Design Reference

`design-reference/zodiann/MASTER.md` §10 "Others"; `design-reference/zodiann/components/components_dark.png`/`_light.png` ("Others" row: switch, orb stepper, body chips, radio list) and `screens/04-settings_desktop_en_dark.png` (orb steppers, body chips in context).

## Acceptance Criteria

- [x] All three controls match the component sheet in both themes. (`others_sheet_test.dart`: the stepper, the on and off switches and the five chips, Graphite and Porcelain, one extractor on the sheet and on the render; the Hebrew stepper against `04-settings_desktop_he_dark.png`. Glyph ink is compared within 3 px and 20 per channel; see Completion notes.)
- [x] Orb stepper respects any min/max orb bounds defined once D-1 is resolved (ZOD-ASP-002). (Proved for caller-supplied bounds: `orb_stepper_test.dart` clamping, inert button at a bound, no call past it, stale values; the real orb limits stay with ZOD-ASP-002 / D-1.)
- [x] Body chips reflect on/off state accessibly (not color-only — see ZOD-NFR-010). (Owner decision O1: sheet-exact chips, no check icon; the state is carried by the `checked` semantics, a tint and border change, and the pill focus ring; `body_chip_test.dart`. The visual difference is small by the sheet's own design, border on vs off about 1.5:1; open for ZOD-NFR-008, the colour-independence audit. The task file cites NFR-010, which is the reduced-motion audit.)

## Dependencies

- [ZOD-UI-001](../shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) — Implement the color token values (dark + light)
- [ZOD-UI-002](../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — Implement the typography scale
- [ZOD-UI-003](../shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) — Implement spacing, radius, elevation, and sizing tokens

## Specification References

- MASTER.md §10 "Others"

## Notes

_No additional notes._

## Completion notes

- **Delivered:** `ZodiannSwitch`, `ZodiannOrbStepper` and `ZodiannBodyChip` in `packages/shared_ui/lib/src/widgets/`; tokens `switchThumb`, `switchThumbInset`, `stepperButtonWidth`, `stepperValueMinWidth`, `stepperGlyph`, `stepperInnerHeight` and the `bodyChip*` sizes; four additive `ZodiannPressable` parameters (`toggled`, `checked`, `slotAlignment`, `focusRingRadius`). Plan: [`docs/plans/ZOD-UI-007-switch-stepper-body-chip.md`](../../plans/ZOD-UI-007-switch-stepper-body-chip.md).
- **Owner decisions (2026-11-24):** O1 sheet-exact body chips (no check icon); O6 and O7 (the Pressable slot alignment and focus ring radius) at their defaults.
- **How to use:** `ZodiannSwitch(value:, onChanged:, semanticLabel:)`; `ZodiannOrbStepper(value:, min:, max:, step:, onChanged:, valueLabel:, decrementLabel:, incrementLabel:, semanticLabel:, valueLabelFor:)` (the caller supplies the bounds and every string; pass `valueLabelFor` to give a screen reader group-level increase and decrease actions); `ZodiannBodyChip(body:, label:, selected:, onChanged:)`. A null `onChanged` disables each.
- **Behaviour worth knowing:** the stepper's bound makes only its own button inert and moves keyboard focus to the other button; a value outside the bounds asserts in debug and counts as the nearest bound in release; the stepper row mirrors in Hebrew (minus on the right, as on the designer's Hebrew settings screen) and the value stays left to right; all three animate over 120 ms (linear, instant under reduced motion).
- **Limits recorded:** Flutter draws the symbol-font glyph about 2 to 3 px higher than Chrome inside a chip, so glyph ink is compared within 3 px (other ink within 2); the sheet has LCD text fringes, so ink colours are compared per channel at their extreme; the chip's on/off contrast is faint by design (about 1.56:1 border on vs off in Graphite, 1.50 in Porcelain, fill 1.17 and 1.13), recorded for ZOD-NFR-008.
- **Not covered:** a device (touch, TalkBack and VoiceOver wording for the switch, which is a button with a toggled state); the stepper in a parent narrower than 122 px; the real orb limits (ZOD-ASP-002, D-1).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
