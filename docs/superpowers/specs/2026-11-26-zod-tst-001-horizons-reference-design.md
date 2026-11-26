# ZOD-TST-001: the JPL Horizons reference dataset, design

**Status (2026-11-26): Tasks 0 to 4A are done; Tasks 4B to 9 are in progress. The 11 pilot requests are done (section 8).** Plan: [`docs/plans/ZOD-TST-001-horizons-reference-dataset.md`](../../plans/ZOD-TST-001-horizons-reference-dataset.md).

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

**Rows are protected.** The fetch tool compares every new `entries` row with the previous file (for the first run, with the old Swiss TT fixture, 530 rows), and every `utcCrossCheck` row with the previous file's, and writes nothing if a longitude of an existing (body, instant) is lost or differs by more than 0.001″. An existing dataset is always compared, whatever baseline is named. The control and evidence rows are re-derived and re-checked on every run. **There is no override:** a legitimate change (a revised Horizons solution, a new leap second, which would move later TT values, or a new library ΔT) stops the tool and needs an owner decision. The tool writes `version` 1 when no dataset exists, otherwise the previous version, plus 1 if any row was added or changed.

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

### 5.1 Retrograde candidates (confirmed from Horizons, section 5.2)

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

### 5.2 Confirmation result (Horizons, 2026-11-26 22:10 UTC)

Eight requests (Mercury to Pluto, TT, quantity 31), 8 of 8 HTTP 200, one attempt each, all accepted by the parser. **All 17 candidates are retrograde: every primary and every backup. No substitution; `retrogradeDeclarations` stays the primaries and every count in the plan stands.**

| Body | Instant (00:00 UTC) | Role | t − 3 d (°) | t (°) | t + 3 d (°) | Steps (°) |
|---|---|---|---|---|---|---|
| Mercury | 1953-11-18 | primary | 231.6731315 | 227.9389816 | 225.4173393 | −3.7342, −2.5216 |
| Mercury | 2016-05-13 | backup | 49.1933078 | 47.4018151 | 45.8669223 | −1.7915, −1.5349 |
| Mercury | 2049-05-11 | primary | 47.1968723 | 45.3758521 | 43.8165796 | −1.8210, −1.5593 |
| Venus | 2004-06-14 | backup | 76.2455685 | 74.4712110 | 72.8896318 | −1.7744, −1.5816 |
| Venus | 2012-06-12 | primary | 73.9062984 | 72.1447999 | 70.5868259 | −1.7615, −1.5580 |
| Mars | 1956-09-10 | primary | 349.2266378 | 348.3982722 | 347.5727297 | −0.8284, −0.8255 |
| Mars | 2003-08-28 | backup | 336.0180984 | 335.2208439 | 334.4209791 | −0.7973, −0.7999 |
| Jupiter | 2023-10-15 | primary | 43.3480764 | 43.0034023 | 42.6419757 | −0.3447, −0.3614 |
| Jupiter | 2024-10-20 | backup | 81.2380719 | 81.1457628 | 81.0238014 | −0.0923, −0.1220 |
| Saturn | 2023-08-01 | primary | 335.8958339 | 335.7128216 | 335.5211440 | −0.1830, −0.1917 |
| Saturn | 2024-08-01 | backup | 348.7404445 | 348.5977086 | 348.4432217 | −0.1427, −0.1545 |
| Uranus | 2023-10-15 | primary | 52.3191148 | 52.2198113 | 52.1160856 | −0.0993, −0.1037 |
| Uranus | 2024-10-20 | backup | 56.4488215 | 56.3470187 | 56.2410121 | −0.1018, −0.1060 |
| Neptune | 2023-08-01 | primary | 357.4792494 | 357.4342864 | 357.3852831 | −0.0450, −0.0490 |
| Neptune | 2024-08-01 | backup | 359.7456770 | 359.7027412 | 359.6557347 | −0.0429, −0.0470 |
| Pluto | 2023-08-01 | primary | 298.9636611 | 298.8933332 | 298.8236455 | −0.0703, −0.0697 |
| Pluto | 2024-08-01 | backup | 300.7341065 | 300.6637671 | 300.5941736 | −0.0703, −0.0696 |

