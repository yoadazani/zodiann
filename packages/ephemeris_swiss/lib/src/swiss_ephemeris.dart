import 'package:astro_core/astro_core.dart';

import 'swiss_calculation_source.dart';

/// The `EphemerisPort` over Swiss Ephemeris with its packaged data files
/// (ZOD-EPH-002): the app's primary position source.
///
/// ## Positions and speed
///
/// Geocentric, apparent, true ecliptic and equinox of date, as the library
/// gives them for the flags [swissAdapterFlags]; no further correction is
/// applied. The speed is the library's own longitude speed from the same call
/// (CRS-A1), in degrees per day of the time scale passed to it.
///
/// ## Never an approximate answer
///
/// If the library fell back to its built-in ephemeris, reported a warning or an
/// error, or returned a number that is not finite, [position] returns
/// [OutOfCoveredRange]: data unavailable (R-2).
///
/// ## Time
///
/// From the start of the leap-second table (1972) the UTC instant is converted
/// to Terrestrial Time with the published leap seconds; from the table's
/// validity end the last offset is held, on the labelled assumption that UTC
/// stays continuous. **Before 1972 the UTC input is treated as Universal Time**
/// and the library applies its historical delta T; the input may differ from
/// UT1 by that day's DUT1. See `ephemerisTimeFor`.
///
/// ## Range and threading
///
/// [coveredRange] is the physical coverage of the packaged files, not the
/// product's supported range (that is enforced by the decorator in front of
/// every source). The native source serializes calls over one shared library
/// state, so ports may be used from several isolates; the data path is set once
/// for the process.
final class SwissEphemeris
    with MeanAscendingNodeFormula
    implements EphemerisPort {
  SwissEphemeris({required this._source, this._leapSeconds});

  final SwissCalculationSource _source;
  final LeapSecondTable? _leapSeconds;

  /// The instants the packaged files (`sepl_18`, `semo_18`) cover for all ten
  /// bodies.
  static final UtcRange fileCoverage = UtcRange(
    DateTime.utc(1800, 1, 2),
    DateTime.utc(2399, 12, 31),
  );

  @override
  UtcRange get coveredRange => fileCoverage;

  @override
  EphemerisResult position(Body body, DateTime utc) {
    if (!utc.isUtc) {
      throw ArgumentError.value(utc, 'utc', 'must be a UTC DateTime');
    }
    // The node first: it is formula-based and not bounded by the range.
    if (body == Body.node) {
      return EphemerisSuccess(meanAscendingNode(utc));
    }
    if (!coveredRange.contains(utc)) {
      return OutOfCoveredRange(requested: utc, covered: coveredRange);
    }
    final result = calculateSwissBody(
      _source,
      body,
      utc,
      leapSeconds: _leapSeconds,
    );
    if (result == null ||
        result.returnFlags < 0 ||
        !result.usedSwissEphemerisFiles ||
        !result.longitude.isFinite ||
        !result.speed.isFinite) {
      return OutOfCoveredRange(requested: utc, covered: coveredRange);
    }
    return EphemerisSuccess(
      EclipticPosition(
        longitude: normalizeDegrees(result.longitude),
        speed: result.speed,
      ),
    );
  }
}
