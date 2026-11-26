import 'leap_second_table.dart';

/// TT − TAI, fixed by definition.
const int _ttMinusTaiMicroseconds = 32184000;

/// What a terrestrial-time offset rests on.
enum TtBasis {
  /// The instant is covered by the published leap-second table.
  publishedLeapSeconds,

  /// The instant is at or after the table's validity end: the last offset is
  /// held on the assumption that UTC stays continuous. It is an assumption,
  /// not a guarantee, so results that rest on it are labelled.
  assumedContinuousUtc,
}

/// How a UTC instant is given to an ephemeris.
sealed class EphemerisTime {
  const EphemerisTime();
}

/// The instant is used as Universal Time; the ephemeris applies its own
/// historical delta T. This is the case before the leap-second table begins.
final class UniversalTime extends EphemerisTime {
  const UniversalTime();
}

/// The instant is converted to Terrestrial Time: `TT = UTC + [ttMinusUtc]`.
final class TerrestrialTime extends EphemerisTime {
  const TerrestrialTime({required this.ttMinusUtc, required this.basis});

  /// (TAI − UTC) + 32.184 s, exact to the microsecond.
  final Duration ttMinusUtc;

  /// What the offset rests on.
  final TtBasis basis;
}

/// The approved time conversion for planet positions
/// (docs/decisions/ZOD-EPH-002-time-scale.md): leap seconds from the start of
/// [table] (1972 for the bundled one), Universal Time before it, and the last
/// offset held, labelled, from the table's validity end.
///
/// TT as a function of UTC has small steps at each leap second and at the
/// start of the table.
///
/// Throws [ArgumentError] if [utc] is not UTC.
EphemerisTime ephemerisTimeFor(DateTime utc, {LeapSecondTable? table}) {
  final leapSeconds = table ?? LeapSecondTable.bundled;
  final taiMinusUtc = leapSeconds.taiMinusUtcSecondsAt(utc);
  if (taiMinusUtc == null) return const UniversalTime();
  return TerrestrialTime(
    ttMinusUtc: Duration(
      microseconds:
          _ttMinusTaiMicroseconds +
          taiMinusUtc * Duration.microsecondsPerSecond,
    ),
    basis: utc.isBefore(leapSeconds.validUntil)
        ? TtBasis.publishedLeapSeconds
        : TtBasis.assumedContinuousUtc,
  );
}
