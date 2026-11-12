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

    test('rejects lenient or non-canonical ISO-8601 forms', () {
      const bad = [
        '2026-02-30T09:00:00+02:00', // no Feb 30 (would roll to March)
        '2026-11-12T25:00:00+02:00', // hour 25
        '2026-11-12T24:00:00+02:00', // hour 24
        '2026-11-12T09:61:00+02:00', // minute 61
        '2026-11-12T09:00:00+05:75', // offset minutes 75
        '2026-11-12T09:00:00,5+02:00', // comma fraction
        '2026-11-12T09:00:00 +02:00', // space before offset
        '20261112T090000+02:00', // basic format
        ' 2026-11-12T09:00:00+02:00', // leading space
        '2026-11-12 09:00:00+02:00', // space instead of T
      ];

      for (final input in bad) {
        expect(
          () => OffsetDateTime.parse(input),
          throwsFormatException,
          reason: input,
        );
      }
    });

    test(
      'accepts its own canonical output for extreme years and microseconds',
      () {
        final samples = [
          OffsetDateTime(DateTime.utc(10000, 1, 1, 0, 0, 0, 0, 1), 60),
          OffsetDateTime(DateTime.utc(999, 6, 1, 12, 0, 0, 123, 456), -330),
        ];

        for (final value in samples) {
          expect(OffsetDateTime.parse(value.toIso8601String()), value);
        }
      },
    );

    test('rejects an instant whose wall-clock time is out of range', () {
      expect(
        () => OffsetDateTime(DateTime.utc(275760, 9, 13), 1080),
        throwsArgumentError,
      );
      expect(
        () => OffsetDateTime.parse('+275760-09-13T10:00:00+18:00'),
        throwsFormatException,
      );
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
