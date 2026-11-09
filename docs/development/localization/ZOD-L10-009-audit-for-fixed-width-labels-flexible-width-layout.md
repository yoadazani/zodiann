# ZOD-L10-009 - Audit for fixed-width labels (flexible-width layout)

## Metadata

- **ID:** ZOD-L10-009
- **Category:** [Localization](../README.md#localization) (`localization/`)
- **Phase:** Phase 4
- **Priority:** Medium
- **Status:** Not Started
- **Scope:** MVP

## Description

Ensure no interface element sets a fixed pixel width for a text label, since Hebrew and English text lengths differ substantially for the same meaning.

## Implementation Details

- Review every label/button/tag built in `shared-ui-design-system/` through `settings-persistence/` for hard-coded width constraints; replace with intrinsic/flexible sizing.
- Include this as a standing item in the visual-check acceptance criteria (L-11 explicitly calls out "a visual check in both languages is part of the acceptance criteria").

## Design Reference

No direct design reference applies to the rule; verify against `design-reference/zodiann/screens/*_he_*` vs `*_en_*` that no Hebrew label is clipped or wrapped awkwardly compared to its English counterpart.

## Acceptance Criteria

- [ ] No component in the codebase sets a fixed width around translatable text.
- [ ] A visual check confirms no clipped/overflowing label in either language at any breakpoint.

## Dependencies

- [ZOD-UI-004](../shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md) through [ZOD-UI-014](../shared-ui-design-system/ZOD-UI-014-implement-the-hairline-panel-component.md)

## Specification References

- L-11

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Localization" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
