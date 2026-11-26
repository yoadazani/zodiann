# ZOD-TST-001: the JPL Horizons reference dataset, design

**Status: written 2026-11-26, awaiting the owner's approval. Nothing is implemented and no Horizons data has been downloaded for it.** Plan: [`docs/plans/ZOD-TST-001-horizons-reference-dataset.md`](../../plans/ZOD-TST-001-horizons-reference-dataset.md).

Sources of truth: the [task file](../../development/testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md), specification T-EPH-1, ACC-1, ACC-5 and "Computation settings that must be fixed and documented", the [time-conversion decision](../../decisions/ZOD-EPH-002-time-scale.md), the [ZOD-FND-011 record](../../decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md) sections 5 and 6, and the [ZOD-EPH-002 design](2026-11-25-zod-eph-002-swiss-adapter-design.md) section 6 (hand-off).

## 1. Intent

Give the app one permanent, versioned set of reference longitudes from JPL Horizons that the primary source is judged against, covering 1900-01-01 to 2100-12-31, and validate the mean node separately against Swiss Ephemeris.

**Goals:** one shared dataset consumed by T-EPH-1 and ACC-1; at least 50 instants in 1900 to 2100, all ten bodies, a Horizons-confirmed retrograde instant for each of Mercury to Pluto, year-boundary instants and 2100-12-31; every comparison at the same physical instant; offline re-checks of the dataset's own claims.

**Non-goals:** the backup comparison suite (ZOD-TST-005); the backup's time model (ZOD-EPH-006); the double-precession mutation test (ZOD-TST-004); retrograde marking (ZOD-EPH-005, ZOD-TST-003); any application code, `EphemerisPort`, adapter or specification change; iOS and ARM verification.

**Failure even if it "works":** two sources compared at different instants; a retrograde date accepted on our own calculation; a reference row changing silently; a test whose coverage shrank without being said.

## 2. Owner decisions (2026-11-26)

1. The retrograde criterion applies to **Mercury to Pluto only** (Sun and Moon excluded). Every selected date is confirmed from **JPL Horizons data**, not from our calculations.
2. The backup package **tests** may restrict their assertions to the backup's own supported range. No backup implementation or range change, no weakened guarantee, explicit boundary tests preserved.
3. Every comparison represents **the same instant in TT**. From 1972 the approved conversion; before 1972 no independently estimated UTC value.
4. Lunar node tolerance **0.01°**, to be finalized only after the Swiss setting and frame are verified (section 7: verified).
5. The far-future ΔT blocker is **closed for the Swiss primary source** for this task on its verified accuracy through 2100-01-01. The backup discrepancy **stays open for ZOD-TST-005**.

## 3. Approaches

| Question | Chosen (proposed) | Considered, and why not |
|---|---|---|
| Dataset location | `packages/astro_core/test/fixtures/`, beside the shared date set | In `ephemeris_swiss`: owned by one adapter, yet the backup suite reads it. A root `test/fixtures/`: breaks the established relative-path pattern |
| Device consumption | A generated Dart const copy in `integration_test/`, proved equal by a host test (existing pattern) | A bundled app asset: ships test data to users. `--dart-define-from-file`: a fragile extra step per run |
| Retrograde dates | Explicit candidates from published sources, each confirmed with Horizons before it is committed, with a pre-listed backup per body | Searching daily Horizons series for windows: more downloads, and the dates cannot be reviewed before the download |
| Node validation | A host-generated Swiss fixture checked in CI, plus a live check on the device | Device only: nothing runs in CI. Host only: does not show the shipped library |

## 4. Shared dataset: location and versioning

| File | Role | Versioning |
|---|---|---|
| `packages/astro_core/test/fixtures/reference_dates.json` | the shared instants (existing) | `version` 1 → **2**; add-only: no instant dropped or changed |
| `packages/astro_core/test/fixtures/horizons_reference.json` | **the** shared Horizons dataset (new) | `version` 1, incremented on any change to its rows; `referenceDatesVersion` must equal the date set's `version`, so adding a date without refetching fails a test |
| `packages/astro_core/test/fixtures/swiss_mean_node.json` | node reference from Swiss Ephemeris (new) | `version` 1; `referenceDatesVersion` as above |
| `apps/astro_mobile/integration_test/horizons_reference.dart` | generated copy for devices (new) | regenerated offline from the JSON; a host test compares every row |

