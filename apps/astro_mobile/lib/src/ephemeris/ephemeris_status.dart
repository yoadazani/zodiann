import 'package:astro_core/astro_core.dart';

/// Which position source startup bound (ZOD-EPH-002).
enum ActiveEphemerisSource {
  /// Swiss Ephemeris with its packaged data files.
  primary,

  /// astronomy-engine, chosen only because the Swiss library did not load.
  backup,

  /// No source can calculate: positions of physical bodies are unavailable.
  none,
}

/// How the active source turns a UTC instant into the time it calculates with.
enum ReportedTimeBasis {
  /// Before the leap-second table: the library's historical delta T.
  historicalDeltaT,

  /// The published leap-second table.
  publishedLeapSeconds,

  /// After the table's validity end: continuous UTC is assumed.
  assumedContinuousUtc,

  /// The backup's own delta T model (until ZOD-EPH-006).
  backupOwnDeltaT,
}

/// What the app can report about positions: the active source, and for an
/// instant the time basis and the delta T data status. Both are kept apart:
/// the basis says how time was converted, the status how well Earth rotation is
/// known (docs/decisions/ZOD-EPH-002-time-scale.md).
final class EphemerisStatus {
  const EphemerisStatus(this.source);

  final ActiveEphemerisSource source;

  /// The time basis at [utc], or null when no source is available.
  ///
  /// Throws [ArgumentError] if [utc] is not UTC.
  ReportedTimeBasis? timeBasisAt(DateTime utc) {
    _requireUtc(utc);
    return switch (source) {
      ActiveEphemerisSource.primary => switch (ephemerisTimeFor(utc)) {
        UniversalTime() => ReportedTimeBasis.historicalDeltaT,
        TerrestrialTime(basis: TtBasis.publishedLeapSeconds) =>
          ReportedTimeBasis.publishedLeapSeconds,
        TerrestrialTime(basis: TtBasis.assumedContinuousUtc) =>
          ReportedTimeBasis.assumedContinuousUtc,
      },
      ActiveEphemerisSource.backup => ReportedTimeBasis.backupOwnDeltaT,
      ActiveEphemerisSource.none => null,
    };
  }

  /// The delta T data status at [utc] for the primary source; null for any
  /// other, because it describes the primary source's data.
  ///
  /// Throws [ArgumentError] if [utc] is not UTC.
  DeltaTStatus? dataStatusAt(DateTime utc) {
    _requireUtc(utc);
    return source == ActiveEphemerisSource.primary ? deltaTStatusAt(utc) : null;
  }

  static void _requireUtc(DateTime utc) {
    if (!utc.isUtc) {
      throw ArgumentError.value(utc, 'utc', 'must be a UTC DateTime');
    }
  }
}
