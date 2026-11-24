import 'utc_range.dart';

/// Where a UTC instant lies relative to [SupportedDateRange].
enum SupportedRangeSide {
  /// Earlier than [SupportedDateRange.start].
  before,

  /// Within [SupportedDateRange.range], both ends included.
  inside,

  /// Later than [SupportedDateRange.end].
  after,
}

/// The date range the product supports: **1900-01-01 through 2100-12-31,
/// inclusive** (owner decision ZOD-FND-011, 2026-11-25; R-2, NFR-R2).
///
/// This is the single definition of the product range. Every consumer reads
/// it from here: the position guard in front of every ephemeris source, the
/// degree-crossing query API, and each date input route of the wheel. No
/// other file may state it again.
///
/// ## It is not the data-file coverage
///
/// The Swiss Ephemeris files that ship (`sepl_18`, `semo_18`) nominally cover
/// 1800 to 2400, named after the upstream blocks and not device-verified. That
/// *physical coverage* belongs to the adapter (ZOD-EPH-002), whose
/// `SwissCalcResult.usedSwissEphemerisFiles` is the runtime check that the
/// files were used. The range here is narrower on purpose: accuracy is
/// validated only for 1900 to 2100 (ACC-1), so nothing outside it is offered.
///
/// ## Judged on the UTC instant
///
/// Membership is decided on the UTC instant *after* the caller converts local
/// time to UTC (as the `EphemerisPort` contract requires), never on the local
/// calendar date. A local 1900-01-01 00:00 at UTC+14 is 1899-12-31T10:00Z and
/// is [SupportedRangeSide.before]; a local 2100-12-31 23:00 at UTC-10 is
/// 2101-01-01T09:00Z and is [SupportedRangeSide.after]. So the same instant is
/// never valid in one time zone and rejected in another.
///
/// Not the Excel limit: an anchor before 1900 is an export rule of the Square
/// (XLS-017) and the Square does not use the ephemeris.
abstract final class SupportedDateRange {
  /// The first supported instant: 1900-01-01T00:00:00Z.
  static final DateTime start = DateTime.utc(1900, 1, 1);

  /// The last supported instant: the final microsecond of 2100-12-31, so the
  /// whole day is inside.
  static final DateTime end = DateTime.utc(2100, 12, 31, 23, 59, 59, 999, 999);

  /// [start] to [end], both included.
  static final UtcRange range = UtcRange(start, end);

  /// Where [utc] lies relative to [range].
  ///
  /// Throws [ArgumentError] if [utc] is not UTC, like [UtcRange.contains]:
  /// local times are converted by the caller, never treated as UTC.
  static SupportedRangeSide classify(DateTime utc) {
    if (range.contains(utc)) return SupportedRangeSide.inside;
    return utc.isBefore(start)
        ? SupportedRangeSide.before
        : SupportedRangeSide.after;
  }
}
