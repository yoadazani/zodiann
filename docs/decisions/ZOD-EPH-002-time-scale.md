# ZOD-EPH-002: time conversion for planet positions (approved specification deviation)

> **Status: approved by the owner, 2026-11-25; implemented by ZOD-EPH-002 and verified on an x86_64 Android emulator, 2026-11-26 (section 9).** ARM devices and iOS are unverified. The measurements of section 3 are from a host build. The specification text is unchanged: only the owner edits it. Background: [`docs/spikes/ZOD-EPH-002-time-scale.md`](../spikes/ZOD-EPH-002-time-scale.md).

## 1. Decision

| Requested UTC instant | Conversion | Library call | Basis label |
|---|---|---|---|
| before 1972-01-01T00:00:00Z | the input is treated as Universal Time; the library's historical ΔT (unchanged) | `swe_calc_ut` | historical ΔT |
| from 1972-01-01T00:00:00Z, before the leap-second table's validity end | `TT = UTC + (TAI − UTC) + 32.184 s` from the published table | `swe_calc` | published leap seconds |
| at or after the validity end (bundled table: 2027-06-28T00:00:00Z) | the last offset (37 s) is held | `swe_calc` | assumes continuous UTC |

* `JD_TT = JD_UTC + (TAI − UTC + 32.184) / 86400`. `TAI − UTC` is 10 s from 1972-01-01 and 37 s since 2017-01-01 (27 steps), each from 00:00:00 UTC of its date. TDB − TT (at most about 2 ms) is neglected.
* The table is **data with provenance** (source, bulletin, validity end) and is replaceable. The bundled one is IERS `Leap_Second.dat`, updated through Bulletin C 72, expiring 28 June 2027.
* **The label is never silent.** A caller can ask which basis applies to any instant; results that rest on the continuous-UTC assumption can be identified.

### Why the offset is held after the table

CGPM 2026 Resolution 5 makes UTC continuous from 20 May 2027, with a maximum |UT1 − UTC| of 3,600 s (the French text is official). Bulletin C 72 itself only rules out a step at the end of December 2026; the table's stated validity (to 28 June 2027) reaches past 20 May 2027. This is the current international decision, **not a guarantee**: a later conference could change it. A change of δ seconds would move the Moon by about 0.55 δ arcseconds at the affected instants (about 1.8 s would exceed 1″). Forecasts of the Earth-rotation lag by 2100 (24 s from Swiss Ephemeris, 133 s from Astronomy Engine) are far below the 3,600 s limit.

## 2. Three separate concepts

| Concept | Answers | Used by position computation |
|---|---|---|
| Time-conversion basis (section 1) | how TT was obtained | yes |
| ΔT data status: observed through 2023, estimated 2024 to 2028, forecast from 2029 for the bundled library data; data-driven, no year literal in code | how well ΔT is known | no (from 1972) |
| Moon accuracy warning threshold | when to warn a user | **not set** |

These are never conflated. The ΔT classification does not replace any warning.

## 3. Evidence (2026-11-25, host build of the vendored library with the packaged files)

