# ZOD-EPH-004: E0, does the library's VSOP "Earth" point behave as the Earth–Moon barycentre?

Measured 2026-11-21, on the owner's instruction (D10, option E0: measure first, outside the repository; apply E2 only if the effect is confirmed). Source: astronomy-engine v2.1.19, `source/c/astronomy.c`, commit `61dc07020aaa6885d2c7f688a4d82beaf6edb9ef`, blob `713bc1aeee87a04f8512477b984c4f43f3fb30e7` (the file was checked against its upstream git blob id before use).

## Question

D10 noted that the library is inconsistent about the point `vsop[BODY_EARTH]`: most code treats it as the Earth's centre, but the gravity-simulation code passes `EARTH_GM + MOON_GM` for it (line 3912). If it were the Earth–Moon barycentre, the library's geocentric position of the Sun would be off by `−(Moon geocentric vector)/(1 + EARTH_MOON_MASS_RATIO)` projected on the Sun's direction of longitude: a signal of up to about 6.4/d arcseconds (6.8 arcseconds at the Sun's distance on the dates used) that follows the Moon's position relative to the Sun with a period of one synodic month (29.5 days), not 27.3 days as D10 said (27.3 days is the sidereal month; the Sun sees the Moon's elongation). The same offset would shift the library's speed of the other bodies (D10).

## Method (no repository change; the program and data are in the session scratch directory and are not kept)

- Reference: JPL Horizons OBSERVER query for the Sun, centre `500@399`, quantity 31 (apparent ecliptic longitude), `ANG_FORMAT=DEG`, `EXTRA_PREC=YES`, UT, from 2026-01-01 00:00 to 2026-03-02 00:00 every 6 hours: **241 samples**, saved as untrusted data.
- Library value: the plan's own formulation, `Astronomy_GeoVector(BODY_SUN, t, ABERRATION)` rotated to ECT with `Astronomy_Rotation_EQJ_ECT` and `Astronomy_RotateVector`, longitude `atan2(y, x)`; also `Astronomy_SunPosition` for comparison. Compiled on the host (TDM-GCC 5.1.0) with the unmodified `astronomy.c`.
- Prediction of the barycentre signal: `pred = −((Moon geocentric vector in ECT) · ê_λ) / ((1 + EARTH_MOON_MASS_RATIO) · |Sun vector|)` in arcseconds, with the Moon from `Astronomy_GeoMoon` (a measurement tool, not product code), and `EARTH_MOON_MASS_RATIO` from the library (81.30056).
- Fit: `(library − Horizons) = a·pred + b + c·Δt` by least squares. `a = 1` means the hypothesis is true; `a = 0` means the point is the Earth's centre.

## Result

| Quantity | GeoVector + rotation (the plan's formulation) | `Astronomy_SunPosition` |
|---|---|---|
| (library − Horizons), min / max (arcsec) | 0.371 / 1.300 | 0.016 / 1.050 |
| mean, rms (arcsec) | 0.834, 0.860 | 0.535, 0.586 |
| predicted barycentre signal, max \|pred\| (arcsec) | 6.827 | 6.827 |
| fit coefficient `a` | **0.015** | **0.014** |
| rms after the fit (arcsec) | 0.163 | 0.160 |

If the VSOP point were the barycentre, the residual would swing by about ±6.8 arcseconds with the Moon's phase and `a` would be near 1. The residual stays inside 0.4 to 1.3 arcseconds and does not follow the predicted pattern (`a` ≈ 0.015). **The hypothesis is not confirmed: in the Sun's position the library behaves as if the point were the Earth's centre.**

## Conclusion and consequence for the plan

- D10's E2 condition ("if the 27.3-day Earth–Moon barycentre signal is confirmed") is **not met**. **E1, the approved formulation, stands.** E2 is not applied, the D7 thresholds are unchanged, and no formula changed.
- The plan's own statement that the signal period is 27.3 days is corrected here: for the Sun the signal would have a synodic period.

## Limits (stated)

- One body (the Sun), one 60-day window (January to March 2026), 241 samples. The position of the Sun is the cleanest test of the Earth point's position, because the Sun's apparent longitude is dominated by the observer's position; it is not a measurement of the library's velocity.
- A position that is consistent with the Earth's centre says the VSOP series' own Earth point is the centre in the library's position pipeline; the velocity comes from the derivative of the same series (`VsopDeriv`), so it refers to the same point. This is an inference, not a velocity measurement. The D7 speed comparison against Swiss Ephemeris (Task 6) will show any residual effect; if the Sun, Venus, Mars or Mercury exceed their approved bounds with a monthly oscillation, the plan stops and reports (Global Constraints), and nothing is adjusted.
