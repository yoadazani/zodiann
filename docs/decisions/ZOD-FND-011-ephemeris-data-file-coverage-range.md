# ZOD-FND-011: the ephemeris data-file coverage range and the supported date range

> **Status: owner decisions recorded 2026-11-25.** Nothing here claims device verification of the data-file edges; they are nominal (section 3). The contract amendment in section 7, including the product-range enforcement for **every body, the mean node included**, is **approved (owner, third message, 2026-11-25, Option A) to be implemented in ZOD-FND-011 (Task 7 of the plan); at this revision it is NOT yet implemented**, and this record will say "implemented" with commit hashes only after it is. **ZOD-EPH-002 remains responsible only for the production DI wiring** (and for adding its adapter to the guard allowlist). Plan: [`docs/plans/ZOD-FND-011-ephemeris-data-file-coverage-range.md`](../plans/ZOD-FND-011-ephemeris-data-file-coverage-range.md).

## 1. Decision

The owner approved **Option 2** (2026-11-25): keep the existing Swiss Ephemeris data files `sepl_18.se1` and `semo_18.se1` (nominally 1800 to 2400, no neighbouring 600-year block), and limit the user-facing supported date range to **1900-01-01 through 2100-12-31 inclusive**.

Two ranges are kept apart everywhere:

| | Physical data-file coverage | Supported product range |
|---|---|---|
| What it is | what the packaged files contain | what the app lets a user use |
| Value | nominally 1800-01-01 to 2400-01-01 (**not device-verified**) | 1900-01-01T00:00:00Z to 2100-12-31T23:59:59.999999Z |
| Owner | the Swiss adapter (ZOD-EPH-002) | `SupportedDateRange` in `astro_core` (`packages/astro_core/lib/src/ephemeris/supported_date_range.dart`) |
| Runtime check | `SwissCalcResult.usedSwissEphemerisFiles` on every call (authoritative) | the product-range decorator and each input route |

## 2. The supported range: exact bounds

`SupportedDateRange.start` = `1900-01-01T00:00:00Z`; `SupportedDateRange.end` = `2100-12-31T23:59:59.999999Z` (the last microsecond of 2100-12-31, so the whole day is inside; both ends inclusive, as `UtcRange`). It is the only definition of the product range; no other file states it.

**Judged on the UTC instant after the caller converts local time to UTC**, never on the local calendar date: a local 1900-01-01 00:00 at UTC+14 is 1899-12-31T10:00Z (outside); a local 2100-12-31 23:00 at UTC-10 is 2101-01-01T09:00Z (outside). The same instant is therefore never valid in one time zone and rejected in another. Boundary tests (one microsecond either side, both converted instants) are in `packages/astro_core/test/ephemeris/supported_date_range_test.dart`.

## 3. Data files and size

- **Set:** exactly `sepl_18.se1` (484,061 B) and `semo_18.se1` (1,304,771 B), 1,788,832 B raw, 1,662,654 B stored in the APK. Pinned by `packages/ephemeris_swiss/test/data_files_test.dart` (exact file set and sizes), so a neighbouring block cannot be added unnoticed.
- **Size impact (existing measured evidence, [`docs/spikes/ZOD-FND-003-swiss-ephemeris-ffi.md`](../spikes/ZOD-FND-003-swiss-ephemeris-ffi.md) section 4):** the release APK grows by **+1,663,124 B per ABI** with the regular dependency: arm64-v8a 18,537,162 to 20,200,286 B; armeabi-v7a 16,157,122 to 17,820,246 B; x86_64 19,788,968 to 21,452,092 B. Option 2 adds no bytes beyond the spike's pair. **Measured on Android builds only**; the iOS size is added by ZOD-IOS-009; ZOD-REL-002 re-checks the final size.
- **The regular `ephemeris_swiss` dependency in `apps/astro_mobile/pubspec.yaml` stays** (the release app carries the files; the spike left this confirmation to FND-011).
- **Nominal, not verified.** "1800 to 2400" comes from the upstream block names. Until ZOD-EPH-002 measures the edges on a device they must not be quoted as measured facts. The spike observed one thing only: at 1799-12-31 with only `sepl_18` present, the library fell back to its built-in ephemeris (flags 260, a `sepl_12.se1 not found` warning). The approved range sits 100 and about 299 years inside the nominal edges, so the exact edge instants cannot affect a supported date.

## 4. Boundary behavior

`P` = the supported range. `F` = the physical coverage of the files (nominal). Applies with the contract amendment of section 7.

