# ZOD-EXT-011 - ICS calendar export for degree crossings

## Metadata

- **ID:** ZOD-EXT-011
- **Category:** [Optional Extensions](../README.md#optional-extensions) (`optional-extensions/`)
- **Phase:** Phase 5
- **Priority:** Low
- **Status:** Not Started
- **Scope:** Optional Extension

## Description

Generate a calendar event (.ics) for each user-selected degree crossing, so it can be imported into any calendar app. Explicitly marked "Idea" stage in the spec's format table (the only format-export row not already MVP).

## Implementation Details

One VEVENT per selected crossing, with the body/sign/degree/retrograde info in the event title/description.

## Design Reference

No direct design reference applies — not shown in any mockup.

## Acceptance Criteria

- [ ] Generated .ics file imports cleanly into at least one major calendar app with correct event timing.

## Dependencies

- [ZOD-WHL-021](../zodiac-wheel/ZOD-WHL-021-build-the-degree-crossings-results-table-list-and-moon-exclusion-rule.md) — Build the degree-crossings results table/list and Moon-exclusion rule

## Specification References

- "Other formats" table (ics row
- stage "Idea")

## Notes

_No additional notes._

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Optional Extensions" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
