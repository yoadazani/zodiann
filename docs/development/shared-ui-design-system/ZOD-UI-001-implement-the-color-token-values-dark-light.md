# ZOD-UI-001 - Implement the color token values (dark + light)

## Metadata

- **ID:** ZOD-UI-001
- **Category:** [Shared UI & Design System](../README.md#shared-ui-design-system) (`shared-ui-design-system/`)
- **Phase:** Phase 1
- **Priority:** Critical
- **Status:** Not Started
- **Scope:** MVP

## Description

Fill the `ThemeExtension` skeleton from [ZOD-FND-013](../foundations-architecture/ZOD-FND-013-establish-the-design-token-theme-skeleton-dark-light-colorscheme.md) with the exact token values from the design system, for both themes.

## Implementation Details

- Populate `ZodiannSurfaces` (`bg`, `bg-raised`, `surface`, `surface-2`, `surface-3`, `line`, `line-soft`, `text`, `text-2`, `text-3`, `accent`, `accent-strong`, `accent-soft`, `accent-line`, `on-accent`, `focus`, `scrim`, `danger`, `ok`) with the exact hex/rgba values from MASTER.md §2.1, dark and light.
- Populate `SquareColors` (axis/diag/eighth/cell/center/today/sel-outer/sel-inner, fill/ink/line variants) from §2.2.
- Populate `ZodiacColors` (element colors fire/earth/air/water + tint percentages) and `AspectColors` (conj/soft/hard) from §2.3.
- Populate `BodyColors` (all 11 bodies, dark and light hex) from §2.3.

## Design Reference

`design-reference/zodiann/MASTER.md` §2 "Colour tokens" (complete token tables, this is the literal source of truth — copy values exactly, do not approximate). Verify visually against `design-reference/zodiann/components/components_dark.png` and `components_light.png` ("Colour tokens" swatch grid at the top).

## Acceptance Criteria

- [ ] Every token in MASTER.md §2 has a corresponding value in both themes.
- [ ] A rendered swatch grid (test harness) visually matches `components_dark.png`/`components_light.png`'s token section.
- [ ] No component anywhere references a hex literal instead of a token (ARCH-7).

## Dependencies

- [ZOD-FND-013](../foundations-architecture/ZOD-FND-013-establish-the-design-token-theme-skeleton-dark-light-colorscheme.md) — Establish the design-token theme skeleton (dark + light `ColorScheme`)

## Specification References

- ARCH-7
- MASTER.md §2
- Appendix D

## Notes

Prepared by ZOD-FND-013: the extension types (`ZodiannSurfaces`, `SquareColors`, `ZodiacColors`, `AspectColors`, `BodyColors`), their `tokens` maps (exact MASTER names, for the swatch harness) and the theme wiring exist in `packages/shared_ui`. This task replaces the right-hand sides in `packages/shared_ui/lib/src/theme/tokens/graphite_tokens.dart` / `porcelain_tokens.dart` with MASTER §2's literal values and deletes `placeholder_tokens.dart`. `signTintOpacity` already carries MASTER's 0.10 / 0.09 (FND-013); keep them. The color-literal guard allows literals only in that `tokens/` directory.

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Shared UI & Design System" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
