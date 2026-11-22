# ZOD-EPH-004: the astronomy-engine `EphemerisPort` adapter (backup and oracle), findings

Written 2026-11-22 at the end of the task. Scope: Android and host. iOS is
deferred (no macOS access, no spending: owner constraint of 2026-11-20) and is
**not** verified. Plan: [`docs/plans/ZOD-EPH-004-astronomy-engine-adapter.md`](../plans/ZOD-EPH-004-astronomy-engine-adapter.md)
(decisions D1 to D12). Companion records: [`ZOD-EPH-004-moon-derivative.md`](ZOD-EPH-004-moon-derivative.md),
[`ZOD-EPH-004-earth-point-measurement.md`](ZOD-EPH-004-earth-point-measurement.md),
[`ZOD-EPH-004-delta-t.md`](ZOD-EPH-004-delta-t.md),
[`ZOD-EPH-004-retarded-velocity.md`](ZOD-EPH-004-retarded-velocity.md),
[`ZOD-EPH-004-swiss-speed-reference.md`](ZOD-EPH-004-swiss-speed-reference.md).

## 1. Verdict

* **ACC-2 is met on an Android emulator at equivalent TT instants.** Ten
  bodies, the 53 instants of `reference_dates.json`, 1899-12-31 to
  2100-01-01, within 17.6 arcseconds of JPL Horizons (bound 60). Pluto is
  measured on its own: 8.169 arcseconds. The criterion is judged at equivalent
  TT instants by the owner's decision of 2026-11-22 (D12); at UTC instants the
  Moon is 78.6 arcseconds off at 2099-12-31 because of ΔT (section 4). That is a
  measured limit, not a pass.
* **The longitude speed is analytic, with no finite difference anywhere**,
  including upstream code. It agrees with Swiss Ephemeris, evaluated at the
  same TT, within the owner-approved bounds for all ten bodies and at every
  planetary station (section 5).
* **Swapping to this backup is one DI override** (host test, section 8).
* **The node still uses the ZOD-EPH-001 formula**: `with MeanAscendingNodeFormula`,
  the native source is never called for it.
* Not done, by decision: no automatic fallback (D5, ZOD-EPH-002 owns it); iOS;
  no CI run of the device tests (D3).

## 2. What was built

