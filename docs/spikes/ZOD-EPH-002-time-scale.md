# ZOD-EPH-002: time scales, ΔT and updatable Earth-rotation data

**Status: investigation and proposal (2026-11-25). Nothing here is approved or implemented.** The owner asked for an architecture and implementation proposal before any code or dependency change. No code, dependency, specification or task file was changed.

## 1. Answer first

1. **Position accuracy does not depend on new Earth-rotation measurements** for what the MVP computes (geocentric longitudes from a civil-time input). Input is UTC, the ephemeris needs TT, and `TT − UTC = 32.184 s + (TAI − UTC)`. That is the leap-second count, not ΔT and not UT1.
2. **Measured:** computing TT that way and calling `swe_calc` puts all ten bodies within **0.56″** of JPL Horizons at all 53 reference instants. The current plan (`swe_calc_ut`, which treats UTC as UT1 and adds the library's ΔT model) is up to **13.9″** off for the Moon after 2026.
3. **The leap-second table is about to stop changing.** CGPM Resolution 5 (2026) makes UTC continuous from 20 May 2027 (maximum |UT1 − UTC| of 3,600 s).
4. **Updated UT1 − UTC data would matter only** for quantities that depend on the Earth's rotation angle: sidereal time, topocentric positions (a specification option, off by default), the Ascendant and houses (optional, ZOD-EXT-005). None is in this task.
5. **An automatic download conflicts with the specification** (line 70, DATA-7, DATA-8, NFR-R3) and with `test/architecture/no_network_test.dart`. Only the owner can change that.

**Recommendation:** use leap-second TT for positions now (no network, no new dependency); ship the data-driven classification you asked for; defer the updater to its own task, to be started when a feature actually consumes UT1.

## 2. Measurement

Host build (gcc 5.1.0, Windows x86_64) of the vendored Swiss Ephemeris 2.10.03 with the packaged `.se1` files, flags `SEFLG_SWIEPH | SEFLG_SPEED`, against the Horizons UT values already in `packages/ephemeris_astronomy/test/fixtures/reference_longitudes.json` (53 instants, 1899-12-31 to 2100-01-01, ten bodies, 530 rows; every call used the data files). Before 1972 both columns use `swe_calc_ut`. The 27 leap-second steps used were compared with IERS `Leap_Second.dat` (downloaded 2026-11-25, updated through Bulletin C 72): identical.

Maximum absolute difference in arcseconds, as `current → leap-second TT`:

| Body | Before 1972 (19 instants) | 1972 to 2026 (16) | After 2026 (18) |
|---|---|---|---|
| Sun | 0.242 | 0.070 → 0.049 | 0.840 → 0.179 |
| Moon | 0.455 | 0.393 → 0.053 | **13.856 → 0.180** |
| Mercury | 0.243 | 0.078 → 0.049 | 1.445 → 0.179 |
| Venus | 0.242 | 0.075 → 0.050 | 1.024 → 0.179 |
| Mars | 0.242 | 0.063 → 0.051 | 0.475 → 0.179 |
| Jupiter | 0.228 | 0.089 → 0.090 | 0.229 → 0.138 |
| Saturn | 0.252 | 0.097 → 0.097 | 0.251 → 0.203 |
| Uranus | 0.560 | 0.080 → 0.079 | 0.463 → 0.468 |
| Neptune | 0.198 | 0.056 → 0.056 | 0.091 → 0.079 |
| Pluto | 0.246 | 0.125 → 0.126 | 0.154 → 0.148 |

**What this does not show:** an Android or iOS device run; instants other than these 53; speeds. **After 2026 it is partly circular:** Horizons also holds TT − UTC constant (about 69.18 s, see `ZOD-EPH-004-delta-t.md` section 2). The agreement shows the two use the same convention; what makes the convention right is the UTC standard (section 3), which a future international decision could change.

## 3. Time scales

```
TT  = TAI + 32.184 s                      (definition)
UTC = TAI − (TAI − UTC)                   (leap seconds; 37 s since 2017-01-01)
UT1 = UTC + (UT1 − UTC)                   (measured Earth rotation)
ΔT  = TT − UT1 = 32.184 + (TAI − UTC) − (UT1 − UTC)
```

* ΔT and UT1 − UTC are **not** interchangeable. Example from IERS Bulletin A of 19 November 2026: UT1 − UTC = −0.074804 s, so ΔT = 32.184 + 37 + 0.074804 = **69.259 s**.
* For a UTC input, UT1 cancels: `UT1 + ΔT = UTC + 32.184 + (TAI − UTC)`. Using a modelled ΔT on a UTC instant treats UTC as UT1 and adds the model's error.
* Interpolate `UT1 − TAI` (continuous), never `UT1 − UTC`, which jumps by a second at a leap second.
* **From 1972:** TT from the leap-second table. **Before 1972:** civil time is taken as UT and the library's historical ΔT applies, as Swiss Ephemeris's own `swe_utc_to_jd` does. That ΔT is a reconstruction, not a forecast.
* Bulletin C 72 (6 July 2026) announced no leap second at the end of December 2026. IERS `Leap_Second.dat` expires 28 June 2027. I know of no announced step before 20 May 2027; a table update would cover one if it came.
* Do **not** use `swe_utc_to_jd`: when the library's ΔT minus (leap seconds + 32.184) reaches 1 s it treats the input as UT1 (`swedate.c:425-436`), which for later years brings the model back.

## 4. What the bundled library offers (vendored 2.10.03, read from source)

Its yearly ΔT table is observed through 2023 and "extrapolated" for 2024 to 2028 (`swephlib.c:2488-2494`, `TABEND 2028`).

| Way to feed new ΔT | Behaviour | Verdict |
|---|---|---|
| `swe_deltat.txt` / `sedeltat.txt` in the data directory (`init_dt`, `swephlib.c:3089`) | One value per year; read once per library initialisation; overwrites a static table in the process. The parser has **no lower bound on the table index**: a line whose year is below 1620, or that does not parse as a number (including a bare CR line), writes outside the array | Not recommended. Never write downloaded text into it |
| `swe_set_delta_t_userdef` | One fixed ΔT for every instant, global state | Only usable if set and reset around each locked call |
| Compute TT in our code, call `swe_calc` (already bound) | No library state, any time resolution, no file | **Recommended** |

A newer upstream release is listed (2.10.04, tagged 24 November 2026). Its table was not verified, and an upgrade is not needed for this proposal.

## 5. Proposed architecture

### 5.1 Stage 1, inside ZOD-EPH-002 (needs approval)

* `astro_core`, pure Dart: a **leap-second table** as data with provenance (source, bulletin, expiry), and `TT − UTC` for instants from 1972 (none before). A host test pins it to the published list.
* The adapter calls the locked native entry point with TT from 1972 and with UT before. Both stay behind `EphemerisPort`; no contract change.
* **Classification** (your points 1, 2, 6, 9), a pure function over a dataset description, with no year literal in code:

  | Dataset field | Bundled value | Result |
  |---|---|---|
  | `observedThrough` | end of 2023 | Observed |
  | `estimatedThrough` | end of 2028 | Estimated |
  | later | | Forecast (from 2029) |

  A guard test ties `estimatedThrough` to the vendored `TABEND`, so a library upgrade cannot leave it stale. Note: the table holds values for 1 January, so instants during 2023 already interpolate toward the first extrapolated point. Your rule (through 2023 observed) is kept.
* **Warning threshold: separate and not set.** The classification describes Earth-rotation data. With leap-second TT it says nothing about geocentric Moon accuracy.

### 5.2 Stage 2, a new task: updatable Earth-orientation data

Worth building when topocentric positions or the Ascendant are built. Rough estimate (not measured): one second of UT1 error moves the topocentric Moon by about 0.25″.

```
bundled snapshot ──┐
transport ─► strict Dart parser ─► validator ─► atomic local store ─► immutable dataset
(import or fetch)                                (keeps previous)      ├─ classification
                                                                       └─ UT1 consumers
```

* **Source:** IERS `finals.all` (IAU 2000), observed and predicted daily values: `https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt`. Bulletin A: `.../latestVersion/bulletinA.txt` (read: weekly, about 37 kB of text, one year of daily predictions, stated UT1 − UTC accuracy `0.00025 × days^0.75` s, about 0.02 s at one year). `https://maia.usno.navy.mil/ser7/ser7.dat` **could not be retrieved** (connection reset twice), nor could the format readme, so the column layout must be verified before a parser is written. The NASA CDDIS mirror redirects to a login. `finals.all` was not downloaded or sized.
* **Terms of use:** none found; the IERS legal pages returned 404. Bulletin A says "Approved for public release: distribution unlimited". Ask IERS before shipping automated downloads.
* **Replacement rules:** observed replaces estimated or forecast for the same day; predictions never overwrite observations; a newer issue may revise observations within a tolerance; an older issue is ignored.
* **Validation:** size cap; strict fixed-width parse; consecutive dates; |UT1 − UTC| at most 0.9 s before 20 May 2027 and 3,600 s after; day-to-day continuity of UT1 − TAI (threshold to be derived from the data); TAI − UTC consistent with the leap table; overlap with stored observations. Any failure keeps the current dataset. No signature from the source was seen, so integrity would rest on HTTPS.
* **Offline:** the bundled snapshot and the last validated dataset always work; updating never blocks startup or a calculation.
* **A consequence for your point 1:** IERS predicts only about one year ahead. After an update, data-driven classification would put "Forecast" about a year from the issue date (late 2027 today), **earlier** than 2029, and 2024 onward would become observed up to the issue date.

| Transport | Specification impact | Cost and risk |
|---|---|---|
| **A. None yet** (recommended now) | none | positions unaffected; classification changes only with app releases |
| **B. User imports a file** | a new import feature, fits the DATA-9 pattern; no permission | user effort; same parser and validator |
| **C. Automatic fetch** | needs DATA-7 and line 70 changed, DATA-8 and NFR-R3 reviewed, privacy text | `INTERNET` permission; guard changes; the server sees the user's IP address; availability and terms unknown (above); scheduling and opt-out |

## 6. Consequences if Stage 1 is approved

* **Specification:** the "Time" row says UTC is converted to TT "using the difference called delta T" and that future ΔT reduces Moon accuracy. Both would be recorded as a deviation in a decision record (as ZOD-FND-011 section 9 did); only the owner edits the specification.
* **ZOD-EPH-002:** the bullet asking for a ΔT-forecast warning flag becomes the classification above. **ZOD-NFR-017:** its criterion "a far-future date shows the ΔT-forecast banner" needs an owner decision (keep as information, reword or drop).
* **ZOD-TST-001 vs ΔT blocker:** resolved for Swiss Ephemeris on the evidence of section 2 (to be confirmed on a device).
* **Backup (astronomy-engine):** still uses its own ΔT (up to 78.6″ for the Moon at 2100). `Astronomy_SetDeltaTFunction` (global) can supply the same conversion. A change to completed ZOD-EPH-004 work and its fixtures, so a separate decision (`ZOD-EPH-004-delta-t.md` section 7).
* **Unchanged:** the mean node formula (defined on UTC by the specification), the Square of Nine.

## 7. Decisions already taken for ZOD-EPH-002 (owner, 2026-11-25)

* Calls are serialized with **one shared library state on every platform and a lock** in a small project-authored C file; vendored sources unchanged. Reason: `TLS` is `__thread` in the Android build and empty on Apple platforms (`sweodef.h:86-94`).
* The astronomy-engine backup is selected automatically **only if the Swiss library does not load**; missing files or unsupported dates never switch sources. This refines the ZOD-FND-011 record's "only ever an explicit user choice" (section 4) for the library-load case.

## 8. Sources

* [IERS Bulletin A (latest)](https://datacenter.iers.org/data/latestVersion/bulletinA.txt) · [IERS EOP products](https://datacenter.iers.org/eop.php) · [Bulletin C](https://hpiers.obspm.fr/iers/bul/bulc/bulletinc.dat) · [Leap_Second.dat](https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat)
* [CGPM 2026 Resolution 5](https://www.bipm.org/committees/cg/cgpm/28-2026/resolution-5) (the French text is official) · [CGPM 2022 Resolution 4](https://www.bipm.org/en/-/resolution-cgpm-27-4)
* [Swiss Ephemeris tags](https://github.com/aloistr/swisseph/tags) · [programmer documentation](https://www.astro.com/swisseph/swephprg.htm)

## Appendix: reproducing section 2

Scratch tooling, not added to the repository. Build with `gcc -O1 -std=gnu99 -I<upstream> check.c <upstream>/{swedate,swehouse,swejpl,swemmoon,swemplan,sweph,swephlib,swecl,swehel}.c -lm` and run `check <ephe dir> < rows.txt`. Each input row is `utc body jd_ut offset horizons_longitude`, where `offset` is `32.184 + (TAI − UTC)` seconds, or `-1` before 1972; `jd_ut = microsecondsSinceEpoch / 86400000000 + 2440587.5`; `body` is 0 (Sun) to 9 (Pluto).

```c
#include <stdio.h>
#include <string.h>
#include "swephexp.h"
int main(int argc, char** argv) {
    char serr[AS_MAXCH], utc[64]; double jd, off, ref, a[6], b[6]; int ipl;
    swe_set_ephe_path(argv[1]);
    while (scanf("%63s %d %lf %lf %lf", utc, &ipl, &jd, &off, &ref) == 5) {
        int f1 = swe_calc_ut(jd, ipl, SEFLG_SWIEPH | SEFLG_SPEED, a, serr);
        int bad = !(f1 & SEFLG_SWIEPH) || (f1 & SEFLG_MOSEPH);
        if (off >= 0) {
            int f2 = swe_calc(jd + off / 86400.0, ipl, SEFLG_SWIEPH | SEFLG_SPEED, b, serr);
            bad |= !(f2 & SEFLG_SWIEPH) || (f2 & SEFLG_MOSEPH);
        } else memcpy(b, a, sizeof a);
        double d1 = a[0] - ref, d2 = b[0] - ref;
        while (d1 > 180) d1 -= 360; while (d1 < -180) d1 += 360;
        while (d2 > 180) d2 -= 360; while (d2 < -180) d2 += 360;
        printf("%s %d %.4f %.4f %d\n", utc, ipl, d1 * 3600, d2 * 3600, bad);
    }
    swe_close();
    return 0;
}
```
