# ZOD-EPH-004: ΔT, and what the TT-consistent ACC-2 test does and does not show

Written 2026-11-22 for the owner decision D12 (Option 2) of
[`docs/plans/ZOD-EPH-004-astronomy-engine-adapter.md`](../plans/ZOD-EPH-004-astronomy-engine-adapter.md).
Nothing here changes the ΔT model of any engine, the covered range (D4), a
threshold, a formula, `EphemerisPort`, `astro_core`, the specification's
literal ACC-1 and ACC-2 text, or ZOD-TST-001.

## 1. Why this document exists

The adapter is given a UTC instant and the library converts it to TT (the time
scale of the planetary theories) with its own ΔT = TT − UT model. Horizons and
Swiss Ephemeris use theirs. The three agree to a few tenths of a second in the
historical record and diverge in the future, where ΔT is a prediction. The
first Task 5 device run compared the adapter at UTC instants with Horizons at
the same UTC instants, and the Moon was 78.599 arcseconds away at
2099-12-31T23:59:59Z against the 60-arcsecond bound. The Moon moves about 0.55
arcsecond per second of time, so a ΔT gap of about 133 seconds is about 79
arcseconds. The theory was not at fault: asked at the same TT, the library's
Moon is within 3.4 arcseconds of Horizons at all 53 instants.

## 2. How each source gets its ΔT

| Source | UT-to-TT model for the future | Where it is stated |
|---|---|---|
| Astronomy Engine v2.1.19 | The Espenak and Meeus polynomial model, extrapolated; 202.65 s at 2100. | `Astronomy_TimeFromDays` in the vendored `astronomy.c`; measured here through the device hook. |
| Swiss Ephemeris | Its own model, `swe_deltat_ex(jd_ut, SEFLG_SWIEPH, serr)` with the data files (the tidal acceleration, and so ΔT, depends on the ephemeris in use). | Measured here with the vendored sources. |
| JPL Horizons | Historical reconstruction before 1962 (UT1); the long JPL EOP file from 1962 (UTC); EOP predictions for about the next 73 days; "beyond that prediction interval the last prediction is taken as a constant for all future dates" (about 69.18 s). | Horizons manual, quantity 30 (TDB-UT) and its time-scale section. |

None of the three is "true" for the future: ΔT depends on the Earth's rotation,
which is not predictable to the second decades ahead. A comparison of two
sources in the future measures the difference between two assumptions.

## 3. Measured ΔT at the 53 reference instants

Produced by `docs/spikes/ZOD-EPH-004-delta-t/measure_delta_t.dart` on
2026-11-22. Astronomy Engine: the TT fixture's `deltaTSeconds`, which the
device test pins against the device's own hook within 1 millisecond. Swiss:
`swiss_delta_t.c` built from the vendored sources. Horizons: the printed
quantity 30 at UT input, so the "implied ΔT" fallback of the plan was not
needed. The Horizons figure is TDB − UT; it differs from TT − UT by the
TDB − TT periodic term (at most about 1.7 milliseconds), which is ignored. The
last column uses 0.55 arcsecond per second for the Moon; at the worst instant
the exact figure is 78.599 / 133.47 = 0.589 arcsecond per second, and the
Moon's speed ranges over 0.49 to 0.64 arcsecond per second.

