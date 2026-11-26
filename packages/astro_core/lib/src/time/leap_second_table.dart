/// One step of TAI − UTC: [taiMinusUtcSeconds] applies from [from] (00:00:00
/// UTC) until the next step.
final class LeapSecondStep {
  const LeapSecondStep({required this.from, required this.taiMinusUtcSeconds});

  /// The UTC instant the value takes effect.
  final DateTime from;

  /// TAI − UTC, in whole seconds.
  final int taiMinusUtcSeconds;
}

/// The published TAI − UTC steps as **data with provenance**: where they came
/// from, which bulletin, and until when the publisher vouches for them. The
/// table is replaceable, so newer data is a different value, not new code
/// (ZOD-EPH-002, docs/decisions/ZOD-EPH-002-time-scale.md).
final class LeapSecondTable {
  /// Throws [ArgumentError] if [steps] is empty, if any instant is not UTC,
  /// if the steps are not strictly ascending, or if [validUntil] is not after
  /// the last step.
  LeapSecondTable({
    required Iterable<LeapSecondStep> steps,
    required this.validUntil,
    required this.source,
    required this.bulletin,
  }) : steps = List.unmodifiable(steps) {
    if (this.steps.isEmpty) {
      throw ArgumentError.value(steps, 'steps', 'must not be empty');
    }
    DateTime? previous;
    for (final step in this.steps) {
      if (!step.from.isUtc) {
        throw ArgumentError.value(step.from, 'steps', 'must be UTC');
      }
      if (previous != null && !step.from.isAfter(previous)) {
        throw ArgumentError.value(
          step.from,
          'steps',
          'must be strictly ascending',
        );
      }
      previous = step.from;
    }
    if (!validUntil.isUtc || !validUntil.isAfter(previous!)) {
      throw ArgumentError.value(
        validUntil,
        'validUntil',
        'must be a UTC instant after the last step',
      );
    }
  }

  /// The table packaged with the app: IERS `Leap_Second.dat`, updated through
  /// Bulletin C 72, expiring on 28 June 2027.
  static final LeapSecondTable bundled = LeapSecondTable(
    steps: [
      for (final (year, month, seconds) in _bundledSteps)
        LeapSecondStep(
          from: DateTime.utc(year, month),
          taiMinusUtcSeconds: seconds,
        ),
    ],
    validUntil: DateTime.utc(2027, 6, 28),
    source: 'IERS Leap_Second.dat',
    bulletin: 'Bulletin C 72 (July 2026)',
  );

  /// The steps, oldest first. Unmodifiable.
  final List<LeapSecondStep> steps;

  /// The publisher vouches for the table before this UTC instant.
  final DateTime validUntil;

  /// Where the data came from.
  final String source;

  /// The announcement the data is current through.
  final String bulletin;

  /// TAI − UTC at [utc]: the last step at or before it, or null before the
  /// first step. Past [validUntil] the last value is returned; the caller
  /// decides what that means (see `ephemerisTimeFor`).
  ///
  /// Throws [ArgumentError] if [utc] is not UTC.
  int? taiMinusUtcSecondsAt(DateTime utc) {
    if (!utc.isUtc) {
      throw ArgumentError.value(utc, 'utc', 'must be a UTC DateTime');
    }
    for (final step in steps.reversed) {
      if (!utc.isBefore(step.from)) return step.taiMinusUtcSeconds;
    }
    return null;
  }
}

/// (year, month, TAI − UTC), each from day 1 at 00:00:00 UTC.
const _bundledSteps = [
  (1972, 1, 10),
  (1972, 7, 11),
  (1973, 1, 12),
  (1974, 1, 13),
  (1975, 1, 14),
  (1976, 1, 15),
  (1977, 1, 16),
  (1978, 1, 17),
  (1979, 1, 18),
  (1980, 1, 19),
  (1981, 7, 20),
  (1982, 7, 21),
  (1983, 7, 22),
  (1985, 7, 23),
  (1988, 1, 24),
  (1990, 1, 25),
  (1991, 1, 26),
  (1992, 7, 27),
  (1993, 7, 28),
  (1994, 7, 29),
  (1996, 1, 30),
  (1997, 7, 31),
  (1999, 1, 32),
  (2006, 1, 33),
  (2009, 1, 34),
  (2012, 7, 35),
  (2015, 7, 36),
  (2017, 1, 37),
];
