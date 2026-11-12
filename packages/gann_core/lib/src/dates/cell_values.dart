/// What each Square of Nine cell holds in each mode (SQ-2, SQ-3, SQ-4),
/// today's cell (SQ-6), and a cell's distance from the anchor (SQ-18).
///
/// **Time-zone rule** (product-owner decision 2026-11-12, see the
/// ZOD-GAN-003 Notes; NFR-A3):
/// - **Date-and-time mode** steps in absolute time: cell `n` is the anchor
///   instant plus `stepHours·(n−1)` hours, shown in the **device's current
///   zone** ([localWallClock]). A DST change therefore shows as a visible
///   one-hour jump in the displayed hours (e.g. 00:00 → 05:00 in spring).
///   After travel the same cells show in the new zone.
/// - **Dates mode** is calendar-only: cell `n` is the anchor's own calendar
///   date (its [OffsetDateTime.wallClock]) plus `n−1` days. It is unaffected
///   by DST and by travel; only "today" uses the device zone.
///
/// All dates and wall clocks are returned as UTC-flagged [DateTime]s that
/// merely carry calendar/clock fields — never a real instant in disguise.
library;

import '../model/offset_date_time.dart';
import 'local_time_zone.dart';

/// Upper bound on `n − 1` in dates mode: far beyond any square, and small
/// enough that the day arithmetic cannot overflow.
const int _maxDayOffset = 100000000;

/// Upper bound on `stepHours·(n − 1)`: ~273,000 years, inside [DateTime]'s
/// ±100,000,000-day range from any representable anchor's neighbourhood,
/// and far from 64-bit overflow.
const int _maxHourOffset = 2400000000;

/// Numbers mode: cell `n` holds the number `n` (SQ-2).
int cellNumber(int n) {
  _requireN(n);
  return n;
}

/// Dates mode: the calendar date of cell [n] — the anchor's own date
/// (from [OffsetDateTime.wallClock], not its UTC instant) plus `n − 1` days
/// (SQ-3). Throws [ArgumentError] for `n < 1` or a date beyond [DateTime]'s
/// range.
DateTime cellDate(OffsetDateTime anchor, int n) {
  _requireN(n);
  if (n - 1 > _maxDayOffset) {
    throw ArgumentError.value(n, 'n', 'date out of range');
  }
  final w = anchor.wallClock;
  final DateTime result;
  try {
    result = DateTime.utc(w.year, w.month, w.day + n - 1);
  } on ArgumentError {
    throw ArgumentError.value(n, 'n', 'date out of range');
  }
  if (result.isBefore(DateTime.utc(w.year, w.month, w.day))) {
    throw ArgumentError.value(n, 'n', 'date out of range');
  }
  return result;
}

/// Date-and-time mode: the UTC instant of cell [n] — the anchor instant plus
/// `stepHours·(n − 1)` absolute hours (SQ-4). Show it with [localWallClock].
/// Throws [ArgumentError] for `n < 1`, `stepHours < 1`, or an instant beyond
/// [DateTime]'s range.
DateTime cellMoment(OffsetDateTime anchor, int n, {required int stepHours}) {
  final hours = hoursAfterAnchor(n, stepHours: stepHours);
  final DateTime result;
  try {
    result = anchor.instant.add(Duration(hours: hours));
  } on Object catch (e) {
    if (e is! ArgumentError && e is! RangeError) rethrow;
    throw ArgumentError.value(n, 'n', 'moment out of range');
  }
  if (result.isBefore(anchor.instant)) {
    throw ArgumentError.value(n, 'n', 'moment out of range');
  }
  return result;
}

/// The wall clock of [utcInstant] in [zone], as a UTC-flagged [DateTime]
/// carrying the local fields. Throws [ArgumentError] for a non-UTC input or
/// a result beyond [DateTime]'s range.
DateTime localWallClock(DateTime utcInstant, LocalTimeZone zone) {
  _requireUtc(utcInstant, 'utcInstant');
  final offset = zone.offsetMinutesAt(utcInstant);
  try {
    return utcInstant.add(Duration(minutes: offset));
  } on ArgumentError {
    throw ArgumentError.value(utcInstant, 'utcInstant', 'out of range');
  }
}

/// Dates mode: the cell holding today's date in [zone], or `null` when
/// today is before the anchor date (SQ-6). The anchor date is always the
/// anchor's own calendar date, never re-derived through [zone].
int? todayCellInDatesMode(
  OffsetDateTime anchor,
  DateTime nowUtc,
  LocalTimeZone zone,
) {
  _requireUtc(nowUtc, 'nowUtc');
  final local = localWallClock(nowUtc, zone);
  final today = DateTime.utc(local.year, local.month, local.day);
  final w = anchor.wallClock;
  final anchorDate = DateTime.utc(w.year, w.month, w.day);
  final days = today.difference(anchorDate).inDays;
  return days < 0 ? null : days + 1;
}

/// Date-and-time mode: the cell whose block contains [nowUtc] — whole
/// `stepHours` blocks elapsed since the anchor instant, plus one — or `null`
/// before the anchor (SQ-6).
int? nowCellInDateTimeMode(
  OffsetDateTime anchor,
  DateTime nowUtc, {
  required int stepHours,
}) {
  _requireUtc(nowUtc, 'nowUtc');
  _requireStep(stepHours);
  if (nowUtc.isBefore(anchor.instant)) return null;
  final elapsedHours =
      nowUtc.difference(anchor.instant).inMicroseconds ~/
      Duration.microsecondsPerHour;
  return elapsedHours ~/ stepHours + 1;
}

/// Dates mode distance (SQ-18): cell [n] is `n − 1` days after the anchor.
int daysAfterAnchor(int n) {
  _requireN(n);
  return n - 1;
}

/// Date-and-time mode distance (SQ-18): cell [n] is `stepHours·(n − 1)`
/// absolute hours after the anchor. Throws [ArgumentError] when that exceeds
/// the supported range (checked before multiplying, so it cannot overflow).
int hoursAfterAnchor(int n, {required int stepHours}) {
  _requireN(n);
  _requireStep(stepHours);
  if (n - 1 > _maxHourOffset ~/ stepHours) {
    throw ArgumentError.value(n, 'n', 'moment out of range');
  }
  return stepHours * (n - 1);
}

void _requireN(int n) {
  if (n < 1) throw ArgumentError.value(n, 'n', 'must be ≥ 1');
}

void _requireStep(int stepHours) {
  if (stepHours < 1) {
    throw ArgumentError.value(stepHours, 'stepHours', 'must be ≥ 1');
  }
}

void _requireUtc(DateTime value, String name) {
  if (!value.isUtc) throw ArgumentError.value(value, name, 'must be UTC');
}