| Piece | Where |
|---|---|
| astronomy-engine v2.1.19 (commit `61dc07020aaa6885d2c7f688a4d82beaf6edb9ef`, MIT), vendored byte for byte, with a guard | `native/astronomy_c/upstream/`, `MANIFEST.json`, `VENDORED.md`, `test/architecture/astronomy_vendored_test.dart` |
| Flat C shim, one translation unit that includes the unmodified `astronomy.c` | `native/astronomy_c/zodiann_astronomy_shim.{c,h}` |
| The Moon's value path and its exact analytic derivative; the 114-term table is generated from the vendored source | `zodiann_moon_rate.{c,h}`, `zodiann_moon_terms.h`, `packages/ephemeris_astronomy/tool/gen_moon_terms.dart` |
| Android-only build hook, ffigen bindings | `packages/ephemeris_astronomy/hook/build.dart`, `tool/ffigen.dart`, `lib/src/ffi/astronomy_bindings.g.dart` |
| Pure Dart: the longitude rate, the value types, the port | `lib/src/longitude_rate.dart`, `body_state.dart`, `astronomy_ephemeris.dart` |
| The native source (device only) | `lib/src/native_body_state_source.dart`, `lib/ephemeris_astronomy_native.dart` |
| Horizons fixtures (UT and TT) and their fetch tools | `test/fixtures/reference_longitudes{,_tt}.json`, `tool/fetch_horizons_{,tt_}reference.dart`, `tool/tt_grid.c` |
| Device tests: ACC-2, the Moon derivative, the retarded velocity, speed against Swiss | `apps/astro_mobile/integration_test/astronomy_{accuracy,moon_derivative,retarded_velocity,speed_vs_swiss}_test.dart` |
| The DI swap test | `apps/astro_mobile/test/di/astronomy_swap_test.dart` |
| `swe_calc`, `calcTt`, `julianDayTt`, `seflgNogdefl` added to the Swiss binding (owner's Option A) | `packages/ephemeris_swiss` |

`AstronomyEphemeris with MeanAscendingNodeFormula implements EphemerisPort`:
UTC is enforced (`ArgumentError`); the node is answered first, for any instant;
outside the covered range the answer is `OutOfCoveredRange`, never an
approximate position; one source call per position. `EphemerisPort`,
`astro_core` and the specification are unchanged.

Covered range (D4, reaffirmed 2026-11-22): `1899-12-31T12:00Z` to
`2100-01-01T12:00Z`, the span ACC-2 was proved over.

## 3. Owner decisions that shaped the task

| | Decision (owner, date) |
|---|---|
| D1 | Speed analytic from the library's own state vectors, no finite differences, no exceptions (2026-11-21); the Moon's velocity is our analytic derivative of the lunar series (Option 2, 2026-11-21); the Sun and planets use the body's velocity at the light-time-retarded instant, variant V2 (2026-11-22) |
| D4 | Covered range 1899-12-31 to 2100-01-01 (2026-11-21, reaffirmed 2026-11-22) |
| D5 | No automatic fallback here; ZOD-EPH-002 owns source selection (2026-11-21) |
| D6 | The ACC-2 fixture covers all 53 reference instants and ten bodies (2026-11-21) |
| D7 | Speed bounds: Mercury 0.0012, Venus 0.00045, 0.0003 for the Sun and Mars to Pluto (2026-11-21); the Moon's 0.0007 confirmed 2026-11-22 |
| D10 | Measure the Earth point first (E0): not confirmed, so E1 stands (2026-11-21) |
| D11 | Keep the integral-identity test, integrating in TT (2026-11-21) |
| D12 | ACC-2 at equivalent TT instants; ΔT documented separately; ZOD-TST-001 unchanged; the ΔT model not replaced (2026-11-22); Swiss evaluated at the same TT (D12-O1) |
| 2026-11-22 | Swiss reference without gravitational deflection (`SEFLG_NOGDEFL`) after the Uranus finding |

## 4. ACC-2: longitude against JPL Horizons

Quantity 31 (observer ecliptic longitude, apparent, true equinox of date),
geocentric centre. Maximum over the 53 instants, in arcseconds, on the Android
emulator, 2026-11-22.

| Body | TT-equivalent (the gate, bound 60) | UTC-input (information) |
|---|---|---|
| Sun | 1.985 | 5.412 |
| Moon | 3.399 | **78.599** |
| Mercury | 10.883 | 10.885 |
| Venus | 11.616 | 11.638 |
| Mars | 4.448 | 5.065 |
| Jupiter | 6.445 | 6.744 |
| Saturn | 11.493 | 11.490 |
| Uranus | 11.029 | 11.030 |
| Neptune | 17.590 | 17.506 |
| **Pluto** | **8.169** | 8.199 |

* **Pluto.** The library models Pluto with its own gravity simulation and
  states no accuracy for it; measured here, it is among the better planets in
  this range. Its longitude and its speed are reported on their own row in every
  table, never folded into a "worst of all" figure.
* **Equivalent TT instants (D12).** The adapter is called with the UTC instant;
  Horizons is asked at the TT the adapter's own conversion assigns; a device pin
  test requires the hook's UT days, TT days and ΔT to match the fixture within 1
  millisecond; one conversion helper in the shim is guarded structurally; mutation
  proofs (a 20-second ΔT change fails the pin, the 100-second one fails the gate
  as well, a post-helper TT edit fails only the structural guard).
  [`ZOD-EPH-004-delta-t.md`](ZOD-EPH-004-delta-t.md) has the full table and the
  limits.
* **What the TT test cannot see.** The library's own ΔT. At UTC instants the
  Moon is under 3.4 arcseconds to 2026, 24 at 2061, 57 at 2090, 78.6 at 2100: it
  exceeds 60 arcseconds after about 2092. Swiss Ephemeris shows the same effect
  smaller (about 14 arcseconds at 2100); Horizons holds ΔT at 69.18 s for the
  future. No source is "true" for future ΔT.
* **Frame checks.** ACC-2's 60 arcseconds cannot catch a mean-versus-true-equinox
  slip (nutation is at most about 17 arcseconds). The Sun's longitude from
  `Astronomy_SunPosition` agrees with the rotated vector within 0.357
  arcsecond. For the Moon, `Astronomy_EclipticGeoMoon` and `atan2` of our
  value path agree to 5.7e-14 degrees: a regression check, not an independent
  frame check, since both apply the same chain. **For the planets there is no
  independent in-library path**, so their frame rests on the reading of
  `Astronomy_Rotation_EQJ_ECT` and on the Horizons maxima above (a slip of 17
  arcseconds or less would show only if the observed errors stayed under about
  10 arcseconds; Mercury, Venus, Saturn, Uranus and Neptune sit above that, so
  no frame guarantee beyond the Horizons agreement is made for them).
* **E0 (Earth point).** Library line 3912 hints that the VSOP "Earth" point may
  be the Earth–Moon barycentre. Measured against Horizons over 60 days, the
  Sun's longitude is within 0.37 to 1.30 arcseconds, the fit coefficient to a
  27.3-day barycentre signal is 0.015 against 1, so the hypothesis is not
  confirmed; the approved formulation stands ([`ZOD-EPH-004-earth-point-measurement.md`](ZOD-EPH-004-earth-point-measurement.md)).

## 5. The longitude speed (CRS-A1): analytic, compared with Swiss Ephemeris

**Formulation, stated plainly.** For the Sun and the planets: the geocentric
velocity is `v_body(t − τ)(1 − dτ/dt) − v_earth(t)` in the true ecliptic of
date, with `τ` the light time, `v` the library's analytic `Astronomy_BaryState`
velocities (VSOP derivatives; for Pluto the library's gravity-simulation state),
and the longitude speed is `(x·vy − y·vx)/(x² + y²)`. For the Moon: the exact
derivative of upstream's `CalcMoon` series (project-authored C), built in the
mean-equinox ecliptic and rotated by the library's own frozen chain.
`Astronomy_GeoMoonState` (a central difference upstream) is never called; a
host guard scans the project's native sources for it and the other banned
calls. **This is not the derivative of the fully apparent longitude.** It omits
the derivative of the aberration correction (about 9.8e-5 degrees per day) and
the rotation rate of the ecliptic-of-date frame (about 3.8e-5), and for the
Moon the nutation and obliquity rate (about 5e-5) and the ΔT rate (about 1e-7).

**The Moon's derivative is verified in layers** (device, no finite
differences): value regression against upstream's `CalcMoon` over 10,000
instants (worst error 0.0 in longitude, latitude and distance, bit identical); an integral identity in TT (a
quadrature of the analytic rate against the change of upstream's position, 400
seven-day intervals, worst 1.3e-10 degrees against a 1e-9 bound; it integrates
the rate and differentiates nothing, owner decision D11); rotation invariants
(relative, at most 7.0e-16); ten deliberately wrong derivatives, run on the host in a scratch build outside the repository (recorded in the session ledger, which is not in the repository), each pushed the integral identity above its tolerance; a generated table with a
byte-equality guard.

**Speed against Swiss Ephemeris** (device; both engines at the same TT through
the adapter's hook and `swe_calc`; every Swiss sample from the data files). The
Swiss flags are `SEFLG_SWIEPH | SEFLG_SPEED | SEFLG_NOGDEFL`.

| Body | Max difference (deg/day) | Approved bound |
|---|---|---|
| Sun | 0.000121 | 0.0003 |
| Moon | 0.000573 | 0.0007 |
| Mercury | 0.000784 | 0.0012 |
| Venus | 0.000267 | 0.00045 |
| Mars | 0.000194 | 0.0003 |
| Jupiter | 0.000192 | 0.0003 |
| Saturn | 0.000197 | 0.0003 |
| Uranus | 0.000206 | 0.0003 |
| Neptune | 0.000199 | 0.0003 |
| **Pluto** | **0.000206** | 0.0003 |

* **Retrograde sign:** 0 mismatches for every body at every sample whose
  `|Swiss speed|` exceeds the fixed bound (Mercury 7,605 samples checked, Venus
  1,553, Mars 1,181, Jupiter 2,249, Saturn 2,369, Uranus 2,428, Neptune 2,440,
  Pluto 2,441).
* **Stations** (the zero crossing of the speed, found by bisection on a sign
  change; a search, not a derivative). Found by a daily Swiss scan over 1900 to
  2099 and bisected to a minute, each sampled at the station and at ±1, ±5 and
  ±20 days. Offset of the adapter's crossing from Swiss's, bound 1 day (1,440
  minutes):

| Planet | Stations | Max offset (min) | Mean (min) |
|---|---|---|---|
| Mercury | 1,260 | 11.9 | 2.8 |
| Venus | 250 | 9.1 | 2.4 |
| Mars | 188 | 16.2 | 5.2 |
| Jupiter | 366 | 80.8 | 36.1 |
| Saturn | 386 | 152.6 | 74.1 |
| Uranus | 396 | 317.1 | 155.8 |
| Neptune | 398 | 478.8 | 247.3 |
| **Pluto** | 398 | 758.7 | 323.5 |

  Every station had a crossing; none was skipped. One Uranus and one Neptune
  sample fell outside the covered range and were counted, not hidden. The
  outer-planet offsets are the largest because the speed slope at a station is
  small (about 2.7e-4 °/day² for Neptune); Pluto's 758.7 minutes (0.53 day) is
  the largest and well inside the bound.
* **Mercury's path.** The first run (velocity at `t`) gave 0.001590 against
  0.0012: the light-time term D7 had predicted. The retarded-instant
  refinement fixed it (0.000784); an estimate before applying showed it would,
  and the device run matched the estimate exactly.
* **Uranus's path.** The first runs gave 0.000460 at 2075-01-01 against 0.0003.
  The cause is a glitch in Swiss's own gravitational-deflection speed
  correction near solar conjunction (Swiss data files and Swiss's Moshier
  agree to 1e-5 there, so the glitch is in shared code; it disappears with
  `SEFLG_NOGDEFL`). No defensible exclusion rule exists (a continuous tail of
  anomalies), so the owner approved the deflection-free Swiss reference.
  Astronomy Engine applies no deflection, so that reference is like for like.
  A daily scan over 73,049 days then has no sample over any approved bound for
  any body ([`ZOD-EPH-004-swiss-speed-reference.md`](ZOD-EPH-004-swiss-speed-reference.md)).

**Limits of the speed result.**
* The Moon's bound 0.0007 is backed by the observed maximum 0.000573 over
  2025-01-01 to 2027-01-01 at six-hour spacing plus the 53 reference instants
  only (the 53 alone: 0.000251). Other epochs are not claimed.
* The reference is Swiss without light deflection; with deflection Swiss's own
  speed is unreliable near conjunction. The adapter's speed has not been
  compared with a deflection-aware reference.
* The omitted terms above, and the Swiss comparison measures the difference
  between two implementations, not the error against an exact derivative.
* The stations and the speed tests run on the emulator only (D3): no CI run;
  ZOD-TST-017 owns a release-blocking run.

## 6. ΔT

[`ZOD-EPH-004-delta-t.md`](ZOD-EPH-004-delta-t.md): the library's ΔT is +133.5 s
over Horizons at 2100 (and +5.3 s at 2025, about 3 arcseconds of Moon today),
Swiss's +24 s; the effect on UTC-input results; the limits of the TT-consistent
test; the conflict with **ZOD-TST-001**'s 1-arcsecond Moon bound (unreachable at
far-future UT by any adapter; recorded, its criteria unchanged, not resolved
here); the ΔT model is not replaced (a separate product decision needing a
proposal for both engines). The specification's literal ACC-1 and ACC-2 text is
unchanged.

## 7. Build, size and platform

* **Android only** (D3): `hook/build.dart` compiles the shim and builds for
  Android; the host loads no native code, so the logic tests inject a fake
  source. A host native build is possible later and not done.
* **Sizes** (stripped, in the debug APK, `flutter build apk --debug`, 2026-11-22):
  `libastronomy.so` 197,240 bytes (arm64-v8a), 206,636 (armeabi-v7a), 249,232
  (x86_64), against `libswisseph.so` 557,904, 572,556 and 644,768.
* **16 KB alignment:** every `LOAD` segment of `libastronomy.so` has alignment
  `0x4000` in all three ABIs (NDK 28.2.13676358), as required for Android 15
  devices with 16 KB pages.
* **Release builds drop unreferenced native assets** (ZOD-FND-003 gotcha 8). The
  library enters an app build only when app code references it. This task adds
  no production wiring, so a release APK does not carry `libastronomy.so` until
  ZOD-EPH-002 or another task imports the native source from app code. Nothing
  in this task hides that.
* **Licence:** astronomy-engine is MIT, kept beside the vendored source
  (`native/astronomy_c/upstream/LICENSE`); the project-authored shim is
  AGPL-3.0-only. Whether a built app carries the MIT notice stays `Unverified`
  (ZOD-ABT-007, ZOD-REL-002).

## 8. DI swap

`apps/astro_mobile/test/di/astronomy_swap_test.dart` (7 tests): one
`ephemerisPortProvider` override binds `AstronomyEphemeris(source: fake)` and a
consumer written against `EphemerisPort` (importing nothing from
`ephemeris_astronomy`) receives the position and the analytic speed; one
override binds an unrelated port and the same consumer runs unchanged;
`appOverrides` stays empty (no production wiring); no file under
`apps/astro_mobile/lib` or `packages/feature_*/lib` imports `ephemeris_astronomy`
and no feature pubspec depends on it. The scan was shown sensitive by two
temporary mutations.

## 9. The iOS checklist (not verified; no macOS access, no spending)

Per the specification (R-7, ARCH-6) iOS is required for the binding of the
primary source; for this backup it is recorded, not claimed. When a Mac is
available:

1. Extend `hook/build.dart` to build the shim for iOS (the same single source
   file; `native_toolchain_c` handles the iOS targets), check the asset id still
   equals the `@Native` binding's, and check the library is not dropped from a
   release build when nothing references it (the same gotcha as Android).
2. Run the four device tests (`astronomy_accuracy_test`,
   `astronomy_moon_derivative_test`, `astronomy_retarded_velocity_test`,
   `astronomy_speed_vs_swiss_test`) on an iOS simulator and a device. The Swiss
   half needs the iOS half of ZOD-FND-003 first.
3. Record library size and the time for the speed test; check bitcode and
   minimum-deployment settings are untouched.
4. The tests do not change; if a number differs from the tables above on iOS
   (floating-point contraction on arm64), that is a finding, not a threshold to
   adjust.

## 10. Proposed contract change: written, **not applied**

The owner decides; `EphemerisPort`, `astro_core` and the specification are
untouched by this task.

**Today** (`packages/astro_core/lib/src/ephemeris/ephemeris_port.dart`, the
speed bullet of `position`): "The speed must come **directly from the ephemeris
source, never from finite-differencing two positions** (CRS-A1)." The
specification's CRS-A1: "The longitude speed (degrees per day) comes directly
from the ephemeris, and retrograde is a negative speed."

**Proposed sentence to add to that bullet:** "A source whose library exposes
position and velocity vectors but no longitude speed may derive the speed
analytically from those vectors, as `(x·vy − y·vx)/(x² + y²)`; finite
differences of positions remain forbidden, whether in the adapter or inherited
from the library."

**What it changes.** For CRS-A1's wording: it would state that "directly from
the ephemeris" includes an analytic derivation from the source's own state
vectors, which this adapter does; nothing in the specification's behaviour
changes. It records that such a speed is the derivative of the geometric
position the library models and not of the fully apparent longitude, and that it
differs from Swiss Ephemeris's speed by up to 0.0012 degrees per day for Mercury
and 0.0003 for the Sun and Mars to Pluto (section 5).

**Consumers affected.** The crossing solver (ZOD-CRS-*), which uses the speed to
seed and bracket crossings, and retrograde detection (ZOD-EPH-005, `speed < 0`):
both only need the sign and an approximate rate, and the station offsets above
(at most 0.53 day, Pluto) bound how far a sign flip can move.

**Alternative:** leave the contract as it is and keep the interpretation inside
this adapter (its documentation says exactly what it computes). The cost is that
a reader of `EphemerisPort` alone could take the adapter for a violation.

## 11. Carry-overs

* **ZOD-EPH-002** owns automatic source selection (D5); a Notes line records it.
* **ZOD-TST-005** must decide how its own T-EPH-1 comparison treats ΔT; a Notes
  line carries the finding (UT instants, TT-consistent reference, a restricted
  Moon range, or another bound).
* **ZOD-TST-001** has the 1-arcsecond Moon conflict (section 6): recorded in
  PROGRESS and here only; its file is not edited.
* **ZOD-TST-017** owns a release-blocking run of the device tests.
* **A deflection-aware Swiss reference** for the speed is not available; if a
  later task needs one, the Swiss glitch near conjunction must be understood
  first.

## 12. Verification of the task

See `docs/PROGRESS.md` for the commands, exit codes and the head commit of the
final run. Commands: `dart run melos run lint`, `dart run melos run test` (the
Full suite with its duration against the 240-second budget), `flutter build apk
--debug`, and the four device suites on the emulator.
