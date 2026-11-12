import 'iso8601.dart';

/// A moment in time together with the UTC offset it was expressed in.
///
/// DATA-4: anchor dates are saved with a time zone offset, so a square opens
/// with exactly the same dates when travelling or across a daylight-saving
/// change. Dart's [DateTime] can only be UTC or device-local, so it cannot
/// carry an arbitrary offset; this type does.
final class OffsetDateTime {
  /// Creates the moment [instant] (which must be UTC) as seen at
  /// [offsetMinutes] from UTC.
  ///
  /// Throws [ArgumentError] if [instant] is not UTC, [offsetMinutes] is
  /// outside ±1080 (±18 hours, the ISO-8601 limit), or the resulting
  /// wall-clock time is outside `DateTime`'s range (it could not be
  /// serialized).
  OffsetDateTime(this.instant, this.offsetMinutes)
    : wallClock = _wallClockOf(instant, offsetMinutes);

  static DateTime _wallClockOf(DateTime instant, int offsetMinutes) {
    if (!instant.isUtc) {
      throw ArgumentError.value(instant, 'instant', 'must be a UTC DateTime');
    }
    if (offsetMinutes < -maxOffsetMinutes || offsetMinutes > maxOffsetMinutes) {
      throw ArgumentError.value(
        offsetMinutes,
        'offsetMinutes',
        'must be within ±$maxOffsetMinutes',
      );
    }
    try {
      return instant.add(Duration(minutes: offsetMinutes));
    } on ArgumentError {
      throw ArgumentError.value(
        instant,
        'instant',
        'wall-clock time at offset $offsetMinutes is out of range',
      );
    }
  }

  /// Parses a canonical ISO-8601 date-time with an explicit offset (`Z` or
  /// `±HH:MM`), e.g. `2026-11-12T09:00:00+02:00`.
  ///
  /// Throws [FormatException] if the input is not canonical, has no explicit
  /// offset (it is never guessed), or has an out-of-range field such as
  /// February 30 or offset minutes ≥ 60 (never silently normalized).
  static OffsetDateTime parse(String input) {
    final parsed = parseStrictIso8601(input);
    try {
      return OffsetDateTime(parsed.instant, parsed.offsetMinutes);
    } on ArgumentError catch (e) {
      throw FormatException('${e.message}', input);
    }
  }

  static const maxOffsetMinutes = 18 * 60;

  /// The moment itself, in UTC.
  final DateTime instant;

  /// Offset from UTC in minutes (e.g. 120 for +02:00, -210 for -03:30).
  final int offsetMinutes;

  /// The local wall-clock date and time at [offsetMinutes], as a UTC-flagged
  /// [DateTime] whose fields are the wall-clock fields.
  final DateTime wallClock;

  /// ISO-8601 wall-clock time plus offset, e.g.
  /// `2026-11-12T09:00:00.000+02:00`, or `…Z` when the offset is 0.
  String toIso8601String() {
    final local = wallClock.toIso8601String(); // ends with 'Z'
    final base = local.substring(0, local.length - 1);
    if (offsetMinutes == 0) return '${base}Z';
    final sign = offsetMinutes < 0 ? '-' : '+';
    final abs = offsetMinutes.abs();
    String two(int n) => n.toString().padLeft(2, '0');
    return '$base$sign${two(abs ~/ 60)}:${two(abs % 60)}';
  }

  @override
  bool operator ==(Object other) =>
      other is OffsetDateTime &&
      other.instant == instant &&
      other.offsetMinutes == offsetMinutes;

  @override
  int get hashCode => Object.hash(instant, offsetMinutes);

  @override
  String toString() => 'OffsetDateTime(${toIso8601String()})';
}