| Requested instant `t` (UTC) | Through the decorator (what the app sees) | Swiss adapter alone (tests, oracles) |
|---|---|---|
| `t < P.start` (including `P.start - 1 us`) | `OutsideSupportedRange`; the adapter is not called | `t` in `F`: a true Swiss position. `t` before `F`: `OutOfCoveredRange` (files not used; never the built-in ephemeris) |
| `P.start <= t <= P.end` and the files were used | `EphemerisSuccess` | `EphemerisSuccess` |
| `P.start <= t <= P.end` and `usedSwissEphemerisFiles` is false | `OutOfCoveredRange` = **data unavailable**; no automatic fallback to the built-in ephemeris, no backup swap | same |
| `t > P.end` (including `P.end + 1 us`) | `OutsideSupportedRange` | `t` in `F`: a true Swiss position. `t` after `F`: `OutOfCoveredRange` |
| `t.isUtc == false` | `ArgumentError` (unchanged) | `ArgumentError` |
| `position(Body.node, t)` | inside `P`: the formula result; outside `P`: `OutsideSupportedRange` | the formula result for any `t` (unchanged) |

`OutsideSupportedRange` means the requested instant is outside the product range. `OutOfCoveredRange` means data is unavailable for an instant inside it. Selecting the built-in ephemeris (ZOD-EPH-003) or the backup is only ever an explicit user choice; the decorator applies to every source.

**The backup (Q2).** `AstronomyEphemeris.coveredRange` ends at 2100-01-01T12:00Z (`packages/ephemeris_astronomy/lib/src/astronomy_ephemeris.dart:78-80`). The product range is **not** shortened for it. If the user explicitly selects it for a later instant it may return `OutOfCoveredRange`; that surfaces as unavailable data (`rangeDataUnavailable`), never hidden and never turned into a success. Extending the ACC-1 dataset (section 6) does not change the backup's coverage: they are two separate concerns.

## 5. Accuracy statement

- **Validated today:** the ACC-1 reference set (`packages/astro_core/test/fixtures/reference_dates.json`, 53 instants) spans **1899-12-31T12:00Z to 2100-01-01T12:00Z**. The specification says "from 1900 to 2100".
- **Not validated, and not claimed:** 1800-01-01 to 1899-12-31T11:59Z, 2100-01-01T12:00Z to 2400, and, until ZOD-TST-001 adds the instants (section 6), the last 364 days of the product range.
- **Evidence required before widening the product range** (change `SupportedDateRange` and its tests only): (1) a Horizons reference dataset for the new span in the ACC-1 shape (at least 50 dates, year starts, retrograde neighbourhoods, both ends, all ten bodies); (2) Swiss Ephemeris within one arcsecond of it for the Sun and Moon (T-EPH-1) and the per-body bounds recorded; (3) the ZOD-TST-001 vs ΔT decision applied to the new far ends; (4) the crossing oracle (T-CRS-2) rerun over the new span; (5) if the span leaves 1800 to 2400, new data blocks, a re-measured size (section 3) and a new decision record; (6) the Excel floor rechecked (section 8); (7) the owner's approval.
- **The ΔT warning stays.** It is an in-range concern (the forecast ΔT between now and 2100) as well as a far-future one. ZOD-EPH-002 exposes the flag and ZOD-NFR-017 shows it; this task invents no threshold and does not remove it because the date picker is narrower.

## 6. ZOD-TST-001: extend the ACC-1 dataset (approved, Q2)

ZOD-TST-001 extends the reference dataset through 2100-12-31 (the file is add-only: add instants and increment `version`, never change or drop one). The extension **must preserve the exact production UTC-to-TT conversion path and compare equivalent TT instants** (as ZOD-EPH-004 established; see [`docs/spikes/ZOD-EPH-004-delta-t.md`](../spikes/ZOD-EPH-004-delta-t.md)). It must not compare different astronomical instants and must not change the established accuracy contract. Not edited by this task (the ZOD-TST-001 task file receives its Notes line when that task is planned).

## 7. FND-002 contract amendment (approved, Q1 option A; to be applied in ZOD-FND-011 Task 7, not yet implemented at this revision)

**What changes**, and nothing else:

1. **`EphemerisPort.coveredRange` doc comment** (`packages/astro_core/lib/src/ephemeris/ephemeris_port.dart`). Proposed text: "The inclusive UTC range the source's data physically covers. It is not the product's supported range: the app limits date input with `SupportedDateRange`. Outside it, [position] returns [OutOfCoveredRange]." The sentence "The app's UI uses it to limit date input" is removed.
2. **A new sealed subtype** in `ephemeris_result.dart`:

   ```dart
   /// The requested moment is outside the product's supported date range
   /// ([SupportedDateRange]), whatever the source could compute.
   final class OutsideSupportedRange extends EphemerisFailure {
     const OutsideSupportedRange({required this.requested, required this.supported});
     final DateTime requested; // UTC
     final UtcRange supported; // for the user-facing message
     // value equality and toString, like OutOfCoveredRange
   }
   ```
   `OutOfCoveredRange` keeps its meaning (data unavailable for an instant the source was asked about); its doc comment gains: "inside the supported range this is a defect, never hidden".
