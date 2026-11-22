# ZOD-EPH-004: the retarded-instant velocity refinement (D1, variant V2)

Owner approval, 2026-11-22: "Approved V2 for Mercury, apply to all bodies."
This changes the formulation of D1 for the **Sun and the planets**; the Moon's
velocity (our analytic derivative of the lunar series) is untouched. No finite
difference is introduced: the velocities are the library's analytic
`Astronomy_BaryState` values, and the retarded time is built through the
shim's single conversion helper.

## Why

The first Task 6 diagnostic (adapter against Swiss Ephemeris at the same TT)
found Mercury's longitude speed up to 0.001590 degrees per day from Swiss's,
against the approved bound of 0.0012. D1 had named the cause: the position `r`
is the apparent (light-time-retarded) position while `v` was the body's
instantaneous velocity at `t`.

## The formula

For the Sun and every planet, at the UT instant `t`:

* the geometric retarded vector is `Astronomy_GeoVector(body, t, NO_ABERRATION)`,
  its light time is `tau = |g| / c` (`C_AUDAY` AU per day);
* the retarded time is `t - tau`, built as `zodiann_time_from_ut(ut_days - tau)`
  (not `Astronomy_AddDays`, which the guards ban);
* `v_body` is `Astronomy_BaryState(body, t - tau)` and `v_earth` is
  `Astronomy_BaryState(BODY_EARTH, t)`;
* `dtau/dt = rhat . (v_body - v_earth) / (c + rhat . v_body)`, with `rhat = g / |g|`;
* the geocentric velocity is `v_body (1 - dtau/dt) - v_earth`, the exact
  derivative of the retarded geometric position `x_body(t - tau) - x_earth(t)`;
* it is rotated to the true ecliptic of date with the same frame as before and
  the longitude speed is `(x vy - y vx) / (x^2 + y^2)` in Dart, as before.

Still omitted (and still stated in the adapter's docs): the derivative of the
aberration correction (about 9.8e-5 degrees per day), the rotation rate of the
ecliptic-of-date frame (about 3.8e-5), and, for the Moon, the terms of D1.

## Estimate before applying (scratch, host, 2026-11-22)

`estimate.c` (spike tooling, built with the vendored astronomy-engine and
Swiss Ephemeris and its data files) evaluated four variants against Swiss at
the same TT on the Task 6 formal sample set and on a daily scan, 1900 to 2099.
It reproduced the device's failing Mercury maximum exactly (0.001590 at
1949-10-17T19:44:35Z).

| Mercury | Max difference (deg/day) | Samples over 0.0012 (8,873) |
|---|---|---|
| V0, before | 0.001590 | 251 |
| V1, `v_body(t - tau) - v_earth(t)` | 0.000703 | 0 |
| **V2, the exact retarded derivative (applied)** | **0.000784** | **0** |
| V3, Earth also at `t - tau` | 0.000692 | 0 |

V2 was chosen because it is the exact derivative of the retarded geometric
position and does better than V1 on Mars (0.000194 against 0.000212); the
difference between V1, V2 and V3 is within the noise of the omitted terms.
Venus 0.000305 to 0.000267; the Sun, Jupiter, Saturn, Neptune and Pluto were
unchanged within 1e-5; Uranus stayed at 0.000460, a one-day dip in Swiss's own
speed, not a light-time effect.

## Verification in the repository

* `apps/astro_mobile/integration_test/astronomy_retarded_velocity_test.dart`:
  eight cases (Mercury three times, Venus, Mars, the Sun, Jupiter, Pluto) whose
  expected values come from `print_values.c`, an implementation written
  separately from the shim (same vendored library), to 1e-10 degrees per day;
  the Mercury cases also exclude the earlier value by more than 1e-4. They
  failed (RED) on the earlier shim and pass with the refinement.
* The ACC-2 gate (positions) is unchanged to the printed precision, and the
  Moon derivative suite passes (the Moon branch is untouched).
* The host structural guard now expects five calls of `zodiann_time_from_ut`
  (the retarded time adds one) and still bans `Astronomy_AddDays`,
  `Astronomy_TimeFromTt`, `Astronomy_MakeTime`, `Astronomy_CurrentTime` and any
  `.tt` or `.ut` write.
* The Task 6 speed comparison against Swiss is rerun with the refinement; its
  result is in `docs/PROGRESS.md` and the findings.

`estimate.c` and `print_values.c` are spike tooling, not part of any build:
`gcc -O1 -std=gnu99 -I<astronomy_c/upstream> -I<swisseph/upstream> estimate.c
<astronomy.c> <the nine Swiss sources> -lm`, run with `mercury|venus|...`, the
ephemeris directory and a file of UT days; `print_values.c` takes the ephemeris
directory and pairs of body name and integer microseconds since J2000.
