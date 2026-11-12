import 'package:gann_core/gann_core.dart';
import 'package:test/test.dart';

void main() {
  group('OffsetDateTime', () {
    test('round-trips through ISO-8601 with its offset', () {
      final samples = [
        OffsetDateTime(DateTime.utc(2026, 11, 12, 7), 120), // +02:00
        OffsetDateTime(DateTime.utc(2026, 11, 12, 3, 30), 330), // +05:30
        OffsetDateTime(DateTime.utc(2026, 11, 12, 3, 15), 345), // +05:45
        OffsetDateTime(DateTime.utc(2026, 11, 12, 12, 30), -210), // -03:30
        OffsetDateTime(DateTime.utc(2026, 11, 12, 9), 0), // Z
      ];

      for (final value in samples) {
        expect(OffsetDateTime.parse(value.toIso8601String()), value);
      }
    });

    test('prints wall-clock time with the offset, or Z for offset 0', () {
      expect(
        OffsetDateTime(DateTime.utc(2026, 11, 12, 7), 120).toIso8601String(),
        '2026-11-12T09:00:00.000+02:00',
      );
      expect(
        OffsetDateTime(
          DateTime.utc(2026, 11, 12, 12, 30),
          -210,
        ).toIso8601String(),
        '2026-11-12T09:00:00.000-03:30',
      );
      expect(
        OffsetDateTime(DateTime.utc(2026, 11, 12, 9), 0).toIso8601String(),
        '2026-11-12T09:00:00.000Z',
      );
    });

    test('keeps the wall-clock time of the offset', () {
      final value = OffsetDateTime.parse('2026-03-27T01:00:00+02:00');

      expect(value.instant, DateTime.utc(2026, 3, 26, 23));
      expect(value.offsetMinutes, 120);
      expect(value.wallClock, DateTime.utc(2026, 3, 27, 1));
    });

    test('same instant, different offset, is not equal', () {
      final instant = DateTime.utc(2026, 11, 12, 7);

      expect(OffsetDateTime(instant, 120), isNot(OffsetDateTime(instant, 0)));
      expect(OffsetDateTime(instant, 120), OffsetDateTime(instant, 120));
      expect(
        OffsetDateTime(instant, 120).hashCode,
        OffsetDateTime(instant, 120).hashCode,
      );
    });

    test('rejects a string without an explicit offset', () {
      expect(
        () => OffsetDateTime.parse('2026-11-12T09:00:00'),
        throwsFormatException,
      );
    });

    test('rejects garbage', () {
      expect(() => OffsetDateTime.parse('tomorrow'), throwsFormatException);
      expect(() => OffsetDateTime.parse('+02:00'), throwsFormatException);
    });

    test('rejects non-UTC instants and out-of-range offsets', () {
      final utc = DateTime.utc(2026);

      expect(() => OffsetDateTime(DateTime(2026), 0), throwsArgumentError);
      expect(() => OffsetDateTime(utc, 1081), throwsArgumentError);
      expect(() => OffsetDateTime(utc, -1081), throwsArgumentError);
      expect(OffsetDateTime(utc, 1080).offsetMinutes, 1080);
    });
  });
}
