// T-FMT-1 (ZOD-TST-013): a cell date is shown as day.month.year with a
// two-digit year and no leading zero on the day or month (e.g. 4.1.24).
// "Two digits only" applies to the year (2005 → 05), as settled in the
// ZOD-GAN-003 plan, MASTER.md §8.2 (`4.1.22`) and Excel's `d.m.yy` (EX-1).
//
// Independence rules (product-owner decision, see the TST-013 task file):
// * Only `formatCellDate` — the code under test — is imported.
// * Spot checks compare against literal strings.
// * The full grid never rebuilds the expected string the way production
//   does: it parses the output back (split on '.') and checks character-level
//   properties and the numbers against the loop variables.
// * Each grid date is checked at 00:00 and 23:59:59.999 UTC, so reading the
//   carrier through the machine's zone (east or west of UTC) is caught.
//
// Out of scope: HH:MM (GAN-003 tests), English month-first order (L-12,
// ZOD-L10-010), Excel number formats (XLS tasks).
import 'package:gann_core/gann_core.dart' show formatCellDate;
import 'package:test/test.dart';

bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

int _daysInMonth(int y, int m) => switch (m) {
  2 => _isLeap(y) ? 29 : 28,
  4 || 6 || 9 || 11 => 30,
  _ => 31,
};

final _shape = RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+$');

/// Problems with [out] as the `d.m.yy` form of the date ([d], [m], [y]);
/// empty when it is right.
List<String> _checkShape(String out, int d, int m, int y) {
  final problems = <String>[];
  if (!_shape.hasMatch(out)) problems.add('shape');
  final parts = out.split('.');
  if (parts.length != 3) return [...problems, '${parts.length} parts'];
  final [day, month, year] = parts;
  if (day.startsWith('0')) problems.add('leading zero on day');
  if (month.startsWith('0')) problems.add('leading zero on month');
  if (year.length != 2) problems.add('year has ${year.length} characters');
  if (int.tryParse(day) != d) problems.add('day $day ≠ $d');
  if (int.tryParse(month) != m) problems.add('month $month ≠ $m');
  if (int.tryParse(year) != y % 100) problems.add('year $year ≠ ${y % 100}');
  return problems;
}

void main() {
  group('oracle self-check', () {
    test('month lengths follow the Gregorian rules', () {
      expect(_daysInMonth(2024, 2), 29);
      expect(_daysInMonth(2026, 2), 28);
      expect(_daysInMonth(2100, 2), 28);
      expect(_daysInMonth(2000, 2), 29);
      expect(_daysInMonth(2026, 4), 30);
      expect(_daysInMonth(2026, 12), 31);
    });

    test('the shape check accepts the right form and flags deviations', () {
      expect(_checkShape('4.1.24', 4, 1, 2024), isEmpty);
      expect(
        _checkShape('04.1.24', 4, 1, 2024),
        contains('leading zero on day'),
      );
      expect(
        _checkShape('4.01.24', 4, 1, 2024),
        contains('leading zero on month'),
      );
      expect(
        _checkShape('4.1.2024', 4, 1, 2024),
        contains('year has 4 characters'),
      );
      expect(_checkShape('4/1/24', 4, 1, 2024), isNotEmpty);
    });
  });

  group('literal spot checks', () {
    final cases = {
      '2024-01-04': (DateTime.utc(2024, 1, 4), '4.1.24'),
      '2024-11-14': (DateTime.utc(2024, 11, 14), '14.11.24'),
      '2024-11-04': (DateTime.utc(2024, 11, 4), '4.11.24'),
      '2024-01-14': (DateTime.utc(2024, 1, 14), '14.1.24'),
      '2022-01-04': (DateTime.utc(2022, 1, 4), '4.1.22'),
      '2024-02-29': (DateTime.utc(2024, 2, 29), '29.2.24'),
      '1999-12-31': (DateTime.utc(1999, 12, 31), '31.12.99'),
      '2000-01-01': (DateTime.utc(2000, 1, 1), '1.1.00'),
      '2005-01-05': (DateTime.utc(2005, 1, 5), '5.1.05'),
      '2009-09-09': (DateTime.utc(2009, 9, 9), '9.9.09'),
      '2010-10-10': (DateTime.utc(2010, 10, 10), '10.10.10'),
      '2026-08-31': (DateTime.utc(2026, 8, 31), '31.8.26'),
      '2026-10-01': (DateTime.utc(2026, 10, 1), '1.10.26'),
      '2100-03-01': (DateTime.utc(2100, 3, 1), '1.3.00'),
      '1900-01-01': (DateTime.utc(1900, 1, 1), '1.1.00'),
    };
    cases.forEach((iso, c) {
      final (date, expected) = c;
      test('$iso → $expected', () {
        expect(formatCellDate(date), expected);
      });
    });
  });

  group('every day and month combination', () {
    for (final (year, expectedCount) in [(2024, 366), (2026, 365)]) {
      test(
        '$year: every valid day 1–31 × month 1–12, both ends of the day',
        () {
          final problems = <String>[];
          var startOfDay = 0;
          var endOfDay = 0;
          for (var m = 1; m <= 12; m++) {
            for (var d = 1; d <= 31; d++) {
              if (d > _daysInMonth(year, m)) continue;
              final inputs = [
                DateTime.utc(year, m, d),
                DateTime.utc(year, m, d, 23, 59, 59, 999),
              ];
              for (final input in inputs) {
                if (input.day != d || input.month != m) {
                  problems.add('$input normalised away from $d.$m');
                }
                final out = formatCellDate(input);
                for (final p in _checkShape(out, d, m, year)) {
                  problems.add('$input → "$out": $p');
                }
              }
              startOfDay++;
              endOfDay++;
            }
          }
          expect(problems, isEmpty);
          expect(startOfDay, expectedCount);
          expect(endOfDay, expectedCount);
        },
      );
    }
  });

  test('two-digit year across 1900–2100', () {
    final problems = <String>[];
    var years = 0;
    for (var y = 1900; y <= 2100; y++) {
      final out = formatCellDate(DateTime.utc(y, 1, 1));
      for (final p in _checkShape(out, 1, 1, y)) {
        problems.add('$y → "$out": $p');
      }
      years++;
    }
    expect(problems, isEmpty);
    expect(years, 201);
  });
}