| UTC instant | Astronomy Engine ΔT (s) | Swiss ΔT (s) | Horizons TDB-UT (s) | Library − Horizons (s) | Swiss − Horizons (s) | Moon effect of library − Horizons (arcsec) |
|---|---|---|---|---|---|---|
| 1899-12-31T12:00:00Z | -2.76 | -1.95 | -1.95 | -0.81 | -0.01 | -0.4 |
| 1900-01-01T00:00:00Z | -2.76 | -1.95 | -1.94 | -0.81 | -0.01 | -0.4 |
| 1905-01-01T00:00:00Z | 3.78 | 4.94 | 4.95 | -1.17 | -0.01 | -0.6 |
| 1910-01-01T00:00:00Z | 10.33 | 11.16 | 11.16 | -0.83 | -0.01 | -0.5 |
| 1912-06-30T06:00:00Z | 13.76 | 14.42 | 14.42 | -0.67 | -0.01 | -0.4 |
| 1915-01-01T00:00:00Z | 17.04 | 17.49 | 17.50 | -0.46 | -0.00 | -0.3 |
| 1920-01-01T00:00:00Z | 21.18 | 21.63 | 21.63 | -0.45 | -0.00 | -0.2 |
| 1925-01-01T00:00:00Z | 23.77 | 23.80 | 23.80 | -0.02 | -0.00 | -0.0 |
| 1930-01-01T00:00:00Z | 24.13 | 24.42 | 24.42 | -0.29 | -0.00 | -0.2 |
| 1935-01-01T00:00:00Z | 23.82 | 24.17 | 24.17 | -0.35 | -0.00 | -0.2 |
| 1940-01-01T00:00:00Z | 24.39 | 24.43 | 24.43 | -0.03 | -0.00 | -0.0 |
| 1945-01-01T00:00:00Z | 26.86 | 27.05 | 27.05 | -0.19 | -0.00 | -0.1 |
| 1950-01-01T00:00:00Z | 29.05 | 28.93 | 28.93 | 0.12 | -0.00 | 0.1 |
| 1950-12-31T23:59:59Z | 29.46 | 29.32 | 29.32 | 0.14 | -0.00 | 0.1 |
| 1955-01-01T00:00:00Z | 31.03 | 31.07 | 30.41 | 0.62 | 0.66 | 0.3 |
| 1960-01-01T00:00:00Z | 33.09 | 33.15 | 33.07 | 0.01 | 0.08 | 0.0 |
| 1965-01-01T00:00:00Z | 35.76 | 35.73 | 35.72 | 0.04 | 0.01 | 0.0 |
| 1969-07-20T20:17:00Z | 39.71 | 39.74 | 39.76 | -0.05 | -0.02 | -0.0 |
| 1970-01-01T00:00:00Z | 40.15 | 40.18 | 40.18 | -0.03 | -0.00 | -0.0 |
| 1975-01-01T00:00:00Z | 45.41 | 45.48 | 46.18 | -0.78 | -0.71 | -0.4 |
| 1980-01-01T00:00:00Z | 50.48 | 50.54 | 51.18 | -0.71 | -0.65 | -0.4 |
| 1985-01-01T00:00:00Z | 54.32 | 54.34 | 54.18 | 0.14 | 0.16 | 0.1 |
| 1990-01-01T00:00:00Z | 56.87 | 56.86 | 57.18 | -0.31 | -0.33 | -0.2 |
| 1995-01-01T00:00:00Z | 60.76 | 60.79 | 61.18 | -0.42 | -0.40 | -0.2 |
| 1999-12-31T23:59:59Z | 63.85 | 63.83 | 64.18 | -0.34 | -0.36 | -0.2 |
| 2000-01-01T00:00:00Z | 63.85 | 63.83 | 64.18 | -0.34 | -0.36 | -0.2 |
| 2000-01-01T12:00:00Z | 63.85 | 63.83 | 64.18 | -0.34 | -0.35 | -0.2 |
| 2000-12-31T23:59:59Z | 64.13 | 64.09 | 64.18 | -0.06 | -0.09 | -0.0 |
| 2005-01-01T00:00:00Z | 64.71 | 64.69 | 64.18 | 0.53 | 0.50 | 0.3 |
| 2010-01-01T00:00:00Z | 66.68 | 66.07 | 66.18 | 0.50 | -0.11 | 0.3 |
| 2015-01-01T00:00:00Z | 68.99 | 67.64 | 67.18 | 1.81 | 0.46 | 1.0 |
| 2020-01-01T00:00:00Z | 71.58 | 69.36 | 69.18 | 2.39 | 0.18 | 1.3 |
| 2024-12-31T23:59:59Z | 74.45 | 69.00 | 69.18 | 5.26 | -0.18 | 2.9 |
| 2025-01-01T00:00:00Z | 74.45 | 69.00 | 69.18 | 5.26 | -0.18 | 2.9 |
| 2026-11-12T00:00:00Z | 75.58 | 68.81 | 69.18 | 6.40 | -0.37 | 3.5 |
| 2030-01-01T00:00:00Z | 77.59 | 69.28 | 69.18 | 8.41 | 0.09 | 4.6 |
| 2035-01-01T00:00:00Z | 81.02 | 70.51 | 69.18 | 11.83 | 1.32 | 6.5 |
| 2040-01-01T00:00:00Z | 84.72 | 71.80 | 69.18 | 15.54 | 2.62 | 8.5 |
| 2045-01-01T00:00:00Z | 88.71 | 73.16 | 69.18 | 19.52 | 3.97 | 10.7 |
| 2050-01-01T00:00:00Z | 92.97 | 74.58 | 69.18 | 23.78 | 5.40 | 13.1 |
| 2055-01-01T00:00:00Z | 103.18 | 76.07 | 69.18 | 33.99 | 6.89 | 18.7 |
| 2060-01-01T00:00:00Z | 113.59 | 77.64 | 69.18 | 44.40 | 8.46 | 24.4 |
| 2061-07-28T18:30:00Z | 116.90 | 78.15 | 69.18 | 47.71 | 8.97 | 26.2 |
| 2065-01-01T00:00:00Z | 124.16 | 79.29 | 69.18 | 54.98 | 10.10 | 30.2 |
| 2070-01-01T00:00:00Z | 134.90 | 81.01 | 69.18 | 65.71 | 11.83 | 36.1 |
| 2075-01-01T00:00:00Z | 145.79 | 82.81 | 69.18 | 76.60 | 13.63 | 42.1 |
| 2080-01-01T00:00:00Z | 156.84 | 84.70 | 69.18 | 87.66 | 15.52 | 48.2 |
| 2085-01-01T00:00:00Z | 168.06 | 86.68 | 69.18 | 98.87 | 17.50 | 54.4 |
| 2090-01-01T00:00:00Z | 179.43 | 88.76 | 69.18 | 110.24 | 19.57 | 60.6 |
| 2095-01-01T00:00:00Z | 190.96 | 90.92 | 69.18 | 121.78 | 21.74 | 67.0 |
| 2099-12-31T23:59:59Z | 202.65 | 93.18 | 69.18 | 133.47 | 24.00 | 73.4 |
| 2100-01-01T00:00:00Z | 202.65 | 93.18 | 69.18 | 133.47 | 24.00 | 73.4 |
| 2100-01-01T12:00:00Z | 202.65 | 93.18 | 69.18 | 133.47 | 24.00 | 73.4 |

