# ZOD-L10-015 - Build the EN/HE × phone/tablet screenshot comparison suite

## Metadata

- **ID:** ZOD-L10-015
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Build the dedicated screenshot test suite (L-19) comparing layout correctness across both languages at both device classes, distinct from but built on the general visual-regression harness ([ZOD-UI-015](../shared-ui-design-system/ZOD-UI-015-build-the-automated-light-dark-en-he-visual-regression-harness.md)).

## Implementation Details

- Capture every major screen at phone and tablet widths, in both languages, in both themes.
- Compare against the design reference's existing `responsive/mobile/*_he_*` and `responsive/tablet/*_he_*` captures where they exist, flagging any screen/breakpoint combination the design reference doesn't cover as a design gap (e.g., no `03-saved-squares` mobile capture exists in `design-reference/`).

## Design Reference

`design-reference/zodiann/responsive/mobile/*` and `responsive/tablet/*` (full inventory — note gaps explicitly, e.g., About/Saved squares lack dedicated mobile captures and must be inferred from the desktop screenshots plus the general phone-layout rules in MASTER.md §6).

## Acceptance Criteria

- [ ] Every screen with an existing `responsive/` capture is verified to match it in the corresponding language/theme.
- [ ] Every screen/breakpoint gap in the design reference (no mobile capture available) is explicitly listed as a design gap in the test report, not silently invented.

## Dependencies

- [ZOD-UI-015](../shared-ui-design-system/ZOD-UI-015-build-the-automated-light-dark-en-he-visual-regression-harness.md) — Build the automated light/dark, EN/HE visual regression harness
- ZOD-L10-004
- ZOD-L10-005

## Specification References

- L-18
- L-19

## Notes

- This task has an **explicit design gap** — no design reference covers it yet. Do not invent a visual treatment; request design work before implementing (see Design Reference above).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
