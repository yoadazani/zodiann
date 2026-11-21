# ZOD-EPH-004: analytic derivative of the Moon series, feasibility and derivation

Written 2026-11-21, before any implementation, after the owner chose Option 2 (differentiate the Moon series analytically in our C shim; no finite differences, including ones inherited from the upstream library). Source read: astronomy-engine v2.1.19, `source/c/astronomy.c`, commit `61dc07020aaa6885d2c7f688a4d82beaf6edb9ef`, blob `713bc1aeee87a04f8512477b984c4f43f3fb30e7` (read from a verified download; not yet vendored in the repository). Line numbers below are that file's.

**Verdict: feasible, with a complete verification plan that uses no finite differences.** Every quantity in `CalcMoon` is a closed-form function of one variable T (Julian centuries of TT since J2000): sines and cosines of arguments that are polynomials in T, products, and one reciprocal. No iteration, no table lookup, no numerical derivative inside the function. Nothing blocks the work. Two items need the owner's attention and are listed in section 6.

## 1. Which code computes the position (upstream) and which computes the velocity (ours)

| | Source |
|---|---|
| Moon position (λ, β, R in the ecliptic of the mean equinox of date, "ECM") | **Upstream**, `CalcMoon(T, &lon, &lat, &dist)`, lines 2150 to 2277, using `Init`, `LongPeriodic`, `AddSol` (104 calls), `SolarN` (10 terms), `Planetary` (11 terms), `Term`, `AddThe`, `Sine`, `Frac` (lines 1950 to 2148) |
| Moon position in ECT (true equinox of date) | **Upstream**, `Astronomy_EclipticGeoMoon` (line 2378): ECM to EQM with the mean obliquity (`obl_ecl2equ_vec`), nutation to EQD (`nutation`), then to ECT with the true obliquity (`RotateEquatorialToEcliptic`) |
| Moon velocity | **Project-authored** (this document, then `native/astronomy_c/zodiann_moon_rate.c`): the exact derivative of the same series with respect to T, converted to per day |
| Not used, by owner ruling | `Astronomy_GeoMoonState` (line 2433, a central difference with dt = 1e-5 days), `Astronomy_GeoEmbState`, and `Astronomy_BaryState` / `Astronomy_HelioState` with `BODY_MOON` or `BODY_EMB` (they call it) |

## 2. The series, term by term, and its derivative

Notation: ˙ means d/dT (per Julian century). A conversion to degrees per day is in section 3. ARC = 3600·180/π (arcseconds per radian). All angles in radians unless stated.

### 2.1 Long-periodic terms (`LongPeriodic`, lines 2019 to 2037)

Seven sines `S_i = sin(2π(a_i + b_i T))` (a_i, b_i are the constants in the source) give `S_i˙ = 2π b_i cos(2π(a_i + b_i T))`. `DL0`, `DL`, `DLS`, `DF` are fixed linear combinations of the `S_i`, so their derivatives are the same combinations of `S_i˙`. `DD = DL0 − DLS`, so `DD˙ = DL0˙ − DLS˙`. `DGAM` is three scaled sines; `DGAM˙ = Σ k_j · 2π b_j cos(2π(a_j + b_j T))`.

### 2.2 Fundamental arguments (`Init`, lines 2039 to 2077)

`L0 = 2π·Frac(a + bT + cT²) + DL0/ARC`, and likewise for `L`, `LS`, `F`, `D` (with `DL`, `DLS`, `DF`, `DD`). `Frac(x) = x − floor(x)` has derivative 1 everywhere it is continuous; at its jumps the angle changes by exactly 2π, and every use is inside `sin`/`cos` or a final reduction modulo 2π, so the wrap does not affect the derivative of any quantity that is used. Therefore, for each argument with constants (a, b, c):

`ARG˙ = 2π(b + 2cT) + DARG˙/ARC`.

### 2.3 The scaled harmonics (`Init`, lines 2055 to 2073) and the terms (`Term`, `AddSol`)

For each of the four arguments k (L, LS, F, D) the code builds `CO(1,k) = FAC_k cos ARG_k`, `SI(1,k) = FAC_k sin ARG_k`, then higher harmonics by `AddThe`, a complex multiplication, and the negative harmonics by `CO(−j) = CO(j)`, `SI(−j) = −SI(j)`. In complex notation `z_k = FAC_k e^{i ARG_k}`, `CO(j,k) + i·SI(j,k) = z_k^j` for j > 0 and `= conj(z_k)^|j|` for j < 0. `FAC_k` is: L, `1.000002208` (constant); LS, `0.997504612 − 0.002495388T`; F, `1.000002708 + 139.978·DGAM`; D, `1`.

A term `Term(p,q,r,s)` returns `w = x + i·y = Π_k (z_k or conj z_k)^|n_k|` over the nonzero `n = (p, q, r, s)`. Taking the logarithmic derivative factor by factor:

`w˙ = w · Σ_k ( |n_k|·α_k + i·n_k·ARG_k˙ )`, where `α_k = FAC_k˙ / FAC_k`:
- L and D: `α = 0`.
- LS: `α = −0.002495388 / FAC_LS`.
- F: `α = 139.978·DGAM˙ / FAC_F`.

