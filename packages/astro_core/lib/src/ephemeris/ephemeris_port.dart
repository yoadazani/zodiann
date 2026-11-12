import 'body.dart';
import 'ecliptic_position.dart';
import 'ephemeris_result.dart';
import 'utc_range.dart';

/// The single contract every position source implements (ARCH-4): Swiss
/// Ephemeris with data files, its built-in Moshier mode, and astronomy-engine.
/// Swapping a source, or falling back to the backup, is one injection of a
/// different implementation, without touching the rest of the code.
///
/// ## Coordinate system
///
/// **Physical bodies** ([Body.sun] … [Body.pluto]) — spec "Planet position",
/// "Computation settings that must be fixed and documented" and NFR-A1:
///
/// * **Geocentric** viewpoint (from the center of the Earth).
/// * **Apparent** position: corrected for light time, aberration, light
///   deflection and nutation.
/// * Longitude on the **true ecliptic and equinox of date** (the tropical
///   zodiac).
/// * Implementations **must not apply any extra precession correction** on top
///   of what the library already does. Such a mistake shifts every position by
///   a few tenths of a degree; a mandatory regression test (NFR-A1,
///   ZOD-TST-004) catches it.
///
/// **Exception — [Body.node]** is not a physical body. It is the formula-based
/// **mean ascending lunar node** described at [meanAscendingNode]. The
/// apparent-position requirements above (light time, aberration, deflection,
/// nutation) do **not** apply to it, and it must not be computed or
/// "corrected" as if it were an apparent physical position.
///
/// ## Calling
///
/// All methods are synchronous: implementations wrap synchronous native
/// calls, and the degree-crossing solver calls them many thousands of times.
/// Callers run long scans (e.g. a crossing table) in a separate isolate
/// (ARCH-1). Every `DateTime` argument must be UTC; local time is converted to
/// UTC by the caller before calling.
abstract interface class EphemerisPort {
  /// The inclusive UTC range in which this source guarantees its stated
  /// accuracy for the physical bodies. The app's UI uses it to limit date
  /// input (R-2). Outside it, [position] returns [OutOfCoveredRange].
  UtcRange get coveredRange;

  /// The position of [body] at the UTC moment [utc].
  ///
  /// Throws [ArgumentError] if [utc] is not UTC (`utc.isUtc` is false).
  ///
  /// For a **physical body**:
  ///
  /// * Returns [EphemerisSuccess] with the tropical ecliptic longitude in
  ///   degrees in `[0, 360)` and the longitude speed in degrees per day. The
  ///   speed must come **directly from the ephemeris source, never from
  ///   finite-differencing two positions** (CRS-A1). Consumers derive
  ///   retrograde as `speed < 0` (ZOD-EPH-005).
  /// * If [utc] is outside [coveredRange], returns [OutOfCoveredRange] and
  ///   **never** an approximate position (R-2).
  ///
  /// For **[Body.node]**: returns `EphemerisSuccess(meanAscendingNode(utc))`
  /// for any [utc]. The node is formula-based, so it is not bounded by
  /// [coveredRange], and its retrograde state is the constant "mean ℞"
  /// rather than derived from the speed sign (ZOD-EPH-001 / ZOD-EPH-005).
  EphemerisResult position(Body body, DateTime utc);

  /// The mean ascending lunar node at the UTC moment [utc].
  ///
  /// Throws [ArgumentError] if [utc] is not UTC.
  ///
  /// Formula contract (spec "Planet position"):
  ///
  /// * `Ω = 125.04452 − 1934.136261·T` degrees, where
  ///   `T = (JD − 2451545.0) / 36525` is the number of Julian centuries
  ///   since 2000-01-01 12:00 UTC, and `JD` is the Julian Day of the UTC
  ///   instant [utc] itself. Do **not** convert to terrestrial time (no ΔT);
  ///   the spec defines `T` from UTC.
  /// * The longitude is normalized to `[0, 360)`. Use `normalizeDegrees`
  ///   (this package) rather than a bare `x % 360`: in Dart, `x % 360` returns
  ///   exactly `360.0` for tiny negative `x` (e.g. `-1e-15 % 360`), which
  ///   [EclipticPosition] rejects with an [ArgumentError]. The same applies to
  ///   adapters normalizing physical-body longitudes.
  /// * The speed is the constant `−1934.136261 / 36525` degrees per day.
  /// * This is a linear approximation. The spec states an expected deviation
  ///   of less than 0.01° from the full formula over two hundred years
  ///   around 2000; this bound is pending independent verification by T-EPH-2
  ///   (ZOD-TST-002).
  ///
  /// This is a formula-based point, not an apparent physical position (see
  /// the class documentation).
  ///
  /// The formula is implemented once, by ZOD-EPH-001, as
  /// `meanAscendingNodeAt` and the `MeanAscendingNodeFormula` mixin in this
  /// package; implementations should mix in `MeanAscendingNodeFormula`
  /// rather than re-implement it. Independent verification of the formula and
  /// its accuracy bound: T-EPH-2 (ZOD-TST-002), pending.
  EclipticPosition meanAscendingNode(DateTime utc);
}
