# ZOD-EPH-002: the Swiss Ephemeris adapter (data-file mode), design

**Status: written 2026-11-25, awaiting the owner's approval.** Next: implementation plan, plan review, approval, then code.

Sources of truth: the [task file](../../development/computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md), the [time-conversion decision](../../decisions/ZOD-EPH-002-time-scale.md), the [ZOD-FND-011 record](../../decisions/ZOD-FND-011-ephemeris-data-file-coverage-range.md) (sections 4, 7a, 11) and the [FFI spike](../../spikes/ZOD-FND-003-swiss-ephemeris-ffi.md).

## 1. Intent

Give the app its primary position source: accurate, never silently approximate, and safe to call from the crossing solver's background isolate.

**Goals:** the ten physical bodies through `EphemerisPort` with speed from the library; the approved time conversion; serialized native calls; data files installed on the device; production wiring with the automatic backup; Android verification.

**Non-goals:** built-in Moshier mode (EPH-003); the backup's time conversion (EPH-006); updatable data (EPH-007); banners and settings screens (NFR-017, SET-006); the crossing solver; iOS verification (IOS-001); any network access; any `EphemerisPort` contract change.

**Failure even if it "works":** a Moshier or otherwise approximate longitude returned as success; a valid date failing on a background isolate; a production binding without the supported-range wrapper.

## 2. Constraints

* Vendored `native/swisseph/upstream` stays byte-identical (guarded).
* Settings: geocentric, apparent, true ecliptic of date; flags `SEFLG_SWIEPH | SEFLG_SPEED` only, so no extra precession, sidereal or J2000 flag.
* Host tests never load native code (the hook builds Android only).
* Architecture guards: the binding is `ephemerisPortProvider.overrideWithValue(SupportedRangeEphemeris(<adapter>(...)))` with the adapter created inside; the adapter file joins `nodeBypassAllowlist` with a justification.

## 3. Approaches (chosen by the owner)

| Question | Chosen | Considered, and why not |
|---|---|---|
| Serialization | One shared library state (`TLSOFF`) and a lock in project C code. Same behaviour on every platform; costs native code and brief waiting | Per-thread state plus lock: two behaviours, iOS untestable. Dart retry: leaves shared iOS state unprotected |
| Time | Leap seconds from 1972, historical ΔT before, labelled assumption after the table | `swe_calc_ut` everywhere: reads UTC as UT1, so a ΔT forecast moves future positions |
| Backup | Automatic only if the Swiss library does not load | Never automatic: no positions until a settings screen exists |
| Earth-rotation updates | Separate deferred task | In this task: needs no-network rules changed, changes no position |

## 4. Design

### 4.1 Time scale (`astro_core`, pure Dart)

* `LeapSecondTable`: the 27 steps plus the 1972 base, with source, bulletin and validity end (2027-06-28T00:00:00Z).
* A pure function of a UTC instant returning a sealed result: **Universal Time** (before 1972) or **Terrestrial Time** with the offset in seconds and the basis `publishedLeapSeconds` or `assumedContinuousUtc`. Non-UTC input throws `ArgumentError`.
* A separate pure function for the **ΔT data status** (observed / estimated / forecast) over a dataset description (bundled: observed through the end of 2023, estimated through the end of 2028). A guard ties the estimated end to the vendored `TABEND`.
* Both are callable by any consumer, so no port or result type changes.

### 4.2 Native layer (`ephemeris_swiss`)

* A project-authored C file beside (not inside) `upstream/`: one mutex around set-path, close, `swe_calc` and `swe_calc_ut`. The hook compiles it with the library and defines `TLSOFF`.
* `SwissEphemerisBinding` keeps its public methods and calls through the locked functions, so existing device tests are unchanged. A guard forbids any other Dart code from using the unlocked symbols.
* The data path is set once at startup; with shared state it applies to every isolate.

### 4.3 Adapter

* A pure-Dart `EphemerisPort` over a small injected calculation interface (host-testable with a fake); the native implementation is exported only from the native library entry point.
* `position`: node from `MeanAscendingNodeFormula`; non-UTC throws; outside `coveredRange`, `OutOfCoveredRange`; otherwise convert time, one library call, check `usedSwissEphemerisFiles`, normalize the longitude, take the speed from the same call.
* Moshier fallback, a missing file, a warning **or a negative library return** gives `OutOfCoveredRange` (data unavailable). *My call:* a damaged file must not crash the app.
* `coveredRange` comes from edges **measured on the device**, taken inward so every body succeeds throughout.
* *My call:* speed is reported as the library gives it (degrees per TT day); the difference from per-UTC-day exists only inside a leap second or the 1972 step.

### 4.4 Data files and startup (`astro_mobile`)

* An installer copies the two packaged files to the application support directory when a file is missing or its bytes differ (*my call:* stronger than the spike's size-only rule, so a same-size newer file is recopied), through a temporary file and rename. `path_provider` becomes a runtime dependency; the licensing inventory is updated.
* A failed copy does not stop startup: the Swiss source stays bound and reports data unavailable.
* The test seam in `bootstrapOverrides` injects the **calculation sources and the load-probe results, never a ready port**, so host tests of `main()` never touch native code and the architecture guards still hold: the binding is **one expression**, `ephemerisPortProvider.overrideWithValue(SupportedRangeEphemeris(<condition> ? <Swiss adapter>(...) : AstronomyEphemeris(...)))`, with both adapters created inside the wrapper.
* **Source selection**, once at startup: if a probe shows the Swiss library cannot load, the astronomy-engine adapter is chosen. The active source is exposed by a provider. *My call:* if neither library loads, the Swiss adapter is bound over a calculation source that always reports unavailable, so every physical-body request returns `OutOfCoveredRange` instead of crashing. No third port class, so no new guard exemption.
* **The time basis belongs to the primary source.** The §4.1 function describes the Swiss adapter's conversion. While the backup is active it does not apply; the app-level value combines it with the active source and reports "backup's own ΔT" instead (*my call*).

## 5. Verification

| Check | Where |
|---|---|
| Time scale at every table step, 1972, validity end, one microsecond either side; status boundaries; table equals the published list | host |
| Adapter: mapping of all bodies, flags, fallback and error cases, node, range, non-UTC | host, fake source |
| Wiring: wrapper, fallback selection, installer, startup with failures | host, plus the architecture guards |
| T-EPH-1: Sun and Moon within 1″ of Horizons by UTC input on 10+ dates (the existing 53 UT instants, all bodies recorded) | device |
| Ephemeris accuracy at matched TT; no extra precession | device |
| Range edges for all bodies; measured file edges; negative control | device |
| Concurrent calls from several isolates equal sequential results, including an isolate that never set the path | device |
| Release APK contains `libswisseph` for all three ABIs; size recorded | build |

## 6. Known limits and hand-offs

* **Until EPH-006, the fallback changes time handling:** the backup uses its own ΔT (Moon up to 78.6″ at 2100).
* The backup library keeps unsynchronised state; this task does not serialize it. A consumer running it on two isolates at once could get a wrong Pluto. Recommended addition to EPH-006 or the crossing tasks.
* TT as a function of UTC has steps (decision record section 4): hand-off to CRS-001/002.
* Swiss speed has small glitches near solar conjunction ([note](../../spikes/ZOD-EPH-004-swiss-speed-reference.md)): hand-off to CRS-001 and EPH-005.
* iOS is unverified (accepted risk, IOS-001).

## 7. Left to the builder

Names and file layout; the calculation interface's shape; the C function signatures; how the probe is made; how device fixtures are shared.
