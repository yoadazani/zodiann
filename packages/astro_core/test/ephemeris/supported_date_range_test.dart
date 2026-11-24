// ZOD-FND-011: the product-supported date range (1900-01-01 through
// 2100-12-31 inclusive), judged on the UTC instant. Physical data-file
// coverage is a different thing and belongs to the adapter (EPH-002).
import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  const tick = Duration(microseconds: 1);

  group('SupportedDateRange bounds', () {
    test('start is 1900-01-01T00:00:00Z', () {
      expect(SupportedDateRange.start, DateTime.utc(1900, 1, 1));
    });

    test('end is the last microsecond of 2100-12-31', () {
      expect(
        SupportedDateRange.end,
        DateTime.utc(2100, 12, 31, 23, 59, 59, 999, 999),
      );
    });

    test('range is the UtcRange of start and end', () {
      expect(
        SupportedDateRange.range,
        UtcRange(SupportedDateRange.start, SupportedDateRange.end),
      );
    });

    test('range.contains the start and not the instant before 1900', () {
      expect(
        SupportedDateRange.range.contains(DateTime.utc(1900, 1, 1)),
        isTrue,
      );
      expect(
        SupportedDateRange.range.contains(DateTime.utc(1899, 12, 31, 12)),
        isFalse,
      );
    });
  });

  group('SupportedDateRange.classify', () {
    SupportedRangeSide side(DateTime utc) => SupportedDateRange.classify(utc);

    test('the first instant is inside, one microsecond before is before', () {
      expect(side(SupportedDateRange.start), SupportedRangeSide.inside);
      expect(
        side(SupportedDateRange.start.subtract(tick)),
        SupportedRangeSide.before,
      );
    });

    test('the last instant is inside, one microsecond after is after', () {
      expect(side(SupportedDateRange.end), SupportedRangeSide.inside);
      expect(side(SupportedDateRange.end.add(tick)), SupportedRangeSide.after);
    });

    test('the whole of 2100-12-31 is inside', () {
      expect(side(DateTime.utc(2100, 12, 31)), SupportedRangeSide.inside);
      expect(side(DateTime.utc(2100, 12, 31, 12)), SupportedRangeSide.inside);
      expect(
        side(DateTime.utc(2100, 12, 31, 23, 59, 59)),
        SupportedRangeSide.inside,
      );
    });

    test('a local 1900-01-01 00:00 at UTC+14 is before the range', () {
      // 1900-01-01T00:00+14:00 is 1899-12-31T10:00Z.
      expect(side(DateTime.utc(1899, 12, 31, 10)), SupportedRangeSide.before);
    });

    test('a local 2100-12-31 23:00 at UTC-10 is after the range', () {
      // 2100-12-31T23:00-10:00 is 2101-01-01T09:00Z.
      expect(side(DateTime.utc(2101, 1, 1, 9)), SupportedRangeSide.after);
    });

    test('J2000 and the current era are inside', () {
      expect(side(DateTime.utc(2000, 1, 1, 12)), SupportedRangeSide.inside);
      expect(side(DateTime.utc(2026, 11, 25)), SupportedRangeSide.inside);
    });

    test('the data-file era outside the product range is not inside', () {
      expect(side(DateTime.utc(1800, 1, 1)), SupportedRangeSide.before);
      expect(side(DateTime.utc(2399, 12, 31)), SupportedRangeSide.after);
    });

    test('a local DateTime is rejected, never silently treated as UTC', () {
      expect(() => side(DateTime(2000)), throwsArgumentError);
    });
  });

  group('against the ACC-1 reference dates', () {
    test('only the T = -1 instant lies outside the supported range', () {
      final json = jsonDecode(
        File('test/fixtures/reference_dates.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final instants = [
        for (final v in json['dates'] as List<dynamic>)
          DateTime.parse(v as String),
      ];
      final outside = [
        for (final t in instants)
          if (!SupportedDateRange.range.contains(t)) t,
      ];

      expect(instants, isNotEmpty);
      expect(outside, [DateTime.utc(1899, 12, 31, 12)]);
    });
  });
}
