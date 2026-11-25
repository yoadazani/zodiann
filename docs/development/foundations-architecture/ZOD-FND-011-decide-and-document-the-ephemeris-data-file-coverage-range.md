# ZOD-FND-011 - Decide and document the ephemeris data-file coverage range

## Metadata

- **ID:** ZOD-FND-011
- **Category:** [Foundations & Architecture](../README.md#foundations-architecture) (`foundations-architecture/`)
- **Phase:** Phase 1
- **Priority:** High
- **Status:** Done (see Completion notes)
- **Scope:** MVP

## Description

Swiss Ephemeris data files are split by time period; which range ships with the app determines both app size and the maximum usable date range in the UI (crossing table, square anchors). This decision must be made and documented before interface range limits (WH-16, SQ-5) are finalized.

## Implementation Details

- Evaluate candidate file sets against size budget and the spec's 10-year (3,660-day) crossing-table range and Excel's pre-1900 limitation.
- Record the chosen range and expected app size impact.
- Define the "outside range" user-facing message content (feeds ZOD-WHL and ZOD-SQR validation tasks, R-2).

## Design Reference

No direct design reference applies — this is a data/content decision. The resulting warning banner UI follows `design-reference/zodiann/MASTER.md` §10 "Feedback" (neutral banner for range warnings).

## Acceptance Criteria

- [x] A documented date range is chosen and recorded. *(1900-01-01 through 2100-12-31 inclusive, owner decision Option 2, 2026-11-25; in code as `SupportedDateRange`, `packages/astro_core/lib/src/ephemeris/supported_date_range.dart`, 13 boundary tests; recorded in [`docs/decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md`](../../decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md); the packaged file set is pinned by `packages/ephemeris_swiss/test/data_files_test.dart`.)*
- [x] The "outside range" message text exists and is ready for translation (feeds ZOD-L10). *(`rangeOutsideSupported` and `rangeDataUnavailable` in `app_en.arb` and `app_he.arb`, owner-approved exact text and an exception to the kit.js-only rule, gen-l10n output regenerated, key parity and `l10n:check` green.)*
- [x] The chosen range is cross-checked against the Excel pre-1900 limitation (EX limits section). *(Decision record section 8: every supported ephemeris date is on or after 1900-01-01; the limit concerns the Square date-anchor export only; the floor stays 1900-01-01; the 1900 leap-year issue is recorded for ZOD-XLS-017 and ZOD-XLS-001 to test in Excel, LibreOffice Calc and Google Sheets.)*

## Dependencies

- [ZOD-FND-003](../foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) — Spike: Swiss Ephemeris FFI binding on Android and iOS

## Specification References

- "Data files" row in "Decisions and implications"
- R-2
- "Limits that will remain in the file"

## Notes

- **From ZOD-FND-003 (2026-11-20; superseded by the 2026-11-24 note at the end of these Notes): blocked.** The owner split ZOD-FND-003: its Android half is verified (findings: [`docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md`](../../spikes/ZOD-FND-003-swiss-ephemeris-ffi.md)) and its iOS half is pending (no macOS access; no spending allowed). The specification (R-7, ARCH-6) requires both platforms, so this task stays blocked until a real iOS computation is verified. Its status, scope and acceptance criteria are unchanged. Whether this decision, which needs only the platform-independent size measurements already in the findings (section 4), may start before the iOS half is an owner decision; it is not taken.

- **iOS split (2026-11-24, owner decision):** ZOD-FND-003 is Done for its Android and shared scope (its iOS half is [ZOD-IOS-001](../ios/tasks/ZOD-IOS-001-verify-the-swiss-ephemeris-and-astronomy-engine-ffi-bindings-on-ios.md)), so this task's dependency is satisfied and it is no longer blocked. The earlier open question, whether this decision may start before the iOS half, is resolved: it needs only the platform-independent size measurements in the findings (section 4). The iOS size is added by [ZOD-IOS-009](../ios/tasks/ZOD-IOS-009-finalize-and-verify-the-ios-release-build-pipeline.md). Scope and acceptance criteria are unchanged.

## Completion notes

- **Done 2026-11-25** (Tasks 1 to 7 of the plan) on branch `task/ZOD-FND-011-ephemeris-data-file-coverage-range`, code head `1264646`. Verified: `melos run lint` and `melos run test` succeed (workspace 466 tests, `astro_core` 96, `shared_ui` 992, `astro_mobile` 257); two independent whole-branch reviews found no Critical or Important issue. Not pushed; CI not yet run.
- **Plan and record:** branch `task/ZOD-FND-011-ephemeris-data-file-coverage-range`. Plan: [`docs/plans/ZOD-FND-011-ephemeris-data-file-coverage-range.md`](../../plans/ZOD-FND-011-ephemeris-data-file-coverage-range.md) (two plan-review rounds). Decision record: [`docs/decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md`](../../decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md).
- **What was decided:** keep `sepl_18` and `semo_18` (nominally 1800 to 2400, **not device-verified**; ZOD-EPH-002 measures the edges); the supported product range is 1900-01-01 to 2100-12-31 inclusive, judged on the UTC instant. The FND-002 contract amendment (physical `coveredRange`, a sealed `OutsideSupportedRange`, a product-range decorator that also covers the mean node) is **approved and implemented in this task (Task 7)**: `SupportedRangeEphemeris`, `OutsideSupportedRange`, doc-comment edits to `EphemerisPort`, no existing signature changed, no exception introduced, no adapter changed. The raw mean-node API is closed against bypass by two architecture guards (`test/architecture/node_bypass_test.dart`, `port_binding_test.dart`). **ZOD-EPH-002 only wires the production DI binding**, wrapped in `SupportedRangeEphemeris(`, and adds its adapter file to the node-bypass allowlist.
- **Not changed:** the specification (line 368 deviation recorded in the decision record), the Square anchor scope, the Excel floor, the ΔT warning, and every other task file. The ownership and hand-off map is in the decision record only; a task gets its Notes line when it is planned.
- **Citation corrected (owner-approved):** the Description cited SQ-10 (square size) for anchors; anchors are SQ-5.
- **For ZOD-TST-001:** extend the ACC-1 reference dataset through 2100-12-31 on the production UTC-to-TT path with equivalent TT instants (decision record section 6).

---

*Part of the [Zodiann development task breakdown](../TASKS.md). Source category: "Foundations & Architecture" — see [`../TASKS.md`](../TASKS.md) for the full index, execution order, and open decisions.*