Reading the table:

* Through the year 2000 the three agree within about 0.8 second (Astronomy
  Engine against Horizons) and within about 0.7 second (Swiss against Horizons;
  1975 to 2000, where Swiss follows its own series rather than the EOP file).
* The library's model has already drifted from the known value: +2.4 s at 2020
  and +5.3 s at 2025, about 3 arcseconds of Moon longitude for UTC input today.
* Swiss stays within 0.2 s of Horizons to 2030, then diverges upwards to +24 s
  at 2100 (about 14 arcseconds for the Moon, matching the +13.9 measured
  earlier).
* Horizons holds ΔT constant at 69.18 s from 2020 on.
* The library reaches +133.5 s over Horizons at 2100.

## 4. Effect on UTC-input results (device run on the emulator, 2026-11-22)

The same adapter calls, compared with Horizons asked at the same UTC instants
as UT ("UTC-input", printed as information, no threshold) and with Horizons
asked at the TT the adapter's own conversion assigns (the ACC-2 gate, 60
arcseconds). Maximum over the 53 instants, in arcseconds.

| Body | TT-equivalent (gate) | UTC-input (information) | UTC-input worst instant |
|---|---|---|---|
| Sun | 1.985 | 5.412 | 2100-01-01T12:00:00Z |
| Moon | 3.399 | **78.599** | 2099-12-31T23:59:59Z |
| Mercury | 10.883 | 10.885 | 1925-01-01T00:00:00Z |
| Venus | 11.616 | 11.638 | 2026-11-12T00:00:00Z |
| Mars | 4.448 | 5.065 | 2100-01-01T12:00:00Z |
| Jupiter | 6.445 | 6.744 | 2055-01-01T00:00:00Z |
| Saturn | 11.493 | 11.490 | 1975-01-01T00:00:00Z |
| Uranus | 11.029 | 11.030 | 2000-01-01T00:00:00Z |
| Neptune | 17.590 | 17.506 | 2090-01-01T00:00:00Z |
| Pluto | 8.169 | 8.199 | 2099-12-31T23:59:59Z |

