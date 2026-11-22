# ZOD-EPH-004 Task 6: Swiss Ephemeris's speed has glitches near the Sun; the reference configuration

2026-11-22. Spike notes for the Uranus failure of the D7 speed comparison. All
measurements are scratch runs (host build of the vendored astronomy-engine and
Swiss Ephemeris with its data files, at the same TT); the sources are beside
this file in `ZOD-EPH-004-swiss-speed-reference/`. Nothing here changes the
adapter, a threshold or a formula.

## The failure

After the retarded-instant refinement, the only failing approved criterion was
Uranus: 0.000460 degrees per day at 2075-01-01T00:00Z against 0.0003. Hourly,
Swiss's speed for Uranus dips by 1.2e-3 within a day (0.06006 at 2074-12-31
18:00, 0.05886 at 2075-01-01 04:00, 0.0600 by 2075-01-02) while the adapter is
a flat 0.059901. At 1946-06-09 Swiss's Uranus speed falls to 0.0379 for a few
hours against 0.0600 around it.

## An exclusion rule is not defensible

The owner chose option 1, an objective rule that excludes Swiss glitches. Two
candidate rules were measured and neither separates glitches cleanly:

* **Swiss data files against Swiss's built-in Moshier ephemeris at the same
  TT** (`files_vs_moshier.c`): they agree to 1e-5 degrees per day for every
  planet over 1900 to 2099 (Uranus maximum 8.6e-6), **including at 2075-01-01
  and 1946-06-09**. The dip is therefore in code both modes share, not in the
  data files, and this check cannot see it.
* **Swiss's speed against the median of its own speed one and two days either
  side** (`neighbour_median.c`): the statistic has a continuous tail with no
  gap. Uranus has 255 days above 1e-4, 131 above 2e-4, 76 above 3e-4, 21 above
  1e-3, up to 0.021; Neptune 116, 52, 37 and 10; Saturn 92, 27, 18 and 5;
  Jupiter 328, 57, 34 and 9. Any threshold would be an arbitrary choice inside
  a continuum, and for the inner planets legitimate curvature at stations
  swamps it.

## The cause, and a reference configuration without it

`flag_sets.c` evaluates the same instants with different Swiss flag sets. The
dips at both dates are **present in the default configuration and with
`SEFLG_NOABERR` and `SEFLG_NONUT`, and absent with `SEFLG_NOGDEFL`** (and with
`SEFLG_TRUEPOS`): Swiss's gravitational-deflection correction has a glitchy
speed near solar conjunction (Uranus 2075-01-01 with `NOGDEFL`: a flat 0.05997
across the whole window). Astronomy Engine's `GeoVector` applies light time and
aberration and **no light deflection**, so Swiss without deflection is the
like-for-like reference for what the adapter models. `moon_nogdefl.c`: Swiss
applies no deflection to the Moon, the speed is bit-identical with and without
the flag.

## The same comparison with `SEFLG_SWIEPH | SEFLG_SPEED | SEFLG_NOGDEFL`

The formal sample set (53 reference instants, plus every station at 0, ±1, ±5
and ±20 days, and the Sun's 20 instants) and a daily scan of 73,049 days from
1900 to 2099, the adapter with the V2 refinement (`estimate.c`, built with
`-DEXTRA_FLAGS=SEFLG_NOGDEFL`):

| Body | Bound | Formal-set max | Daily-scan max | Daily days over the bound |
|---|---|---|---|---|
| Sun | 0.0003 | 0.000121 | 0.000149 | 0 |
| Mercury | 0.0012 | 0.000784 | 0.000783 | 0 |
| Venus | 0.00045 | 0.000267 | 0.000309 | 0 |
| Mars | 0.0003 | 0.000194 | 0.000234 | 0 |
| Jupiter | 0.0003 | 0.000192 | 0.000212 | 0 |
| Saturn | 0.0003 | 0.000197 | 0.000208 | 0 |
| **Uranus** | 0.0003 | **0.000206** | 0.000209 | 0 |
| Neptune | 0.0003 | 0.000199 | 0.000206 | 0 |
| Pluto | 0.0003 | 0.000206 | 0.000211 | 0 |

With the default Swiss configuration the same daily scan had 82 days over the
bound for Uranus alone (and 2,014 for Mercury before the refinement). With
the deflection-free reference **no sample in 73,049 days exceeds any approved
bound, with no exclusion of any sample.** The Moon is unchanged (its frozen
bound 0.0007 stands; its maximum 0.000573).

## Status

Proposed to the owner as the way to settle Uranus instead of an exclusion rule;
not applied to the test until the owner approves it. It changes the Swiss
reference configuration named in D7 (`SEFLG_SWIEPH | SEFLG_SPEED`) by one flag,
for all planets, and changes no threshold, formula or sample.
