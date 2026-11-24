# ZOD-IOS-005 - Run the glyph presentation test on iOS

## Metadata

- **ID:** ZOD-IOS-005
- **Category:** iOS (`ios/tasks/`)
- **Parent task:** [ZOD-UI-002](../../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) (criterion 3, iOS run)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Not Started (blocked: needs macOS and Xcode; see Notes)
- **Scope:** MVP

## Description

iOS draws some symbol characters as colour emoji (Apple Color Emoji) unless the text asks for the text presentation. ZOD-UI-002 proved the 29 astrological glyphs stay monochrome on the host and on an Android emulator. This task runs the same proof on iOS.

## Implementation Details

- Run `apps/astro_mobile/integration_test/glyph_presentation_test.dart` on an iOS simulator and a device: zero coloured pixels for all 29 glyphs, in both themes where the test covers them.
- If a glyph renders as colour on iOS, fix it in the typography layer (`ZodiannFonts`, the U+FE0E selector handling) test-first, and record the result in ZOD-UI-002's completion notes.

## Design Reference

`design-reference/zodiann/MASTER.md` §3 (Glyphs row).

## Acceptance Criteria

- [ ] No astrological glyph renders as a colour emoji on iOS. *(ZOD-UI-002 criterion 3, iOS run: "No astrological glyph renders as a color emoji on any tested platform/font configuration." The host and Android runs are recorded there.)*

## Dependencies

- [ZOD-UI-002](../../shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) — host and Android half (Done)
- [ZOD-IOS-002](ZOD-IOS-002-verify-the-app-shell-build-and-runtime-on-ios.md) — needs a working iOS build

## Specification References

- MASTER.md §3

## Notes

- **Blocked: macOS access** (owner constraint 2026-11-20: no spending).

---

*Part of the [Zodiann development task breakdown](../../TASKS.md). iOS-specific tasks live in `docs/development/ios/tasks/`; see [`../../README.md`](../../README.md) and the iOS section of [`../../TASKS.md`](../../TASKS.md).*