Only the Moon (about 0.55 arcsecond per second) and, much less, the Sun (about
0.04) move fast enough for the ΔT gap to show; the planets are dominated by
their theory error of 4 to 18 arcseconds, the same in both columns. The Moon's
UTC-input error grows with the gap: under 3.4 arcseconds to 2026, 24 at 2061,
57 at 2090 and 78.6 at 2100. **The adapter's UTC-input accuracy against
Horizons is therefore not within 60 arcseconds for the Moon after about 2092.
This is recorded as a measured fact, not hidden by the TT test.** What a user
of the app gets from this backup for the Moon at far-future UTC depends on
which ΔT is closer to the Earth's real rotation, which nobody can know today.

## 5. What the TT-consistent test shows, and what it does not

It shows: the astronomical position model (planetary and lunar theory, the
frame chain to the true ecliptic and equinox of date, light time, aberration)
is within the 60-arcsecond bound of Horizons: the largest figure is 17.6
arcseconds (Neptune), the Moon 3.4 and Pluto 8.2, for ten bodies at 53
instants from 1899-12-31 to 2100-01-01. The adapter is called with a UTC
instant through the production path.

It does not show:

1. **Anything about the library's ΔT.** The TT is the library's own, so its ΔT
   is on both sides. A wrong ΔT cannot fail the gate. That is the intended
   separation (owner decision, 2026-11-22), and why section 3 exists.
2. **Which ΔT is closer to the truth.** For the future no source is true.
3. **UTC-input accuracy for far-future instants** (section 4).
4. **Leap seconds and UT1.** All three treat the instant as UT (Dart's
   `DateTime` has no leap seconds; Horizons uses UT1 before 1962 and UTC
   after). UT1 − UTC is under 0.9 second, at most about 0.5 arcsecond for the
   Moon, and none of the three models it here.
5. **The Horizons TDB − TT term** (at most about 1.7 ms, under 0.001 arcsecond
   for the Moon) and the nine-decimal Julian day of the request (about 86
   microseconds) are ignored.
6. **The reference is Horizons, not truth.**

The conversion is not bypassed or hidden by the test:

* the adapter is always called with the UTC instant, never with a TT;
* the shim converts through one helper, and a host guard requires exactly one
  `Astronomy_TimeFromDays` call, four helper calls, and no banned time call or
  `.tt` / `.ut` write in the project-authored sources (residual limit:
  upstream's own `Astronomy_AddDays` re-derives TT from UT; that is upstream
  behaviour and is not guarded);
* `bodyState`, `rawBufferForTesting` and `timeForTesting` derive the UT days
  through one private method (a host scan);
