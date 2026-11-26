import 'package:astro_core/astro_core.dart';

import 'swiss_calc.dart';

/// The flag word the adapter sends on every call: the packaged data files and
/// the library's own speed, and nothing else. No precession, sidereal or J2000
/// flag, so the output stays apparent, true ecliptic of date.
const int swissAdapterFlags = seflgSwieph | seflgSpeed;

/// The library's body numbers (`SE_SUN` to `SE_PLUTO` in `swephexp.h`). An
/// explicit table, not `Body.index`, so reordering the enum cannot silently
/// change what the library is asked. [Body.node] is absent: it is
/// formula-based.
const Map<Body, int> swissBodyIds = {
  Body.sun: 0,
  Body.moon: 1,
  Body.mercury: 2,
  Body.venus: 3,
  Body.mars: 4,
  Body.jupiter: 5,
  Body.saturn: 6,
  Body.uranus: 7,
  Body.neptune: 8,
  Body.pluto: 9,
};

/// Where the adapter gets a calculation. The native implementation is device
/// only (`package:ephemeris_swiss/ephemeris_swiss_native.dart`); host tests
/// inject a fake. Both methods return null when the source cannot calculate.
abstract interface class SwissCalculationSource {
  /// `swe_calc_ut`: [utc] is taken as Universal Time.
  SwissCalcResult? calcUt(DateTime utc, int body, {required int flags});

  /// `swe_calc`: [tjdTt] is a Julian day in Terrestrial Time.
  SwissCalcResult? calcTt(double tjdTt, int body, {required int flags});
}

/// The source used when the library or its data files cannot be used: every
/// request is unavailable.
final class UnavailableSwissCalculationSource
    implements SwissCalculationSource {
  const UnavailableSwissCalculationSource();

  @override
  SwissCalcResult? calcUt(DateTime utc, int body, {required int flags}) => null;

  @override
  SwissCalcResult? calcTt(double tjdTt, int body, {required int flags}) => null;
}

/// One calculation with the approved time conversion
/// (docs/decisions/ZOD-EPH-002-time-scale.md). It checks no covered range and
/// does not judge the result: the adapter does both, and the coverage
/// measurement uses this function to find where the range ends.
///
/// Throws [ArgumentError] if [utc] is not UTC or [body] is [Body.node].
SwissCalcResult? calculateSwissBody(
  SwissCalculationSource source,
  Body body,
  DateTime utc, {
  LeapSecondTable? leapSeconds,
}) {
  final id = swissBodyIds[body];
  if (id == null) {
    throw ArgumentError.value(body, 'body', 'has no library calculation');
  }
  return switch (ephemerisTimeFor(utc, table: leapSeconds)) {
    UniversalTime() => source.calcUt(utc, id, flags: swissAdapterFlags),
    // The Julian day of the shifted instant: the offset is added in integer
    // microseconds before the one conversion to a floating day number.
    TerrestrialTime(:final ttMinusUtc) => source.calcTt(
      julianDayUt(utc.add(ttMinusUtc)),
      id,
      flags: swissAdapterFlags,
    ),
  };
}