* **Same physical instant.** For ten bodies at 61 instants (the 53 reference instants and 8 boundary instants), Horizons asked with `TIME_TYPE=UT` at the UTC instant and with `TIME_TYPE=TT` at UTC + offset agreed, from 1972, to 0.0004″ (Moon; 0.0000″ for the others). Horizons' own TDB − UT differed from the offset by at most 1.3 ms, consistent with TDB − TT. The Horizons manual states that after 1962 "UT" means UTC and that TDB − UTC = (TDB − TAI) + (TAI − UTC), so this agreement is by construction.
* **Ephemeris accuracy, separate from the convention.** Swiss Ephemeris and Horizons at the **same** TT: at most 0.56″ (Uranus, before 1972); Moon at most 0.24″. This holds for either method's TT.
* **UT-input comparison** (53 instants): all ten bodies within 0.56″.
* **The convention gap** (Swiss ΔT − offset, and the Moon's longitude difference): −0.38 s / 0.24″ in late 2026, 1.32 s / 0.69″ in 2035, 5.40 s / 3.03″ in 2050, 24.0 s / 14.0″ in 2100. Other bodies after 2026: at most 1.6″ (Mercury). The gap is Swiss Ephemeris's forecast of UTC − UT1; it is **not** an ephemeris error.
* **Limit.** Swiss Ephemeris data files (header: based on JPL DE441) and Horizons share JPL lineage: this checks time handling, the apparent-place chain and the packaged files, not orbit theory independently. Android and iOS are not yet verified.
* **Method.** Horizons API, `CENTER=500@399`, `EPHEM_TYPE=OBSERVER`, `QUANTITIES=30,31`, `TLIST_TYPE=JD`; Swiss through a scratch C program calling `swe_calc` / `swe_deltat_ex` with `SEFLG_SWIEPH | SEFLG_SPEED`. The scratch tools are not in the repository; ZOD-EPH-002's tests replace them.

## 4. Known steps in TT as a function of UTC

* At 1972-01-01 the method changes: TT − UTC goes from 42.230 s to 42.184 s, a step of 46 ms (Moon about 0.027″).
* At each of the 27 leap seconds TT advances 2 s between 23:59:59 and 00:00:00 UTC (physically right; `DateTime` cannot represent 23:59:60). The Moon moves about 0.55″ in the extra second.
* A crossing solver cannot reach CRS-A3's 0.01″ across a step: it must split segments at these instants or stop on time resolution.

## 5. Tests required

1. **Ephemeris accuracy:** against Horizons at matched TT.
2. **Conversion:** UTC input against Horizons UT queries from 1972; unit tests of the offset at every table step, one microsecond either side, at 1972 and at the validity end.
3. A guard that the bundled table equals the published list recorded with it.
4. Before 1972: the `swe_calc_ut` path is unchanged.

## 6. Specification deviation

Specification, "Computation settings", row **Time**, currently: "Input in local time is converted to UTC, and from there to terrestrial time using the difference called delta T | Delta T for the future is a forecast, so Moon accuracy drops for dates far in the future. The interface warns about this".

Proposed text (for the owner to apply):

* Value: "Input in local time is converted to UTC. From 1972, terrestrial time is UTC + (TAI − UTC) + 32.184 s from the published leap-second table; before 1972, the ephemeris library's historical delta T."
* Note: "Beyond the table's validity, UTC is assumed continuous (CGPM 2026) and results say so. Forecast delta T affects only quantities that depend on the Earth's rotation."

Scientific implications: geocentric positions for a given UTC instant no longer depend on a ΔT forecast. What remains uncertain about the future is the civil time standard itself. Topocentric positions, sidereal time and houses still depend on UT1, and so on forecast data. Programs that treat civil time as UT1 will show positions and crossing times that differ by the convention gap of section 3.

## 7. Hand-offs (become Notes lines when each task is planned)

| Task | Hand-off |
|---|---|
| ZOD-EPH-002 | implements sections 1, 2 and 5; exposes the basis and the ΔT data status |
| ZOD-EPH-006 | the backup adopts the same conversion (until then it keeps its own ΔT) |
| ZOD-EPH-007 | updatable Earth-rotation and leap-second data |
| ZOD-CRS-001, ZOD-CRS-002 | the steps of section 4 |
| ZOD-TST-001, ZOD-TST-005 | the far-future ΔT conflict does not arise for Swiss Ephemeris under this conversion (confirmed on the x86_64 emulator, section 9); the backup still shows it until ZOD-EPH-006 |
| ZOD-TST-006 | the convention gap must be explained if the comparison program treats civil time as UT1 (not checked for Astrolog) |
| ZOD-NFR-017 | the criterion "a far-future date shows the ΔT-forecast banner" needs an owner decision |
| ZOD-ABT-003 | the method screen states the time conversion |

## 8. Related owner decisions for ZOD-EPH-002 (2026-11-25)

* Native calls use one shared library state with a lock, in a project-authored C file; vendored sources unchanged.
* The astronomy-engine backup is selected automatically **only if the Swiss library does not load**; missing files or unsupported dates never switch sources. This refines "only ever an explicit user choice" in the [ZOD-FND-011 record](ZOD-FND-011-ephemeris-data-file-coverage-range.md) section 4 for that one case.

## 9. Device results (2026-11-26)

`Pixel_9_Pro_API_36` emulator (API 36, x86_64, 16 KB pages), through the production adapter and the locked library, `apps/astro_mobile/integration_test/swiss_ephemeris_accuracy_test.dart`. Maximum difference from JPL Horizons in arcseconds, 53 instants from 1899-12-31 to 2100-01-01 per body:

| Body | UTC input | Matched TT |
|---|---|---|
| Sun | 0.242 | 0.243 |
| Moon | 0.455 | 0.243 |
| Mercury | 0.243 | 0.243 |
| Venus | 0.242 | 0.242 |
| Mars | 0.242 | 0.243 |
| Jupiter | 0.228 | 0.228 |
| Saturn | 0.252 | 0.252 |
| Uranus | 0.560 | 0.560 |
| Neptune | 0.198 | 0.198 |
| Pluto | 0.246 | 0.246 |

The adapter's own TT equals the fixture's within 0.000025″ of Moon longitude.

**What checks the conversion itself (branch review, 2026-11-26).** From 1972 the fixture's TT comes from the app's own conversion, so the matched-TT gate and the TT pin cannot detect an error in it, and the 1″ UTC-input gate resolves only about a second. The host test `packages/ephemeris_swiss/test/reference_tt_fixture_test.dart` therefore requires, for all ten bodies at every reference instant from 1972, that Horizons asked at the app's TT agrees within 0.002″ (a few milliseconds of Moon motion) with the ZOD-EPH-004 reference asked at UTC, where Horizons applies its own leap seconds.

**Update 2026-11-27 (ZOD-TST-001):** that test is replaced by `packages/ephemeris_swiss/test/horizons_reference_time_test.dart`, which reads the shared Horizons dataset (its TT entries against its own UTC cross-check). The device results above are followed by that task's gate over 64 instants.

 The far-future ΔT conflict does not arise for this source; the backup keeps it until ZOD-EPH-006.
