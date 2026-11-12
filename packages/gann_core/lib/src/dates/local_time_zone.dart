/// The device time zone as an injectable dependency, so the cell mapping
/// stays pure and testable (ZOD-GAN-003, NFR-A3).
library;

import '../model/offset_date_time.dart';

/// A time zone: the UTC offset in effect at a given instant.
abstract interface class LocalTimeZone {
  /// The offset from UTC, in minutes, in effect at [utc] (which must be UTC;
  /// otherwise [ArgumentError]).
  int offsetMinutesAt(DateTime utc);
}

/// The device's current time zone, as the platform reports it (including
/// its DST rules). The production zone for showing date-and-time cells.
final class DeviceTimeZone implements LocalTimeZone {
  /// Creates the device-zone adapter.
  const DeviceTimeZone();

  @override
  int offsetMinutesAt(DateTime utc) {
    _requireUtc(utc, 'utc');
    return DateTime.fromMicrosecondsSinceEpoch(utc.microsecondsSinceEpoch)
        .timeZoneOffset
        .inMinutes;
  }
}

/// A zone with one constant offset (no DST). For tests and fixed contexts.
final class FixedOffsetTimeZone implements LocalTimeZone {
  /// Creates a zone at [offsetMinutes] from UTC, within ±1080 (±18:00, the
  /// same bound as [OffsetDateTime]); otherwise [ArgumentError].
  FixedOffsetTimeZone(this.offsetMinutes) {
    if (offsetMinutes.abs() > OffsetDateTime.maxOffsetMinutes) {
      throw ArgumentError.value(
        offsetMinutes,
        'offsetMinutes',
        'must be within ±${OffsetDateTime.maxOffsetMinutes}',
      );
    }
  }

  /// The constant offset from UTC, in minutes.
  final int offsetMinutes;

  @override
  int offsetMinutesAt(DateTime utc) {
    _requireUtc(utc, 'utc');
    return offsetMinutes;
  }
}

void _requireUtc(DateTime value, String name) {
  if (!value.isUtc) throw ArgumentError.value(value, name, 'must be UTC');
}