All answers: `API VERSION: 1.2`, EOP file `eop.261125.p270221`, the same source solutions as the pilot. Kept outside the repository (location in `docs/PROGRESS.md`) with the request log `confirm-retrograde.requests.tsv`. SHA-256:

```
c7c0f475ccd567021e2a3e1474bb456dff3e9216693fddad0de6d6bd50e6c6b1  01_199_TT
bd088dfd2c27835a1fddca345883e44b10bab2792f3e8948b147bf86e43cbffc  02_299_TT
4849f5f3b1fc741a7e57463b9f28d04df72a285a5b49f15d3c131ef27407e055  03_499_TT
89aea1c8666994a5a414e2cec0bf22f9f3192776613d51caeccc0911588b5430  04_599_TT
303a15de4d2989a5365cb0e5e8618e79ceee690397a95e0b73f17240996e7fde  05_699_TT
9ef004678acb1dfdaf97d2fc29b89c1cdceb855b2ba2082e520aac715433aab2  06_799_TT
cea9620dd2a1dee6729a9b0f2ea8ed6fa52595a8747a766be7426053dc912eb7  07_899_TT
c2b0ff72c619758628de497f3d6790bbee01db99af87ee56c960222a71a42ec3  08_999_TT
```

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

**Conclusion.** The definitions are compatible with `SEFLG_NONUT`; **0.01° is verified on this evidence and final: the owner confirmed D6 on 2026-11-26** (about 4.6 times the observed maximum, consistent with the specification's "less than 0.01°"). The UTC time argument contributes at most about 0.00004°.

**What 0.01° alone cannot catch:** the default-flags variant also passes it. The tests therefore require the reference to carry `NONUT` (and not J2000 or sidereal), and require the J2000 and true-node controls to exceed 0.01°.

**Confirmed by the owner (D6):** the matching setting is `NONUT` because the formula's definition is on the mean equinox. Choosing the app's planet frame (true equinox) instead would still pass 0.01°, with a margin of about 1.4 instead of 4.6.

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

**Not documented, so checked by the pilot:** the header text for TT output, the printed Julian-day precision, the quantity 30 column label, the printed decimal places, and the satellite-solution coverage of 499 to 999 at the last instant, which as TT is 2101-01-01T00:01:08. The stop conditions were: no ephemeris for a body there; a time that cannot be confirmed to 1 ms; quantity 30 under 3 decimals of a second; longitude under 7 decimals of a degree; TT and UT disagreeing by more than 0.002″ at the 1972 boundary. All passed (results below).

**Pilot (11 requests, sent 2026-11-26; not repeated):**

| Requests | Command | Time type, quantities | Julian days |
|---|---|---|---|
| 1 | Moon | TT, 31 | 2415020.000000000, 2441317.500488241, 2451545.000000000, 2488434.500789167 |
| 1 | Moon | UT, 30 and 31 | 2415020.000000000, 2441317.500000000, 2451545.000000000, 2488434.500789167 |
| 9 | each other body | TT, 31 | 2488434.500789167 |

The second Julian day is 1972-01-01T00:00:00, exactly where the time convention changes (the TT request asks it 42.184 s later). The control's TT times are derived from Horizons' own TDB − UT as in section 6.

The requests were sent by a throwaway script outside the repository, with exactly the parameters above, between 18:41:32 and 18:41:50 UTC; all returned HTTP 200. The owner accepted these answers as the completed pilot (2026-11-26): **they are not repeated, and the repository tool has no pilot mode.**

### 8.1 Verified output format

Answers are plain text with LF line endings. In order:

| Line (as printed, trailing spaces omitted) | Note |
|---|---|
| `API VERSION: 1.2` | the documentation read at planning was 1.3; recorded, not asserted |
| `API SOURCE: NASA/JPL Horizons API` | |
| `Target body name: Moon (301)                      {source: DE441}` | the number in parentheses is the `COMMAND` |
| `Center body name: Earth (399)                     {source: DE441}` | |
| `Center-site name: GEOCENTRIC` | the answers never print `500` |
| `Start time      : A.D. 1899-Dec-31 12:00:00.0000 TT` | ends in the time scale, ` TT` or ` UT` |
| `Stop  time      : A.D. 2101-Jan-01 00:01:08.1840 TT` | two spaces after `Stop`; ends in the scale |
| `Atmos refraction: NO (AIRLESS)`, `Time format     : BOTH`, `Calendar mode   : Mixed Julian/Gregorian`, `EOP file        : eop.261125.p270221` | other header lines, between asterisk rules |
| the table header, then a rule of asterisks, then `$$SOE`, the rows, `$$EOE` | |

Table header with quantity 31 in TT, and with quantities 30 and 31 in UT:

```
 Date__(TT)__HR:MN:SC.fff, Date_________JDTT, , ,    ObsEcLon,   ObsEcLat,
 Date__(UT)__HR:MN:SC.fff, Date_________JDUT, , ,       TDB-UT,     ObsEcLon,   ObsEcLat,
```

A row of each (leading space, trailing comma):

```
 1899-Dec-31 12:00:00.000, 2415020.000000000, , , 265.2972999,  0.4615158,
 1899-Dec-31 12:00:00.000, 2415020.000000000, , ,    -1.946024,  265.2969812,  0.4614866,
```

The text after `$$EOE` explains the columns ("Terrestrial Time ("TT") output was requested"; for UT, "Times PRIOR to 1962 are UT1 … Times AFTER 1962 are in UTC", and the last known leap second is held for future instants). No answer carried a warning.

### 8.2 Parsing requirements

* **Columns are located by name** in the header line (the last line before `$$SOE` that contains `Date__(`), split at commas and trimmed: `Date__(TT)__HR:MN:SC.fff` or `Date__(UT)__HR:MN:SC.fff`, `Date_________JDTT` or `Date_________JDUT`, `ObsEcLon`, `TDB-UT`. **Never by position:** longitude is field 5 in a quantity-31 answer and field 6 with quantity 30. Two columns after the Julian day have empty names. Every row has as many fields as the header.
* The time scale is taken from the `Start time` and `Stop  time` lines and from the two date column names; all must name the requested scale.
* The target is `(<COMMAND>)` on the target line; the centre is `Earth (399)` and `GEOCENTRIC`.
* Both echoed times, the Julian day and the calendar time, must match the requested Julian day within 1 ms, row by row in request order.
* Fewer printed decimals than the pilot gates (longitude 7, quantity 30 three) is refused for every later answer.

### 8.3 Precision

| Value | Printed | Resolution |
|---|---|---|
| Julian day | 9 decimals | 86.4 µs |
| Calendar time | 3 decimals of a second | 1 ms |
| `ObsEcLon` | 7 decimals of a degree | 0.00036″, below the 0.001″ row protection |
| `TDB-UT` | 6 decimals of a second | 1 µs |

Every pilot time lies within 0.03 ms of a whole millisecond, so the answers do not show whether the calendar time is rounded or truncated. A calendar-time refusal in a later request is a stop and report; the 1 ms tolerance is not widened.

**The retrograde confirmation requests, predicted before sending** (offline, 2026-11-26, on `4b1acc6`; a prediction, not an observation):

* 51 times (33 distinct strings). Largest predicted difference between the printed calendar time and the requested time: **0.968 ms** if Horizons truncates (2003-08-28, 2004-06-14), **0.216 ms** if it rounds (1956-09-10). None exceeds 1 ms, also when each string is read as its nearest double (at most 14.2 µs from the string).
* **What would still refuse:** truncation, with Horizons' internal time below the requested one by more than the requested time's distance above its millisecond boundary. The smallest distance is 22.4 µs (2023-08-01, 2023-10-15, 2024-08-01, 2024-10-20, 2049-05-11); 2016-05-13 has 28.8 µs. Horizons' internal arithmetic is not documented.
* The pilot echoed two TT times with those same distances on the expected millisecond (`2441317.500488241`, 22.4 µs; `2488434.500789167`, 28.8 µs). That is evidence, not proof.

**The dataset requests, predicted before sending** (offline, 2026-11-27, same method; the worst predicted difference between the printed calendar time and the request):

| Set (design 8.6) | Times | Worst if truncated | Worst if rounded |
|---|---|---|---|
| TT entries | 64 | **1.013 ms**, `2447892.500661852` (1990-01-01), nearest double | 0.493 ms |
| UT cross-check | 42 | 0.971 ms | 0.029 ms |
| Control, UT | 22 | **1.010 ms**, `2440423.345138889` (1969-07-20T20:17), nearest double | 0.010 ms |
| Retrograde evidence | 12 distinct (18 sent) | 0.955 ms | 0.216 ms |
| Control, TT (estimate: UT + library ΔT; the real times come from Horizons) | 22 | 0.994 ms | 0.493 ms |

The two values over 1 ms occur only if Horizons truncates **and** reads the string as its nearest double (read exactly, those two times differ by 0.013 ms and 0.010 ms; the worst TT entry is then 0.997 ms). The Task 4B answers show whether it truncates or rounds: at 2003-08-28, 2004-06-14 and 2012-06-12 a truncating printer shows `.183` and a rounding one `.184` (plan Task 4 Step 4B-echo). The pilot could not tell.

**Observed on the Task 4B answers (2026-11-26): Horizons rounds.** All nine deciding rows print the upper millisecond (`00:01:04.184` for 2003-08-28 and 2004-06-14, `00:01:06.184` for 2012-06-12, each at t and t ± 3). Over all 51 rows the printed time minus the requested one lies between −0.216 and +0.045 ms, the values predicted for rounding. Under rounding every dataset time is predicted within 0.493 ms, so the dataset download proceeds with the tolerance unchanged.

**The canonical TT string** (2026-11-26). For every instant it is `ttJulianDay`: from 1972, `julianDayUt(utc.add(ttMinusUtc)).toStringAsFixed(9)`, the double the adapter passes to the library, printed to nine decimals; before 1972, `julianDayUt(utc) + ΔT/86400` printed the same way. It is **not** an exact-decimal rounding.

* 2012-06-12 is **`2456090.500766018`**. The exact value is …`.500766018519`; the app's double (spacing 40.2 µs) is …`.500766018406`, below the half-way point, so it prints as `…018`, while rounding the exact value gives `…019`.
* The same happens at 2010-01-01 and 2015-01-01. The rule reproduces all 530 `jdTt` strings of the ZOD-EPH-002 TT reference (340 from 1972, 190 before). Exact rounding would change 20 of them (those two instants), so it is not used.
* The fetch tool, the dataset, the device copy, the node reference and the reference checks use this string (the plan's Task 5). The adapter itself passes its unrounded double. No nine-decimal string parses back to that double: the canonical one lands at most 40.2 µs from it, about 0.00002″ of Moon motion, inside the 0.0005″ device pin.

### 8.4 Pilot results

* All ten bodies have a row at TT 2101-01-01T00:01:08.184. Sources: Sun, Moon, Mercury and Venus DE441; Mars `mar099`; Jupiter `jup365_merged`; Saturn `sat441l`; Uranus `ura184_merged`; Neptune `nep098_merged`; Pluto `plu060_merged`.
* All 17 rows echo the requested times, in order.
* 1972 boundary: the Moon is 101.6302965° in both the TT and the UT answer; `TDB-UT` there is 42.183919 s, so Horizons applies the offset at that exact instant.
* `TDB-UT` at the other three pilot times: −1.946024 s (1899-12-31T12), 64.183903 s (2000-01-01T12), 69.183904 s (2101).
* Observation, not a gate: where the same Julian day was asked as TT and as UT, UT minus TT is −1.147″, +32.149″ and +41.564″, that is 0.50 to 0.60″ per second of `TDB-UT`, consistent with the Moon's motion. **It does not replace link 4 of section 6: the 22-instant time-scale control is still run with the dataset.**
* No accuracy statement follows from the pilot: its values were not compared with the app's.

### 8.5 Pilot answers

The two Moon answers are committed unchanged as parser samples, `packages/ephemeris_swiss/test/fixtures/horizons_sample_tt.txt` (request 1) and `horizons_sample_ut.txt` (request 2). All 11 raw answers and the request log are kept in a durable directory outside the repository (location in `docs/PROGRESS.md`). SHA-256:

```
789e1d04b1d22563d7a8dafe8a706921e214f8f5c54efec802bbb59b2147fc24  01_301_TT
4e77b549aa88286be8ee469f5adbdd9a9e35fa67804a1ff237672db8869f24fa  02_301_UT
4ce393a3b4d9ec31ed26bf1f8c903233ca56b5fc75084177fc555b2e10e9509f  03_10_TT
5a15a8b99756f629733ff9e2e6644f9a3123da42fb7cf602a3da9f3050b1daa6  04_199_TT
6074c503690a41ca860b103e049917e6d63094a884ae96a48d726ed6c89c09f6  05_299_TT
33102b8130a4e314faff96fa918917ef5e8712715b31113f14e859dcb869b809  06_499_TT
752c3d6f274f2a4d5ef94bf6e77f1092df3e36f96e9a90a085d9b94f46d51436  07_599_TT
8b55f55fce038032a3f3d2c2de901024c2b61f236c3367c8952bc374aa4eca03  08_699_TT
37513e3ff3737b016103fbe1c307ec8af8008c814b6d337f338f0f089f031bae  09_799_TT
5d3a7326d8d94b826f1f88c705900eeb9e41f9d5197075197175df83407720c6  10_899_TT
1d8205e37bbf028e7fcac1a2d8b4e2645514ca57e07b5a9fca1e9faa69f4d4ac  11_999_TT
```

The two requests behind the samples, as sent (the repository's query function must reproduce them):

```
https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND=%27301%27&OBJ_DATA=%27NO%27&MAKE_EPHEM=%27YES%27&EPHEM_TYPE=%27OBSERVER%27&CENTER=%27500%40399%27&TLIST_TYPE=%27JD%27&TLIST=%272415020.000000000+2441317.500488241+2451545.000000000+2488434.500789167%27&TIME_TYPE=%27TT%27&TIME_DIGITS=%27FRACSEC%27&CAL_FORMAT=%27BOTH%27&QUANTITIES=%2731%27&ANG_FORMAT=%27DEG%27&EXTRA_PREC=%27YES%27&CSV_FORMAT=%27YES%27&APPARENT=%27AIRLESS%27
https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND=%27301%27&OBJ_DATA=%27NO%27&MAKE_EPHEM=%27YES%27&EPHEM_TYPE=%27OBSERVER%27&CENTER=%27500%40399%27&TLIST_TYPE=%27JD%27&TLIST=%272415020.000000000+2441317.500000000+2451545.000000000+2488434.500789167%27&TIME_TYPE=%27UT%27&TIME_DIGITS=%27FRACSEC%27&CAL_FORMAT=%27BOTH%27&QUANTITIES=%2730%2C31%27&ANG_FORMAT=%27DEG%27&EXTRA_PREC=%27YES%27&CSV_FORMAT=%27YES%27&APPARENT=%27AIRLESS%27
```

### 8.6 Requests

| Phase | Requests | Times per request |
|---|---|---|
| Pilot (format, 1972 boundary, last-instant coverage): **done 2026-11-26** | 11 | 1 to 4 |
| Retrograde confirmation, primaries and backups (TT) | 8 (Mercury to Pluto) | 6 to 9 |
| Dataset: TT entries | 10 | 64 |
| Dataset: UT cross-check from 1972 | 10 | 42 |
| Dataset: time-scale control (Moon) | 2 | 22 |
| Dataset: retrograde evidence (t ± 3 days) | 8 | 2 to 4 |
| Backup fixtures (only under option A, section 10) | 20 | 61 |
| **Total** | **49, or 69 with option A** | |

**Remaining after the pilot: 38 requests, or 58 with option A (chosen).**

Sequential, 1 second apart, each limited to 60 s in all, never retried, redirected or sent again without the owner's approval. The documentation states no API rate limit. A request holds only dates and body numbers, with Dart's default client identification. About 1.2 kB of times at most, well under usual URL limits. A failed or refused request is not run again without the owner's approval; a new date or parameter needs it too.

### 8.7 Download results

All answers are kept unchanged outside the repository, in `C:/Users/user/zodiann-horizons-answers/ZOD-TST-001`, one directory per phase, with a request log (`*.requests.tsv`: file, time saved, status, bytes, SHA-256, URI) and the tool's output (`*.run.log`). Every request was sent once.

| Phase | Requests | Saved (UTC) | Result |
|---|---|---|---|
| Pilot | 11 | 2026-11-26 18:41 | 11 HTTP 200 (section 8.4) |
| Retrograde confirmation | 8 | 2026-11-26 22:10 | 8 HTTP 200 (section 5.2) |
| Dataset | 30 | 2026-11-26T22:31:06Z to 22:31:55Z | 30 HTTP 200; written |
| Backup, UTC | 10 | 2026-11-26T22:37:47Z to 22:38:02Z | 10 HTTP 200; 610 rows |
| Backup, TT | 10 | 2026-11-26T22:49:21Z to 22:49:36Z | 10 HTTP 200; 610 rows |

**Dataset** (tool at commit `65e2b33`; `API VERSION: 1.2`; `horizons_reference.json` version 1, 188763 bytes, SHA-256 `b1ddcacebd42e12310379e2dc70795e44a4145a8c4a2f7f19297a78c79ec8752`):

* 640 entries (64 instants, ten bodies), 420 UT cross-check rows, 22 time-scale control rows, 9 retrograde evidence rows; every parser check passed and `datasetProblems` was empty.
* All 530 rows of the previous Swiss TT reference are unchanged (largest difference 0″).
* UT cross-check against TT entries: largest disagreement 0.00036″ (Moon, 2090-01-01), limit 0.002″. Time-scale control: largest 0.00072″ (1956-09-10), limit 0.002″; TDB − UT from −1.946024 to 42.076161 s.
* Offline comparison with the retrograde answers: 27 times asked twice, largest difference 0″.
* Echoed times: printed minus requested between −0.492 and +0.493 ms over 1,122 rows (rounding, as predicted).

**Backup** (old-row rule of section 10; for each fixture 530 old rows present, 350 identical, 180 changed, all from 2030-01-01 on, largest 0.00072″; no violation; 80 new rows for the 8 new instants). The UTC requests ran before the rule was decided; their answers were kept and used, not sent again.

SHA-256, dataset:

```
4a74de068fa3fa892613f3e889a70ce413e283195c273627cd06b501d21eb6a7  01_10_TT
70a42730efcf208d9a4ce0bbb42b35ae3bb2c5269a57f52cfbb6844e9c55269f  02_301_TT
eb2a1f450ea6138dfcb912a5a271761446e24e1cdd6df9e59d0c67385dc05ab8  03_199_TT
5178d4568afbe2354de04e04e398b6bcaa85b4dbc150880e24f211ecd13e1611  04_299_TT
15c9bc32bc592a8b9bbdc7fbf9a4e413e66efcef15818501c184f50fb97a0e1a  05_499_TT
3ddcb4c2f948e5165c8a335a3062276372fa81599c8abcc147cf8ddac3b4bd4f  06_599_TT
98c6d0c674093123b09eb516cc84e14c454fb24640570fa8dfac41fffa6e447c  07_699_TT
bdacee3c6d96352657f5d70adbc407225f55fee44e869e3c9eea6fec26122e0b  08_799_TT
cde0ef45841ba7c87d61da68edba1beba785af496b2f204d26259cc9d992eea0  09_899_TT
bc5c997f136810fad932bf219e959f3ea4f0fbf2664e85b0341657fd2b0b5bf7  10_999_TT
f8c6b84db98c1b843a58c784a01fb9bcfa9596e5896e7087c4c1a99a1de2441e  11_10_UT
6bad41f294b54a325eea597cb515310abf81edbcf59bfc80276b1462790c77e8  12_301_UT
306e797a6af3e653b0ac51b2e2147740eedf366c003a8371218cad63b1d2e37a  13_199_UT
8e80cc871220ce8344b6ba02f3205fbce2d0edd32ce2e45844754270b6c4aea7  14_299_UT
6ed262b227bf216725b8d4be20444346bbce47b077d28182fc172a5880dd802f  15_499_UT
b5d7d2a6a5f6d9bf1969555e63a6235d8c61bfb727ff47810b3b595732339f3c  16_599_UT
4478f94f4b73e26287a2b68f1247eb30af52fa172ebf88ef253d23f54b0a4799  17_699_UT
262f24877839ea6224216531115ee54c329a43a0852c4a443e1e66db1a4b915d  18_799_UT
c2c4a2990ac98bf77382ab89056392f81468d8a02471d45289ee62b3692a76cd  19_899_UT
487c0b637a44b3c22082b723bde8c15746ef158855b883ff29420feecf917e80  20_999_UT
ed66ddae3a9de630a1ebfda3ad5743709b3f660a8ef0fd62b083da68bbd3da2a  21_301_UT
8739c519db0da747c2cb352298c8f536cddf5376af3902925bac9640c230d918  22_301_TT
28a4a87b8e86dd8ba51a70ee7aa9853e671d243aaba2aa123659a97828b803a4  23_199_TT
8fd476b3a0baddf367732004613108d608b6ec44be998d55231f15dfcd10fe2c  24_299_TT
58f998bff2e8fe9559bb4e8bc2176d3628d9e99b9dd4d24b64eee58bc7be8bfb  25_499_TT
716a3715ba27f746d45947ed41477f63091d96dd0197a7ebc584fc70be96ae73  26_599_TT
e019c8f6a8b26d20a5067b3ad84dafadd48434c015a2de115579b310c35d16e8  27_699_TT
fafe152102334b8ed32cd14188847e1df6b7d89eef6e8a289b5252b6529d8434  28_799_TT
4345c6a9ec8d38265c6135b503d937e3056b3cc9fea32939cb9341d9b24d46fa  29_899_TT
27a7478e64c693ab4069e3970dc638b43b955af22624847821c4f1e42f0bf0c2  30_999_TT
```

SHA-256, Backup UTC:

```
8a801aa82df326208a6075b5f593efdceb6af8566f93c66c3bf20bafed66241c  01_10_UT
68e5018b087401039120e086869226671ba4c4d36ee4347f0e6d7a630f258951  02_301_UT
04e3a168ef8cfd3393b6cca5a500f446619e2c34722ae487195e0f3cdba2201e  03_199_UT
a7db581c22e38dabd8e51a89873abdea0f5b9573d8c3ab545007f8c1b5626c35  04_299_UT
4c2ca47ffbbfe242e382db40d1f12f9cc9c491a513a5f3061b8c51f87a382154  05_499_UT
8b033dbc853bd3aa4589d1f97cd1cbbfe73de49d4cfd9167edc42be087d71319  06_599_UT
4a054aa7503a6932df857f156290873f5dc1a1834675dbcb8ec2b074ffc0cb5a  07_699_UT
36e87d8b3a9d2fdc51d87d07be00f45d858a8e2d6d2081a80c13d68ac119db69  08_799_UT
a28db277500612305967175cfee7815ef3e483edda51c877f9ee713ee229be71  09_899_UT
ea3a1aa0672169443a6e259bb50074a76009f951f0ba15343e20851ed02885ad  10_999_UT
```

SHA-256, Backup TT:

```
63f18d171e91f6ed883d6c23e0b9e62db4a12b2f890f48d86887630b2c3f823d  01_10_TT
df4b28130f0a5cedee774ba45db835161fa48831607e8170cdacae1d9ca10f0b  02_301_TT
85d6a8ab8607be8e11606fd19932fe03e8d4441e7a86b7a5686f28bbe7581c19  03_199_TT
616a42ffcf9033e1b113e07fb49ec9eff3bb7c0d761ad955b9983be597914834  04_299_TT
726aeffaf2db77dc535106281026bc99973f217312ac65906afe87d448e64c5b  05_499_TT
56dbabc26441a0e683bb7932c4f52bf0923d608ae02fa9f9abcdcdbc33e09a10  06_599_TT
52df1d5dce7ea93f5105870a9b5d86bdd1d35a49b737cd2196efde86cf17d5d4  07_699_TT
012b73f12a7d81e1398c51d802ffae34032df28182b50cf083bd522ef43348db  08_799_TT
d021fff2b38ba041abdb7c9bc214e00b4c7c5731b5c097e7d878952db94a68fb  09_899_TT
b2f03472be9a764a3693b8e3b78ebfbd5200c480b2c6794440c33ecf33778b96  10_999_TT
```

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

## 10. The backup (option A chosen)

Your range restriction covers the three instants after 2100-01-01T12:00Z. It does **not** cover the eight new instants **inside** the backup's range, because its tests require every shared instant to have backup reference rows.

| Option | What happens | Cost |
|---|---|---|
| **A (recommended)** | The restriction is by range only. The two backup fixtures are refetched for the 61 in-range instants (every existing row is kept under the old-row rule below, otherwise stop and ask), its two fetch tools filter to the range, the device counts go from 53 to 61 instants, and the existing 60″ gate also runs on the eight new instants. **This edits backup test data, tools and device tests, which is more than "update the tests": approving A approves that** | 20 more requests; one more device run; backup test data and ACC-2 evidence grow |
| B | The backup tests assert only the 53 version-1 instants; new instants are left to ZOD-TST-005 | none now, but this **goes further than your wording**: the "every shared instant in range" requirement is narrowed |

Neither changes the backup's implementation, range, tolerance or boundary tests.

**Old-row rule for the refetch (owner decision, 2026-11-27, replacing "identical").** For both backup fixtures: every old (body, instant) row is present; its other stored values (`utDays`, `ttDays`, `deltaTSeconds`, `jdTt`) are identical; its longitude may differ only for an instant after **2026-11-25** (the end of the Earth-orientation data in the Horizons answers) and by at most **0.001″**, and then the new value is taken. Anything else stops and goes to the owner.

What prompted it: the UTC refetch (EOP file `eop.261125.p270221`) differs from the fixture retrieved 2026-11-21 in 180 of 530 rows, all from 2030-01-01 on, by 0.00036″ to 0.00072″ (1 or 2 units of the seventh decimal), while all 350 earlier rows are identical and all 390 rows shared with the primary dataset's UT cross-check equal it. The shift does not grow with a body's speed, so it is not a time-basis change; an update of Horizons' Earth-orientation predictions is the likely cause, **inferred, not proven** (the 2026-11-21 answers were not saved).

**Speed test (only under A):** its frozen speed bounds were set on the 53 instants and a dense Moon set. Recommended: it keeps sampling exactly the 53 (the eight are excluded by name and the count is asserted). Alternative: let it sample 61 and stop if a frozen bound is exceeded.

**Still open for ZOD-TST-005:** the shared dataset's TT is the **primary's** TT. The backup takes UTC and applies its own ΔT, so calling it at a shared instant does not reproduce the shared TT (up to about 133 s apart by 2100, 78.6″ of Moon). Nothing here claims the backup meets the primary's accuracy or time basis.

## 11. Blocker closure

**Closed for the Swiss primary source, for this task:** all ten bodies were within 0.56″ at the 53 instants through 2100-01-01T12:00Z on the x86_64 emulator (ZOD-EPH-002). **The extension to 2100-12-31 is not yet verified**; this task's own gate verifies it. ARM devices and iOS remain unverified. **The backup discrepancy stays open.**

## 12. Limits

* Swiss data files and Horizons both descend from JPL ephemerides: the comparison checks time handling, the apparent-place chain and the packaged files, not orbit theory independently.
* Positions only. No speed reference.
* ACC-1's "same settings": geocentric, apparent, tropical of date; Horizons uses the IAU76/80 model for quantity 31, a difference included in the measured error.
* A future change of the civil time standard would change the post-2027 rows' meaning (decision record section 1).
* **Future rows do not reproduce exactly.** For instants after the end of Horizons' measured Earth-orientation data, answers changed by up to 0.00072″ between 2026-11-21 and 2026-11-26 (section 10). The primary dataset has the same exposure, and its 0.001″ row protection leaves only about 1.4 times that. Its comparison with the previous TT reference found 0 differences, but both were retrieved on 2026-11-26. A later refetch that exceeds 0.001″ stops the tool and needs an owner decision.

## 13. Owner decisions on the open questions

**Answered 2026-11-26.** D1: option A. D2: keep the 53. D3: leave. D4: accept. D5: the download is in scope. D6: confirmed.

| ID | Question | Recommendation (approved) |
|---|---|---|
| D1 | Backup coverage of the new in-range instants: A (including edits to the backup's test data, fetch tools and device tests) or B (section 10) | **A** |
| D2 | Under A, the speed test's sample | keep the 53 |
| D3 | The ZOD-FND-003 spike test keeps its own six Horizons rows. Two of them (Sun and Moon, 1900-06-15) are pre-1972 UT comparisons. Leave them, or repoint or drop them? The test does not consume this dataset, and Swiss and Horizons ΔT differ by about 0.01 s near 1900 | leave, as a FND-003 binding smoke test; say so if rule 3 should reach it |
| D4 | Accept non-authoritative sources for the outer-planet **candidates**, given that Horizons confirms them | accept |
| D5 | Approve the download of section 8 (49 requests, 69 with A) | with the plan |
| D6 | Confirm the node comparison setting: `SEFLG_NONUT`, mean equinox of date, tolerance 0.01° (section 7) | confirm |

## 14. Left to the builder

Function and test names beyond those in the plan; the layout of the fetch tool's internals; message wording of its failures.
