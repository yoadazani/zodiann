/// How well delta T (TT − UT1) is known at an instant. It describes
/// Earth-rotation data only: it is not an accuracy statement about positions
/// and it does not choose the time conversion
/// (docs/decisions/ZOD-EPH-002-time-scale.md, section 2).
enum DeltaTStatus {
  /// Measured.
  observed,

  /// Extrapolated close to the measurements.
  estimated,

  /// A forecast.
  forecast,
}

/// Where a delta T data set stops being measured and stops being estimated.
/// It is data, so newer data changes the classification without new code.
final class DeltaTDataset {
  /// Throws [ArgumentError] if a bound is not UTC or if [estimatedBefore] is
  /// before [observedBefore].
  DeltaTDataset({
    required this.observedBefore,
    required this.estimatedBefore,
    required this.source,
  }) {
    if (!observedBefore.isUtc) {
      throw ArgumentError.value(
        observedBefore,
        'observedBefore',
        'must be UTC',
      );
    }
    if (!estimatedBefore.isUtc || estimatedBefore.isBefore(observedBefore)) {
      throw ArgumentError.value(
        estimatedBefore,
        'estimatedBefore',
        'must be a UTC instant not before observedBefore',
      );
    }
  }

  /// The table inside the vendored Swiss Ephemeris: observed through 2023,
  /// extrapolated for 2024 to 2028. A guard in `ephemeris_swiss` ties
  /// [estimatedBefore] to the library's own table end.
  static final DeltaTDataset bundled = DeltaTDataset(
    observedBefore: DateTime.utc(2024),
    estimatedBefore: DateTime.utc(2029),
    source: 'Swiss Ephemeris 2.10.03 delta T table (swephlib.c)',
  );

  /// Instants before this are [DeltaTStatus.observed].
  final DateTime observedBefore;

  /// Instants before this, and not observed, are [DeltaTStatus.estimated].
  final DateTime estimatedBefore;

  /// Where the data came from.
  final String source;
}

/// The status of delta T at [utc] in [dataset] (the bundled one by default).
///
/// Throws [ArgumentError] if [utc] is not UTC.
DeltaTStatus deltaTStatusAt(DateTime utc, {DeltaTDataset? dataset}) {
  if (!utc.isUtc) {
    throw ArgumentError.value(utc, 'utc', 'must be a UTC DateTime');
  }
  final data = dataset ?? DeltaTDataset.bundled;
  if (utc.isBefore(data.observedBefore)) return DeltaTStatus.observed;
  if (utc.isBefore(data.estimatedBefore)) return DeltaTStatus.estimated;
  return DeltaTStatus.forecast;
}