(For a negative `n_k` the conjugate gives the factor `|n_k|·α − i·|n_k|·ARG˙ = |n_k|α + i n_k ARG˙`, which is why one formula covers both signs.)

`AddSol(coeffl, coeffs, coeffg, coeffp, p,q,r,s)` adds `coeffl·y` to `DLAM`, `coeffs·y` to `DS`, `coeffg·x` to `GAM1C`, `coeffp·x` to `SINPI`; `SolarN` adds `coeffn·y` to `N`. Each accumulator is linear in `x` or `y`, so:

`DLAM˙ = Σ coeffl·Im(w˙)`, `DS˙ = Σ coeffs·Im(w˙)`, `GAM1C˙ = Σ coeffg·Re(w˙)`, `SINPI˙ = Σ coeffp·Re(w˙)`, `N˙ = Σ coeffn·Im(w˙)`.

### 2.4 Planetary terms (`Planetary`, lines 2137 to 2148)

Eleven terms `A_j·sin(2π(a_j + b_j T))` added to `DLAM`; their derivative is `Σ A_j·2π b_j cos(2π(a_j + b_j T))`, added to `DLAM˙`.

### 2.5 Assembly (`CalcMoon`, lines 2268 to 2276)

- `S = F + DS/ARC`, so `S˙ = F˙ + DS˙/ARC`.
- `lat_seconds = G·H·sin S − 6.24·sin 3S + N` with `G = 1.000002708 + 139.978·DGAM`, `H = 18518.511 + 1.189 + GAM1C`, so `lat_seconds˙ = G˙·H·sin S + G·H˙·sin S + G·H·cos S·S˙ − 18.72·cos 3S·S˙ + N˙`, with `G˙ = 139.978·DGAM˙`, `H˙ = GAM1C˙`.
- `λ = (L0 + DLAM/ARC) mod 2π`, so `λ˙ = L0˙ + DLAM˙/ARC`.
- `β = lat_seconds·π/648000`, so `β˙ = lat_seconds˙·π/648000`.
- `R = ARC·Re / (0.999953253·SINPI)` (Re the Earth's equatorial radius in AU), so `R˙ = −R·SINPI˙/SINPI`.

## 3. From the series derivative to the quantity the adapter needs

- Per day: the library calls `CalcMoon(time.tt / 36525.0, …)`, so `T = tt/36525`. With `tt = ut + ΔT/86400` (days), `dT/d(ut) = (1 + ΔT˙/86400)/36525`. The shim receives UT days; the factor used is `1/36525`. **Omitted term:** the rate of ΔT (the library's Espenak and Meeus model, about 8e-4 s per day now, so a relative change of about 1e-8 in the time scale) shifts the Moon's speed by about 1e-7 degrees per day (estimate: 13 °/day × 1e-8).
- Cartesian state in ECM, exact from the spherical rates: `r = R·(cosβ cosλ, cosβ sinλ, sinβ)` and `v = R˙·û + R·β˙·ê_β + R·cosβ·λ˙·ê_λ`, with `û = r/R`, `ê_λ = (−sinλ, cosλ, 0)`, `ê_β = (−sinβ cosλ, −sinβ sinλ, cosβ)`.
- To ECT: apply to both `r` and `v` the same fixed (frozen at the instant) linear chain the library applies to the position: `obl_ecl2equ_vec(mobl)`, `nutation`, `RotateEquatorialToEcliptic(tobl)`. The adapter then uses `λ˙ = (x·vy − y·vx)/(x² + y²)` in Dart, as for every other body (D1).
- Note on precession: the Moon's arguments are measured from the moving mean equinox of date, so their linear terms already contain the precession of the equinox. The speed of the Moon in this frame therefore **includes** the precession rate that D1 omits for the other bodies.

## 4. Approximations and omitted terms (every one stated)

| Item | Size (estimate, not measured) | Where |
|---|---|---|
| Rate of change of the frozen ECM-to-ECT rotation (nutation in longitude and obliquity) | up to about 5e-5 °/day (the 13.7-day term, amplitude about 0.23 arcsecond, gives about 2.9e-5; the semiannual term about 1.3e-5; the 18.6-year term about 4.4e-6) | omitted, same kind as the frame-rate term D1 already lists for the other bodies |
| `ΔT` rate in `T` | about 1e-7 °/day | omitted |
| Light time and aberration of the Moon | none applied to the position by the library; the omitted planetary aberration of the Moon is of the order of 1 arcsecond (the Moon moves with the Earth); its rate is about 1e-5 °/day or less | not modelled, as in the library's position |
| Truncation of the lunar theory itself (the 1954 *Improved Lunar Ephemeris* series, truncated) | position errors of a few arcseconds at monthly periods imply speed differences from Swiss Ephemeris of the order of 1e-4 to 1e-3 °/day | **not** an error of the derivative: it is the difference between two theories and is what the Swiss comparison will show |

None is a finite difference, and none is hidden: they are stated here, in the adapter documentation and in the findings.

An earlier note of this plan said the Moon's missing aberration was "up to about 20.5 arcseconds". That is wrong for the Moon (20.5 arcseconds is the annual aberration of distant objects); the figure above replaces it.

## 5. Verification, with no finite differences anywhere

1. **Value regression.** Our transcription of the series must reproduce upstream's `CalcMoon`. Both run in the same translation unit (the shim `#include`s the unmodified `astronomy.c`, which gives it access to the static `CalcMoon`); a device test compares `(λ, β, R)` from our value path against `CalcMoon` at 10,000 instants across 1899 to 2100, with a bound of 1e-11 radians (and 1e-11 relative for R). The bound is 1e-11 and not tighter because the arguments reach about 1337 revolutions, where one unit in the last place is about 1.4e-12 radians; 1e-11 is still 50 times below the smallest coefficient slip to be caught (a 0.0001-arcsecond slip is 4.8e-10 radians). This proves the hand-copied constants are right.
2. **Generated term table.** The 114 table terms (104 `AddSol`, 10 `ADDN`) are not typed by hand: `tool/gen_moon_terms.dart` parses them from the vendored `astronomy.c` and writes `native/astronomy_c/zodiann_moon_terms.h`; a host test regenerates the header from the vendored source and requires byte equality with the committed file.
3. **Integral identity (test-only; it differentiates nothing; whether the owner accepts it is D11 in the plan).** Over 400 composite intervals of 7 days (28 panels of 6 hours, an 8-point Gauss-Legendre quadrature each), a quadrature of our analytic `λ˙` must equal the change of the library's own `λ` (unwrapped) within 1e-9 degrees; likewise for `β` (1e-9 degrees) and `R` (1e-12 AU). A missing or wrong term in the derivative breaks the identity; the smallest term, the derivative of `FAC_LS`, is about 3e-9 degrees per 6-hour panel at best phase, so the 7-day intervals are used to raise it to about 8e-8 degrees, above the tolerance. It does not use finite differences to produce or check the speed; it integrates the analytic rate and compares the result with a change of position, which is the point the owner is asked to rule on.
3a. **Rotation invariants (no differencing).** The shim's ECT `(r, v)` must have the same `|v|`, `r·v` and `|r × v|` as the ECM `(r, v)`, each within 1e-12 relative, so a wrongly rotated velocity cannot hide behind the Swiss noise (an unrotated velocity paired with a rotated position would change the rate by about 6e-5 °/day, inside the expected Swiss noise).
4. **Banned identifiers (host test).** A scanner strips comments and string literals, then rejects any call of `Astronomy_GeoMoonState`, `Astronomy_GeoEmbState`, `Astronomy_HelioState` or `Astronomy_AddDays`, and any `Astronomy_BaryState(` call whose first argument is `BODY_MOON` or `BODY_EMB`; the scanner itself is unit-tested on bad and clean snippets. Reading the upstream source shows nothing on the Sun or planet path reaches `GeoMoonState` (its callers are `GeoEmbState`, `BaryState` and `HelioState` for the Moon and EMB, and one minor-body function).
5. **Swiss comparison (D7).** The Moon's speed against `swe_calc_ut`'s Moon speed over the dense set (every 6 hours, 2025-01-01 to 2027-01-01, plus the 53 reference dates). This measures theory difference plus the omitted terms of section 4, and the owner fixes the Moon's bound from it. The Moon has no stations (its speed stays between about 11.8 and 15.4 degrees per day), so the retrograde and station checks do not apply to it.

## 6. Two things the owner needs to know

1. **Transcription and coupling risk.** About 100 hand-copied constants (the `Init` polynomials and `FAC` factors, about 44 in `LongPeriodic`, about 33 in `Planetary`, and the latitude and distance formulas) are covered by the value regression (item 1 above), not by a generator. The `#include "astronomy.c"` technique ties the shim to the exact vendored version; the manifest guard and the regression test make a version change fail loudly.
2. **A separate open question that may affect the other bodies' thresholds (D10 in the plan).** The library is inconsistent about what the VSOP "Earth" point is: `Astronomy_BaryState(BODY_EARTH)` and `Astronomy_GeoVector` use it as the Earth's centre, while line 3912 passes `EARTH_GM + MOON_GM` for it in the gravity-simulation code, which treats it as the Earth–Moon barycentre. The tables carry no label, so this is a hypothesis, not an established fact. If it is the barycentre, the offset has a period of 27.3 days and a velocity of about 12.4 m/s (about 7.2e-6 AU/day), which shifts the apparent longitude rate of a body at distance d (AU) by up to about 4.1e-4/d degrees per day: about 4.2e-4 for the Sun, up to about 1.5e-3 for Venus, about 1.1e-3 for Mars, about 7.5e-4 for Mercury. The approved D7 bounds for the Sun, Venus and Mars (3e-4, 4.5e-4, 3e-4) would then probably be exceeded by this effect alone. The plan records it as an open owner decision (E0 measure first, E1 leave as approved and stop-and-report on failure, E2 correct the observer velocity with the Moon derivative built here).
