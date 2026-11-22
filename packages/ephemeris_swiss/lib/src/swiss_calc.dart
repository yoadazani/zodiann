/// Pure-Dart pieces of the Swiss Ephemeris binding: the Julian day, the body
/// and flag constants, and the result type. Nothing here imports `dart:ffi`,
/// so host tests never touch the native library.
library;

/// `SE_SUN` in `swephexp.h`.
const int seSun = 0;

/// `SE_MOON` in `swephexp.h`.
const int seMoon = 1;

/// `SEFLG_SWIEPH`: use the Swiss Ephemeris data files.
const int seflgSwieph = 2;

/// `SEFLG_MOSEPH`: the built-in Moshier ephemeris. `swe_calc_ut` falls back
/// to it, with a warning, when a data file cannot be read.
const int seflgMoseph = 4;

/// `SEFLG_SPEED`: also return the speed.
const int seflgSpeed = 256;

/// `SEFLG_NOGDEFL`: turn off the gravitational deflection of light. Swiss
/// Ephemeris's speed correction for the deflection glitches near solar
/// conjunction (ZOD-EPH-004, docs/spikes/ZOD-EPH-004-swiss-speed-reference.md),
/// and Astronomy Engine applies no deflection, so the speed comparison uses it.
const int seflgNogdefl = 512;

/// The Julian day number of the UTC instant [utc] (the `tjd_ut` argument of
/// `swe_calc_ut`), on the proleptic Gregorian calendar.
///
/// Throws [ArgumentError] if [utc] is not UTC.
double julianDayUt(DateTime utc) {
  if (!utc.isUtc) {
    throw ArgumentError.value(utc, 'utc', 'must be a UTC DateTime');
  }
  const unixEpochJulianDay = 2440587.5;
  const microsecondsPerDay = 86400000000;
  return utc.microsecondsSinceEpoch / microsecondsPerDay + unixEpochJulianDay;
}

/// The Julian day number in TT (the `tjd_et` argument of `swe_calc`) of
/// [ttDaysSinceJ2000], days of TT since J2000 (2000-01-01T12:00 TT), the value
/// the Astronomy Engine test hook reports (ZOD-EPH-004 D12-O1). It is a pure
/// shift by the Julian day of J2000, 2451545.0.
///
/// Throws [ArgumentError] if [ttDaysSinceJ2000] is not finite.
double julianDayTt(double ttDaysSinceJ2000) {
  if (!ttDaysSinceJ2000.isFinite) {
    throw ArgumentError.value(
      ttDaysSinceJ2000,
      'ttDaysSinceJ2000',
      'must be finite',
    );
  }
  return ttDaysSinceJ2000 + 2451545.0;
}

/// One `swe_calc_ut` result.
final class SwissCalcResult {
  const SwissCalcResult({
    required this.longitude,
    required this.speed,
    required this.returnFlags,
    required this.error,
  });

  /// Ecliptic longitude in degrees (`xx[0]`).
  final double longitude;

  /// Longitude speed in degrees per day (`xx[3]`).
  final double speed;

  /// The flag word `swe_calc_ut` returned.
  final int returnFlags;

  /// The library's `serr` text; empty when there was no warning.
  final String error;

  /// True only when the calculation really used the Swiss Ephemeris data
  /// files: the Swiss Ephemeris flag is set, the Moshier flag is not, and the
  /// library gave no warning. A longitude alone does not show this, because
  /// the Moshier fallback is close to the right value.
  bool get usedSwissEphemerisFiles =>
      returnFlags & seflgSwieph != 0 &&
      returnFlags & seflgMoseph == 0 &&
      error.isEmpty;
}