**Rows are protected.** The fetch tool compares every new `entries` row with the previous file (for the first run, with the old Swiss TT fixture, 530 rows), and every `utcCrossCheck` row with the previous file's, and writes nothing if a longitude of an existing (body, instant) is lost or differs by more than 0.001″. The control and evidence rows are re-derived and re-checked on every run. **There is no override:** a legitimate change (a revised Horizons solution, a new leap second, which would move later TT values, or a new library ΔT) stops the tool and needs an owner decision. The tool writes `version` 1 when no dataset exists, otherwise the previous version, plus 1 if any row was added or changed.

**Dataset content:**

| Field | Content |
|---|---|
| provenance | endpoint, retrieval date, API version line, each target's printed ephemeris `source:` tag, all query parameters, time-scale text, quantity text, tolerance 1″ |
| `entries` | `body`, `utc`, `jdTt` (nine decimals), `ttMinusUtSeconds`, `longitudeDegrees`; one per body and instant (640 for the proposed set) |
| `utcCrossCheck` | from 1972 only: Horizons asked at the UTC instant (420 rows), with the Julian day sent and the query parameters actually used, so a request made in TT by mistake is detected |
| `timeScaleControl` | before 1972, Moon only: the Horizons-internal proof of section 6 (22 rows) |
| `retrogradeEvidence` | `body`, `utc`, the Julian days asked and Horizons longitudes 3 days before and after (the instant's own longitude is in `entries`) |

The old Swiss TT fixture, its generator, its const copy and its match test are **removed**, so "this exact fixture" is literally true for the primary source. The backup keeps its own two fixtures until ZOD-TST-005.

## 5. Date coverage

All 53 version-1 instants stay. Eleven are added, giving **64** (63 inside 1900 to 2100; 1899-12-31T12:00Z is the existing extra).

| Added instant | Why | Time basis | In the backup's range |
|---|---|---|---|
| 1953-11-18T00:00:00Z | Mercury retrograde | historical ΔT | yes |
| 1956-09-10T00:00:00Z | Mars retrograde | historical ΔT | yes |
| 1971-12-31T23:59:59Z | last second before the leap-second table | historical ΔT | yes |
| 1972-01-01T00:00:00Z | first instant of the table | leap seconds | yes |
| 2012-06-12T00:00:00Z | Venus retrograde | leap seconds | yes |
| 2023-08-01T00:00:00Z | Saturn, Neptune, Pluto retrograde | leap seconds | yes |
| 2023-10-15T00:00:00Z | Jupiter, Uranus retrograde | leap seconds | yes |
| 2049-05-11T00:00:00Z | Mercury retrograde, future | assumed continuous UTC | yes |
| 2100-07-01T00:00:00Z | last year of the range | assumed continuous UTC | **no** |
| 2100-12-31T00:00:00Z | 31 December 2100 | assumed continuous UTC | **no** |
| 2100-12-31T23:59:59Z | end of the supported range, year boundary | assumed continuous UTC | **no** |

Year boundaries: the version-1 set already holds year starts every five years and several 31 December 23:59:59 instants. All ten bodies are evaluated at every instant.

### 5.1 Retrograde candidates (unconfirmed until the download)

| Body | Primary | Published basis | Backup | Published basis |
|---|---|---|---|---|
| Mercury | 1953-11-18 and 2049-05-11 | transits of 1953-11-14 and 2049-05-07 ([NASA Mercury catalog](https://eclipse.gsfc.nasa.gov/transit/catalog/MercuryCatalog.html)) | 2016-05-13 | transit of 2016-05-09, same catalog |
| Venus | 2012-06-12 | transit of 2012-06-06 UT ([NASA Venus catalog](https://eclipse.gsfc.nasa.gov/transit/catalog/VenusCatalog.html)) | 2004-06-14 | transit of 2004-06-08, same catalog |
| Mars | 1956-09-10 | opposition 1956-09-10 ([IMCCE](https://promenade.imcce.fr/en/pages6/887.html), search summary) | 2003-08-28 | opposition 2003-08-28, same source |
| Jupiter, Uranus | 2023-10-15 | published 2023 windows ([Cafe Astrology](https://cafeastrology.com/astrology-of-2023.html), [FOX 10](https://www.fox10phoenix.com/news/7-planets-retrograde-this-summer-nasa)), search summaries | 2024-10-20 | published 2024 windows ([Cafe Astrology](https://cafeastrology.com/astrology-of-2024.html)), search summary |
| Saturn, Neptune, Pluto | 2023-08-01 | as above | 2024-08-01 | as above |

* The transit instants themselves are **not** used: a planet on the solar disk is the extreme case for differences in light-deflection modelling. The candidates sit 4 to 6 days later, inside the window and about 5° to 9° from the Sun (a host figure from the design check, used only to judge distance from the Sun, never to choose or confirm a date).
* **The outer-planet sources are not astronomical authorities** (calendar and news sites read through search summaries; no authoritative table was reachable on 2026-11-26). They only propose dates. The confirmation below decides.

**Confirmation rule (Horizons only).** For each declared (body, instant) t, Horizons longitudes at t − 3 days, t and t + 3 days (TT) must strictly decrease, both steps taken as the shortest signed angle. A failing pair is replaced by the body's backup instant, which must pass the same test (Mercury has two declared instants and one backup, so it can replace only one). If no passing replacement exists, work stops and the owner is asked. No date is chosen by our own computation. A substitution changes the instant and row counts; the new counts are reported.

The three samples show backward motion on both sides of t. They do not locate the stations.

## 6. Time basis: the same instant on both sides

**Every primary comparison asks Horizons in TT** (`TIME_TYPE=TT`, `TLIST_TYPE=JD`) at the TT the app's production path assigns to the instant:

| Instant | JD_TT sent to Horizons | What the app does with the same input |
|---|---|---|
| from 1972, before 2027-06-28 | JD(UTC) + ((TAI − UTC) + 32.184 s) / 86400 | `swe_calc` at that TT |
| from 2027-06-28 | the same with 37 s held, labelled assumption | `swe_calc` |
| before 1972 | JD_UT + ΔT / 86400, ΔT = `swe_deltat_ex(JD_UT, SEFLG_SWIEPH)` of the vendored library with the packaged files (host tool `tt_grid.c`) | `swe_calc_ut(JD_UT)`, which applies that ΔT |

Before 1972 the instant string is only the app's input label, read as UT. No UTC value is estimated: the TT is derived from the app's own conversion, and Horizons is never asked for these rows' primary longitudes at a UT or UTC time.

**Four links prove the instants match:**

1. **Dataset TT = app conversion** (host test): exact recomputation from 1972; before 1972 `jdTt = JD_UT + ttMinusUtSeconds`.
2. **Device TT = dataset TT** (device test, all 64 instants): the adapter's Moon at the input instant equals `calcTt(jdTt)` within 0.0005″ (about 1 ms).
3. **The answer matches the request** (fetch tool, fails closed): the response declares the TT scale, and each row's echoed time (Julian day and fractional seconds) equals the request within 1 ms. The echo proves order and precision only: the same number read as UT would echo the same. Which scale Horizons used rests on the declared scale and on link 4 (before 1972) and the UT cross-check (from 1972).
4. **`TIME_TYPE=TT` is honoured** (fetch tool, re-checked by a host test): at the 22 pre-1972 instants, ask the Moon at `TIME_TYPE=UT` with quantities 30 and 31; take Horizons' own TDB − UT (quantity 30); ask again at `TIME_TYPE=TT` at JD_UT + that value. The longitudes must agree within 0.002″ (TDB − TT, at most about 1.7 ms, is about 0.001″ of Moon motion). This is entirely inside Horizons, so no estimate of ours enters it.

**From 1972** a second, independent check of the app's conversion is kept: Horizons asked at the UTC instant (`TIME_TYPE=UT`, which after 1962 means UTC) agrees with Horizons asked at the app's TT within 0.002″, for all ten bodies, and the device adapter agrees with the UTC-asked values within 1″.

**What changes in an existing gate:** the current "UTC input" device gate also compares the 19 pre-1972 instants with Horizons asked at UT. Horizons applies its own ΔT (and UT1 or the pre-1972 UTC) there, so those rows compare slightly different instants. Under decision 3 they leave the gate; the same instants remain gated at matching TT through the adapter (stronger on the ephemeris, since the instant is exact).

**Limit:** before 1972 both sides use the app's ΔT, so the comparison validates positions at an instant, not the historical ΔT.

## 7. Lunar node: definitions, frame and tolerance

| | App (specification) | Swiss Ephemeris reference |
|---|---|---|
| Definition | mean ascending node, Ω = 125.04452 − 1934.136261·T | `SE_MEAN_NODE` (10): DE404-fitted mean elements with the library's DE431 correction table (`swi_mean_node`) |
| Frame | mean equinox of date (the linear part of the Meeus mean node, which is referred to the mean equinox) | with **`SEFLG_NONUT`**: mean equinox and ecliptic of date |
| Time argument | T from UTC (specification) | TT |
| Light-time, aberration | none | none (`app_pos_etc_mean`) |
| Flags | none | `SEFLG_SWIEPH \| SEFLG_SPEED \| SEFLG_NONUT` (322, returned unchanged) |

**Measured 2026-11-26 on the host** (scratch program, vendored 2.10.03, every day from 1900-01-01 to 2100-12-31, 73,414 instants; TT = UT + Swiss ΔT before 1972, UT + 69.184 s after, at most 27 s above the app's value, under 0.00002° of node motion):

| Swiss variant | Maximum difference from the app formula |
|---|---|
| mean node, `NONUT` (the matching definition) | **0.002160°** (at 1900-01-01) |
| mean node, default flags (true equinox, nutation included) | 0.007296° |
| control: mean node, J2000 | 1.409° |
| control: true node | 1.980° |

**Conclusion.** The definitions are compatible with `SEFLG_NONUT`; **0.01° is finalized on this evidence** (about 4.6 times the observed maximum, consistent with the specification's "less than 0.01°"). The UTC time argument contributes at most about 0.00004°.

**What 0.01° alone cannot catch:** the default-flags variant also passes it. The tests therefore require the reference to carry `NONUT` (and not J2000 or sidereal), and require the J2000 and true-node controls to exceed 0.01°.

**For the owner to confirm (D6):** the matching setting is `NONUT` because the formula's definition is on the mean equinox. Choosing the app's planet frame (true equinox) instead would still pass 0.01°, with a margin of about 1.4 instead of 4.6.

**Observation (no change proposed here):** planet longitudes are on the true equinox of date and the formula node on the mean equinox, so they differ in frame by nutation: at most 0.00527° (19.0″) over the same daily sweep, 1900 to 2100. This follows from the specification's formula.

## 8. Horizons queries

Endpoint `https://ssd.jpl.nasa.gov/api/horizons.api` (GET). [API documentation](https://ssd-api.jpl.nasa.gov/doc/horizons.html) (version 1.3, 2025 June) and [manual](https://ssd.jpl.nasa.gov/horizons/manual.html) (4.98e), read 2026-11-26.

| Parameter | Value | Against the existing tools |
|---|---|---|
| `format` | `text` | same |
| `COMMAND` | `'10'`, `'301'`, `'199'`, `'299'`, `'499'`, `'599'`, `'699'`, `'799'`, `'899'`, `'999'` | same |
| `OBJ_DATA` / `MAKE_EPHEM` | `'NO'` / `'YES'` | same |
| `EPHEM_TYPE` | `'OBSERVER'` | same |
| `CENTER` | `'500@399'` (geocentre) | same |
| `TLIST_TYPE` | `'JD'` | same |
| `TLIST` | space-separated Julian days, nine decimals, in one quoted value, ascending | same (the documentation describes per-value quoting; this form is what returned data in ZOD-EPH-002) |
| `TIME_TYPE` | `'TT'` (primary, evidence, control); `'UT'` (cross-check, control) | same |
| `TIME_DIGITS` | `'FRACSEC'` | was `'SECONDS'` |
| `CAL_FORMAT` | `'BOTH'` | new: echoes the Julian day |
| `QUANTITIES` | `'31'`; `'30,31'` for the control's UT query | 30 is new |
| `ANG_FORMAT` / `EXTRA_PREC` / `CSV_FORMAT` | `'DEG'` / `'YES'` / `'YES'` | same |
| `APPARENT` | `'AIRLESS'` (the default, now explicit) | new |

**Output conventions (documented):** quantity 31 is the "Observer-centered IAU76/80 ecliptic-of-date longitude and latitude of the target centers' apparent position with light-time, gravitational deflection of light, stellar aberration, and optional atmospheric refraction correction", in degrees (the manual's text; it does not name the equinox or nutation there; the repository measured at most 0.56″ against Swiss true-equinox-of-date positions). Quantity 30 is TDB − UT in seconds; UT means UT1 before 1962 and UTC after; unknown future leap seconds are held; ΔT predictions are held constant beyond about 73 days.

**Not documented, checked by the pilot:** the header text for TT output, the printed Julian-day precision, the quantity 30 column label, and the printed decimal places. The pilot answers are inspected before the parser is written. If the output cannot confirm the time to 1 ms, work stops.

**Coverage not verified:** the satellite-solution spans behind 499 to 999 at the last instant, which as TT is 2101-01-01T00:01:08 (the time-spans page did not render). Existing queries succeeded to 2100-01-01. The pilot probes all ten bodies there first; a body with no ephemeris is a stop for an owner decision, with no substitute target or date chosen on our own.

**Pilot (11 requests):**

| Requests | Command | Time type, quantities | Julian days |
|---|---|---|---|
| 1 | Moon | TT, 31 | 2415020.000000000, 2441317.500488241, 2451545.000000000, 2488434.500789167 |
| 1 | Moon | UT, 30 and 31 | 2415020.000000000, 2441317.500000000, 2451545.000000000, 2488434.500789167 |
| 9 | each other body | TT, 31 | 2488434.500789167 |

The second Julian day is 1972-01-01T00:00:00, exactly where the time convention changes. TT and UT answers must agree there within 0.002″; whether Horizons applies the leap-second offset at that exact instant is not established, and a disagreement is a stop (leave the instant out of the cross-check, or choose another boundary instant). The control's TT times are derived from Horizons' own TDB − UT as in section 6.

### 8.1 Requests

| Phase | Requests | Times per request |
|---|---|---|
| Pilot (format, 1972 boundary, last-instant coverage) | 11 | 1 to 4 |
| Retrograde confirmation, primaries and backups (TT) | 8 (Mercury to Pluto) | 6 to 9 |
| Dataset: TT entries | 10 | 64 |
| Dataset: UT cross-check from 1972 | 10 | 42 |
| Dataset: time-scale control (Moon) | 2 | 22 |
| Dataset: retrograde evidence (t ± 3 days) | 8 | 2 to 4 |
| Backup fixtures (only under option A, section 10) | 20 | 61 |
| **Total** | **49, or 69 with option A** | |

Sequential, 1 second apart. The documentation states no API rate limit. A request holds only dates and body numbers, with Dart's default client identification. About 1.2 kB of times at most, well under usual URL limits. Re-running a failed request with the same parameters is within the approval; a new date or parameter is not.

## 9. Tests: what is repointed, changed or left alone

| Existing test or tool | Action |
|---|---|
| `apps/astro_mobile/integration_test/swiss_ephemeris_accuracy_test.dart` (T-EPH-1, ACC-1) | **repoint** to the shared copy: adapter-at-input against Horizons-at-TT (640 rows, new primary gate); matched TT (640); UT cross-check from 1972 (420, was 530 including pre-1972); TT pin (64) |
| `apps/astro_mobile/test/swiss_reference_longitudes_tt_match_test.dart` | **replace** with `horizons_reference_match_test.dart` |
| `packages/ephemeris_swiss/test/reference_tt_fixture_test.dart` | **replace** with `horizons_reference_time_test.dart` reading the shared dataset; it no longer reads the backup's fixture |
| `packages/ephemeris_swiss/tool/fetch_horizons_tt_reference.dart`, its fixture and const copy | **replace** (`tt_grid.c` stays) |
| `packages/astro_core/test/accuracy/reference_dates_test.dart` (ZOD-TST-002) | **change:** add the version-2 instants; the window's end moves from 2100-01-01T12:00Z to `SupportedDateRange.end` (ZOD-FND-011 Q2 approved the extension) |
| `packages/astro_core/test/accuracy/t_eph_2_mean_node_test.dart` | **one test added:** the T = ±1 knowledge moves here, as PROGRESS recorded for this task, naming the three instants beyond it. The existing bound still covers every reference date (about 0.0021° at 2100-12-31, outside the specification's stated ±100 years by under a year) |
| `packages/astro_core/test/ephemeris/supported_date_range_test.dart` | consumes the date set; **unchanged**, expected to pass |
| `apps/astro_mobile/test/astronomy_reference_longitudes_match_test.dart`, `astronomy_reference_longitudes_tt_match_test.dart` | read the backup data; **unchanged**, expected to pass under A |
| `packages/ephemeris_astronomy/test/reference_fixture_test.dart`, `reference_tt_fixture_test.dart` | **restrict** to the backup's range, with explicit tests naming both boundary instants and the excluded ones (section 10) |
| `apps/astro_mobile/integration_test/astronomy_accuracy_test.dart`, `astronomy_speed_vs_swiss_test.dart` | depend on section 10 |
| `apps/astro_mobile/integration_test/swiss_ephemeris_spike_test.dart` (ZOD-FND-003), its fixture, copy and two tests | **left alone** (decision D3) |
| `docs/spikes/ZOD-EPH-004-delta-t/measure_delta_t.dart` | not a test; unchanged |

New: dataset integrity and coverage test (`astro_core`), node host test (`astro_core`), node device test (`astro_mobile`), unit tests of the fetch tool's parser and checks (`ephemeris_swiss`).

## 10. The backup (decisions needed)

Your range restriction covers the three instants after 2100-01-01T12:00Z. It does **not** cover the eight new instants **inside** the backup's range, because its tests require every shared instant to have backup reference rows.

| Option | What happens | Cost |
|---|---|---|
| **A (recommended)** | The restriction is by range only. The two backup fixtures are refetched for the 61 in-range instants (every existing row must be **identical**, otherwise stop and ask), its two fetch tools filter to the range, the device counts go from 53 to 61 instants, and the existing 60″ gate also runs on the eight new instants. **This edits backup test data, tools and device tests, which is more than "update the tests": approving A approves that** | 20 more requests; one more device run; backup test data and ACC-2 evidence grow |
| B | The backup tests assert only the 53 version-1 instants; new instants are left to ZOD-TST-005 | none now, but this **goes further than your wording**: the "every shared instant in range" requirement is narrowed |

Neither changes the backup's implementation, range, tolerance or boundary tests.

**Speed test (only under A):** its frozen speed bounds were set on the 53 instants and a dense Moon set. Recommended: it keeps sampling exactly the 53 (the eight are excluded by name and the count is asserted). Alternative: let it sample 61 and stop if a frozen bound is exceeded.

**Still open for ZOD-TST-005:** the shared dataset's TT is the **primary's** TT. The backup takes UTC and applies its own ΔT, so calling it at a shared instant does not reproduce the shared TT (up to about 133 s apart by 2100, 78.6″ of Moon). Nothing here claims the backup meets the primary's accuracy or time basis.

## 11. Blocker closure

**Closed for the Swiss primary source, for this task:** all ten bodies were within 0.56″ at the 53 instants through 2100-01-01T12:00Z on the x86_64 emulator (ZOD-EPH-002). **The extension to 2100-12-31 is not yet verified**; this task's own gate verifies it. ARM devices and iOS remain unverified. **The backup discrepancy stays open.**

## 12. Limits

* Swiss data files and Horizons both descend from JPL ephemerides: the comparison checks time handling, the apparent-place chain and the packaged files, not orbit theory independently.
* Positions only. No speed reference.
* ACC-1's "same settings": geocentric, apparent, tropical of date; Horizons uses the IAU76/80 model for quantity 31, a difference included in the measured error.
* A future change of the civil time standard would change the post-2027 rows' meaning (decision record section 1).

## 13. Decisions needed from the owner

| ID | Question | Recommendation |
|---|---|---|
| D1 | Backup coverage of the new in-range instants: A (including edits to the backup's test data, fetch tools and device tests) or B (section 10) | **A** |
| D2 | Under A, the speed test's sample | keep the 53 |
| D3 | The ZOD-FND-003 spike test keeps its own six Horizons rows. Two of them (Sun and Moon, 1900-06-15) are pre-1972 UT comparisons. Leave them, or repoint or drop them? The test does not consume this dataset, and Swiss and Horizons ΔT differ by about 0.01 s near 1900 | leave, as a FND-003 binding smoke test; say so if rule 3 should reach it |
| D4 | Accept non-authoritative sources for the outer-planet **candidates**, given that Horizons confirms them | accept |
| D5 | Approve the download of section 8 (49 requests, 69 with A) | with the plan |
| D6 | Confirm the node comparison setting: `SEFLG_NONUT`, mean equinox of date, tolerance 0.01° (section 7) | confirm |

## 14. Left to the builder

Function and test names beyond those in the plan; the layout of the fetch tool's internals; message wording of its failures.