3. **A shared decorator in `astro_core`** (`SupportedRangeEphemeris implements EphemerisPort`, to be built in ZOD-FND-011 Task 7): for any body **including `Body.node`**, `position` returns `OutsideSupportedRange` when `SupportedDateRange.classify(utc)` is not `inside`, and otherwise delegates; `coveredRange` delegates to the wrapped source (physical coverage). The port's node sentence "returns `EphemerisSuccess(meanAscendingNode(utc))` for any utc" gains: "except through the product-range decorator".
4. **The raw mean-node API (resolved by the owner, Option A, 2026-11-25; to be implemented in Task 7).** `meanAscendingNode(DateTime)` returns an `EclipticPosition` with no failure channel, so the decorator cannot return `OutsideSupportedRange` from it, and it must not throw. Decision: the decorator limits **every body, the node included, through `position()`**; `meanAscendingNode()` is unchanged (no signature change, no exception) and is the unlimited formula primitive; the raw API (`meanAscendingNode`, `meanAscendingNodeAt`, the `MeanAscendingNodeFormula` mixin) is closed against bypass by an architecture guard that allows only the justified formula and source-implementation files, and a second guard requires every production binding of `ephemerisPortProvider` to wrap its source in `SupportedRangeEphemeris(`. Until Task 7 is implemented, nothing enforces the range.

**Exhaustive switches that must handle the new subtype** (found by grep over `apps/` and `packages/`, 2026-11-25): exactly one existing site, `describe` in `packages/astro_core/test/ephemeris/ephemeris_port_contract_test.dart:35`, a switch over `EphemerisResult` with no default branch (it stops compiling until `OutsideSupportedRange` is added). The non-exhaustive `is EphemerisSuccess` checks in `apps/astro_mobile/test/di/support/port_consumer.dart:16` and `apps/astro_mobile/integration_test/astronomy_speed_vs_swiss_test.dart:181` stay valid. Every future consumer (ZOD-NFR-017, the wheel, the crossing API) must switch exhaustively. No other contract change is made.

## 8. Excel cross-check

- Excel's pre-1900 limit applies **only to the Square's date-anchor export** (ZOD-XLS-017). The specification floor stays: a date before 1900-01-01 is rejected for export. It does not restrict wheel calculations or the ephemeris range.
- Every supported ephemeris date is on or after 1900-01-01, so the product range never produces a date Excel cannot hold.
- **Square anchors are not limited to 1900 to 2100 (approved, Q3).** The Square uses calendar arithmetic and has no dependency on the ephemeris (`packages/feature_square` and `packages/gann_core` import nothing from `astro_core`; grep, 2026-11-25).
- **Open compatibility issue for ZOD-XLS-017 and ZOD-XLS-001 (Q4).** Excel's 1900 date system counts a non-existent 1900-02-29, so serial numbers for 1900-01-01 to 1900-02-28 are expected to differ by one day from LibreOffice and Google Sheets, and the export uses `=Anchor + k` (EX-9). This is **not verified**. Those tasks must test January and February 1900 in Microsoft Excel, LibreOffice Calc and Google Sheets before deciding whether a different export floor (for example 1900-03-01) or handling is required. The floor does not move without that verification.

## 9. Spec deviation

Specification line 368 (Computation settings, "Date range") reads "According to the coverage of the data files that are packaged". The approved product range is narrower than the packaged files. **The specification text is unchanged** (owner, Q6a): this record is the place the deviation is recorded; only the owner edits the specification.

## 10. User-facing messages (approved exact text, an exception to the kit.js-only copy rule, 2026-11-25)

In `packages/shared_ui/lib/l10n/app_en.arb` and `app_he.arb` (generated into `ZodiannLocalizations`):

| Key | English | Hebrew |
|---|---|---|
| `rangeOutsideSupported(start, end)` | This date is outside the supported range ({start} to {end}). Choose a date within it. | התאריך מחוץ לטווח הנתמך ({start} עד {end}). בחרו תאריך בתוך הטווח. |
| `rangeDataUnavailable` | Position data for this date is not available on this device. | נתוני המיקום לתאריך זה אינם זמינים במכשיר. |

