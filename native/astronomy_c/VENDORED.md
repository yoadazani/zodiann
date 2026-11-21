# Vendored astronomy-engine (C)

Added by ZOD-EPH-004 (2026-11-21). Everything under `upstream/` is a **byte-for-byte copy** of the upstream files. Nothing in them was edited, reformatted or re-line-ended. `test/architecture/astronomy_vendored_test.dart` checks every file against `MANIFEST.json` on each test run.

## Origin

| | |
|---|---|
| Repository | https://github.com/cosinekitty/astronomy (Don Cross) |
| Release / tag | `v2.1.19`, "Latest" release, published 2023-12-14 (the repository's `master` has moved on; the tag is vendored, not `master`) |
| Tag object | `03084ee684bdcc490273fe85f9df4f1c8fb66199` (annotated) |
| Commit | `61dc07020aaa6885d2c7f688a4d82beaf6edb9ef` |
| Retrieved | 2026-11-21, by git blob id (`gh api repos/cosinekitty/astronomy/git/blobs/<sha>`), then compared with the blob id recomputed from the bytes |
| Licence | MIT, "Copyright (c) 2019-2023 Don Cross". The MIT text is vendored as `upstream/LICENSE` and must stay with the source |

## What is vendored

`upstream/astronomy.c` (blob `713bc1aeee87a04f8512477b984c4f43f3fb30e7`), `upstream/astronomy.h` (blob `3013632ea25e1d773a49e2ebd3584a705a34b684`) and `upstream/LICENSE` (blob `9dd5faf8b0dad1d25ce768b8c0792c8185b0e7ae`). The library needs no data files and no other source file.

**Not vendored (not modified, simply not copied):** `README.md` (the 225 KB documentation), `Doxyfile`, `DoxygenLayout.xml`, `.gitignore`, the two language SVG logos.

`.gitattributes` marks `native/astronomy_c/upstream/**` as `-text`, so a Windows checkout with `core.autocrlf=true` cannot change the bytes.

## Source reading recorded for ZOD-EPH-004 (Task 1, Step 1)

All line numbers are in the vendored `astronomy.c`.

1. `Astronomy_BaryState` (line 5536) accepts `BODY_SUN`, `BODY_EARTH`, `BODY_MERCURY` … `BODY_NEPTUNE` and `BODY_PLUTO`. The Sun and the planets get **analytic** velocities from `CalcVsopPosVel` (line 3644, the derivative of the VSOP87 series, `VsopDeriv`); Jupiter to Neptune are adjusted through `AdjustBarycenterPosVel` (line 3772), also analytic; Pluto comes from `CalcPluto` (line 4643), which extrapolates stored gravity-simulation states with Newtonian mechanics.
2. Present and as the plan needs them: `Astronomy_TimeFromDays` (941), `Astronomy_GeoVector` (5489), `Astronomy_BaryState` (5536), `Astronomy_SunPosition` (6595), `Astronomy_Ecliptic` (6640), `Astronomy_RotateVector` (10080), `Astronomy_Rotation_EQJ_ECT` (10228, **takes an `astro_time_t *`**), `Astronomy_EclipticGeoMoon` (2378), `Astronomy_GeoMoon` (2323). `Astronomy_GeoMoonState` (2433) is **read only and never called** (see item 5).
3. Frames: `Astronomy_SunPosition` returns the Sun's apparent position in the **true ecliptic of date (ECT)**, with light time applied by evaluating the Earth at `time − 1/C_AUDAY` (no separate aberration step); `Astronomy_Ecliptic` converts EQJ to **ECT** (precession, then nutation, then the true obliquity); `Astronomy_EclipticGeoMoon` returns the Moon in **ECT**, geometric (no light time, no aberration).
4. `Astronomy_GeoVector(BODY_SUN, t, ABERRATION)` falls to the default branch: `Astronomy_BackdatePosition(time, BODY_EARTH, BODY_SUN, aberration)`, the light-time-backdated, aberrated vector, returned in EQJ with `vec.t` set to the observation time. The Moon is returned as the geometric `Astronomy_GeoMoon` ("aberration and light travel time don't matter").
5. **`Astronomy_GeoMoonState` derives the Moon's velocity as a central difference of `Astronomy_GeoMoon`, `dt = 1.0e-5` days (0.864 s)**; its own comment calls it "a hack". `Astronomy_GeoEmbState` and `Astronomy_BaryState` / `Astronomy_HelioState` for `BODY_MOON` and `BODY_EMB` call it. Nothing on the Sun or planet path reaches it. The owner's decision (2026-11-21, Option 2) is that the Moon's velocity is our own analytic derivative of `CalcMoon`: `docs/spikes/ZOD-EPH-004-moon-derivative.md`.
6. `vsop[BODY_EARTH]`: the gravity-simulation code passes `EARTH_GM + MOON_GM` for it (line 3912), while `HelioVector` (5099), `BaryState` and `GeoVector` use it as the Earth's centre. A host measurement (E0, 2026-11-21) found the Sun's longitude from this point within 0.4 to 1.3 arcseconds of JPL Horizons with no Earth–Moon-barycentre signal: `docs/spikes/ZOD-EPH-004-earth-point-measurement.md`.

## How "unchanged" was proved

1. The upstream tree at the commit above was read with `gh api repos/cosinekitty/astronomy/git/trees/<sha>` (the `source/c` subtree); each file was fetched by blob id.
2. The blob id recomputed from the downloaded bytes equalled the upstream blob id for all three files (2026-11-21).
3. After `git add`, `git rev-parse :<path>` equals the upstream blob id for all three files (Task 1, Step 4).
4. `test/architecture/astronomy_vendored_test.dart` recomputes each file's git blob id and SHA-256 from the bytes on disk and compares them with `MANIFEST.json`.
5. A Windows-style checkout (`git clone -c core.autocrlf=true`) was tested after the commit (Task 1, Step 4).
