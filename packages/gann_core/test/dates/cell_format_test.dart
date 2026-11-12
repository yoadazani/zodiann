import 'package:gann_core/gann_core.dart';
import 'package:test/test.dart';

void main() {
  group('formatCellDate (d.m.yy)', () {
    final cases = {
      DateTime.utc(2022, 1, 4): '4.1.22',
      DateTime.utc(2024, 1, 4): '4.1.24',
      DateTime.utc(1999, 12, 31): '31.12.99',
      DateTime.utc(2005, 1, 5): '5.1.05',
      DateTime.utc(2000, 1, 1): '1.1.00',
      DateTime.utc(2026, 11, 1): '1.11.26',
      DateTime.utc(2026, 10, 9): '9.10.26',
      DateTime.utc(2024, 1, 14): '14.1.24',
    };
    cases.forEach((date, expected) {
      test('$date → $expected', () {
        expect(formatCellDate(date), expected);
      });
    });
  });

  group('formatCellTime (HH:MM)', () {
    final cases = {
      DateTime.utc(2026, 11, 1): '00:00',
      DateTime.utc(2026, 11, 1, 4): '04:00',
      DateTime.utc(2026, 11, 1, 12, 5): '12:05',
      DateTime.utc(2026, 11, 1, 23, 59): '23:59',
    };
    cases.forEach((time, expected) {
      test('$time → $expected', () {
        expect(formatCellTime(time), expected);
      });
    });
  });

  test('formats the design reference cells', () {
    final anchor = OffsetDateTime.parse('2026-11-01T00:00+02:00');
    final zone = FixedOffsetTimeZone(120);
    String show(int n) {
      final w = localWallClock(cellMoment(anchor, n, stepHours: 4), zone);
      return '${formatCellDate(w)} / ${formatCellTime(w)}';
    }

    expect(show(2), '1.11.26 / 04:00');
    expect(show(52), '9.11.26 / 12:00');
    expect(show(169), '29.11.26 / 00:00');
  });

  test('rejects non-UTC-flagged carriers', () {
    expect(() => formatCellDate(DateTime(2026)), throwsArgumentError);
    expect(() => formatCellTime(DateTime(2026)), throwsArgumentError);
  });
}