`rangeOutsideSupported` is for `OutsideSupportedRange` (the user chose an unsupported date); the callers pass the bounds already formatted (date order per ZOD-L10-010, Western digits per ZOD-L10-012). `rangeDataUnavailable` is for `OutOfCoveredRange` (data missing). The ΔT-forecast banner is a third message owned by ZOD-NFR-017 and is untouched.

## 11. Ownership and hand-off map

Nothing below is written into the other task files now (owner, Q6b). Each row becomes a Notes line when that task is planned.

| Task | Hand-off | Why |
|---|---|---|
| [ZOD-EPH-002](../development/computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) | The production DI wiring only: binds the source in `appOverrides` wrapped in `SupportedRangeEphemeris(` (the DI guard fails otherwise) and adds its adapter file to the `node_bypass` allowlist with a justification; implements the section 4 boundary table for the adapter; keeps the per-call `usedSwissEphemerisFiles` guard; measures the physical edge instants on a device; owns the ΔT-forecast flag, call serialization and source selection | exact boundary behavior lives here |
| [ZOD-EPH-003](../development/computation-engine/ZOD-EPH-003-implement-the-swiss-ephemeris-built-in-moshier-fallback-mode.md), [ZOD-EPH-004](../development/computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md) | the product range also applies to the built-in mode and the backup; the backup's range ends 2100-01-01T12:00Z, so `OutOfCoveredRange` for a later instant surfaces as unavailable data | one range for every source |
| [ZOD-CRS-004](../development/computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md) | the core rejects From/To outside `SupportedDateRange` with a typed error (not only the 3,660-day span; a From after about 2090-12-31 plus 3,660 days passes 2100-12-31); the solver never probes beyond To | the core, not the UI, enforces |
| ZOD-WHL-011, 012, 013, 014, 016, 017, 019, 020, 022, 023 (`development/zodiac-wheel/`) | each input route validates the converted UTC instant; playback and step buttons stop at the edge; Now and the initial state handle a device clock outside the range; the default "today to one year ahead" filter is clamped near 2100 | every route can cross the edge |
| [ZOD-NFR-017](../development/performance-accessibility-reliability/ZOD-NFR-017-implement-the-t-forecast-and-out-of-range-warning-banners.md) | the out-of-range banner uses `rangeOutsideSupported`, data-missing uses `rangeDataUnavailable`; the ΔT threshold stays its own | section 10 |
| [ZOD-SQR-002](../development/gann-square/ZOD-SQR-002-build-the-anchor-field-and-anchor-to-today-now-shortcut.md), ZOD-SQR-004 | the Square anchor is not limited to 1900 to 2100; only the Excel export rule applies | Q3 |
| [ZOD-XLS-017](../development/excel-export/ZOD-XLS-017-document-the-excel-exports-known-limits.md), ZOD-XLS-001, ZOD-XLS-012 | the pre-1900 rejection is export-only and the floor stays 1900-01-01; test January and February 1900 in Excel, LibreOffice Calc and Google Sheets before any change | Q4 |
| ZOD-TST-001 (`development/testing-qa/`) | extend the ACC-1 reference through 2100-12-31 on the production UTC-to-TT path, equivalent TT instants | Q2, section 6 |
| ZOD-ABT-003, [ZOD-REL-002](../development/release-preparation/ZOD-REL-002-finalize-and-verify-the-native-build-pipeline-cmake-xcode-native.md) | the method table shows the range from `SupportedDateRange`; REL-002 re-checks the data-file size; the iOS size stays ZOD-IOS-009 | one source of truth |
| [ZOD-FND-011](../development/foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md) | the task file's citation is corrected from SQ-10 (square size) to SQ-5 (the anchor field) | traceability |

## 12. Consumers that can cross the edge

The wheel's moment can leave the supported range through: the date field (WHL-014), Now (WHL-014, and the initial state of WHL-023 when the device clock is wrong), the step buttons (WHL-016), playback at one step per 110 ms (WHL-017, the likeliest to run past an edge), change-date drag (WHL-011), keyboard and accessibility actions (WHL-012, WHL-013), and a tapped crossing row (WHL-019, WHL-022). The crossing table's From and To (WHL-020, CRS-004): the default "today to one year ahead" runs past 2100-12-31 once today is 2100-01-01 or later, and a 3,660-day span runs past it from a From of 2090-12-31 or later (3,660 days is about 10 years). The UI alone is not the enforcement point: the position decorator and the core crossing API enforce the range, and the UI validates the converted instant and shows the section 10 message (NFR-R2).