* the device pin test calls the hook with each fixture instant and requires the
  fixture's UT days (1e-9 d), TT days (1.157e-8 d, one millisecond) and ΔT (1
  ms) to match, so a change of the conversion fails the pin and the fixture
  must be regenerated and reviewed.

### Mutation proofs (emulator and host, 2026-11-22; none committed)

| Mutant | Pin test | ACC-2 TT gate | Host structural guard |
|---|---|---|---|
| (a) +20 s added to TT in the helper | **fails** (TT differs by 2.3e-4 d) | passes (Moon 15.192″) | **fails** (a `.tt` write) |
| (a') +100 s | **fails** (1.157e-3 d) | **also fails** (Moon 64.144″ at 1995-01-01) | **fails** |
| (b) the hook returns UT as TT | **fails** (3.2e-5 d) | passes (hook only) | passes (the shim conversion is untouched) |
| (c) `t.tt += 20 s` after the helper call in `zodiann_body_state` | passes (the hook path is separate) | passes (Moon 3.399″, no Moon change) | **fails** (a `.tt` write) |

The gate alone would have passed a 20-second ΔT change (the blind spot is
shown), and the pin and the guard are what catch it. Mutant (b) shows the pin
is sensitive to the hook itself; mutant (c) shows that an edit after the helper
inside the production path leaves the pin green and is caught only by the
structural guard, which is why the guard exists. All mutations were reverted
(`git status` clean for the shim afterwards).

## 6. ZOD-TST-001: the conflict, recorded and not resolved

ZOD-TST-001's T-EPH-1 requires the Sun and the Moon within 1 arcsecond of
Horizons at the reference instants, by UT input. This task found that **no
adapter can meet that bound for the Moon at far-future UT instants**, because
every source assumes a different future ΔT:

* the Astronomy Engine adapter: 78.6 arcseconds at 2099-12-31, and about 3
  arcseconds at 2025 already;
* Swiss Ephemeris: about 14 arcseconds at 2100 (a 24 s gap), about 3 at 2050
  (5.4 s), and under 0.2 second of gap to about 2030;
* a gap of 1 arcsecond corresponds to about 1.7 s of ΔT, so the bound is
  reachable only where the sources' ΔT agree to about 2 seconds: to about 2015
  for the library, to about 2035 for Swiss.

Implications for the owner (this task chooses none and does not claim to
resolve the conflict; ZOD-TST-001's file and criteria are not edited):

* a T-EPH-1 comparison at UT instants cannot pass for the Moon beyond those
  years with any source, so the test as written is unsatisfiable for the Moon
  over the whole 1900 to 2100 set;
* options include a TT-consistent reference (as this task does), a restricted
  date range for the Moon, a different bound for the Moon, or a project-level
  decision on the ΔT model; each needs a separate decision;
* ZOD-TST-005 re-runs the shared set against this adapter and will meet the
  same effect; a Notes line carries this fact to it.

## 7. The ΔT model: not replaced

A change of any engine's ΔT is a product decision. It would need an explicit
proposal covering both engines (Swiss Ephemeris and Astronomy Engine), the
choice of an extrapolation for the future, the compatibility consequences
(charts computed today would shift when a new model is adopted; the Swiss
primary and the Astronomy Engine backup would need to agree), and the
interaction with ZOD-TST-001. This document makes none.

## 8. Reproduction

* The TT fixture: `dart run tool/fetch_horizons_tt_reference.dart` in
  `packages/ephemeris_astronomy`, with network access and `gcc`.
* The table of section 3: `dart docs/spikes/ZOD-EPH-004-delta-t/measure_delta_t.dart`
  from the repository root, with network access and `gcc` (it builds
  `swiss_delta_t.c` against the vendored Swiss sources in a temporary
  directory; nothing is distributed). The helpers are spike tooling outside the
  Melos packages; the project's lint and format gates do not cover them.
* The device run: `flutter test integration_test/astronomy_accuracy_test.dart
  -d emulator-5554` in `apps/astro_mobile`.
