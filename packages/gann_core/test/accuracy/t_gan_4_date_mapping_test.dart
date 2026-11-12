// T-GAN-4 (ZOD-TST-012): date mapping — the anchor cell is the anchor date,
// and today's cell is marked exactly, at a daylight-saving boundary and in a
// leap year (spec T-GAN-4, R-4; decided rule in the ZOD-GAN-003 Notes).
//
// Independence rules (product-owner decision, see the TST-012 task file):
// * Only the code under test is imported (`show` list). Expected values are
//   literals or come from this file's own Gregorian calendar (`_nextDay`,
//   `_dayNumber` on records, self-checked against literals) and plain
//   `DateTime` microsecond arithmetic — never from production helpers.
// * Time zones are test-local fakes mirroring the real 2026 rules:
//   - Israel: DST starts Friday before the last Sunday of March
//     (27.3, 02:00 → 03:00 = 00:00Z) and ends the last Sunday of October
//     (25.10, 02:00 → 01:00 = 24.10 23:00Z);
//   - New York: second Sunday of March (8.3, 02:00 → 03:00 = 07:00Z) and
//     first Sunday of November (1.11, 02:00 → 01:00 = 06:00Z).
//   They throw outside 2026. `DeviceTimeZone` is never used, so results do
//   not depend on the test machine's zone.
import 'package:gann_core/gann_core.dart'
    show
        cellDate,
        cellMoment,
        localWallClock,
        todayCellInDatesMode,
        nowCellInDateTimeMode,
        LocalTimeZone,
        OffsetDateTime;
import 'package:test/test.dart';

typedef _Ymd = (int, int, int);
typedef _Clock = (int, int, int, int, int);

// ---------------------------------------------------------------------------
// Test-local zones.

/// A 2026 zone with one summer period [start, end).
final class _Zone2026 implements LocalTimeZone {
  const _Zone2026(this.standard, this.summer, this.start, this.end);

  final int standard;
  final int summer;
  final DateTime start;
  final DateTime end;

  @override
  int offsetMinutesAt(DateTime utc) {
    if (!utc.isUtc) throw ArgumentError.value(utc, 'utc', 'must be UTC');
    if (utc.isBefore(DateTime.utc(2026)) || !utc.isBefore(DateTime.utc(2027))) {
      throw StateError('fake 2026 zone used for $utc');
    }
    return !utc.isBefore(start) && utc.isBefore(end) ? summer : standard;
  }
}

final _israel2026 = _Zone2026(
  120,
  180,
  DateTime.utc(2026, 3, 27),
  DateTime.utc(2026, 10, 24, 23),
);
final _newYork2026 = _Zone2026(
  -300,
  -240,
  DateTime.utc(2026, 3, 8, 7),
  DateTime.utc(2026, 11, 1, 6),
);

final class _Fixed implements LocalTimeZone {
  const _Fixed(this.offsetMinutes);

  final int offsetMinutes;

  @override
  int offsetMinutesAt(DateTime utc) {
    if (!utc.isUtc) throw ArgumentError.value(utc, 'utc', 'must be UTC');
    return offsetMinutes;
  }
}

// ---------------------------------------------------------------------------
// Test-local Gregorian calendar (records, no DateTime date arithmetic).

bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

int _daysInMonth(int y, int m) => switch (m) {
  2 => _isLeap(y) ? 29 : 28,
  4 || 6 || 9 || 11 => 30,
  _ => 31,
};

_Ymd _nextDay(_Ymd date) {
  final (y, m, d) = date;
  if (d < _daysInMonth(y, m)) return (y, m, d + 1);
  if (m < 12) return (y, m + 1, 1);
  return (y + 1, 1, 1);
}

/// Days since 1970-01-01 (Howard Hinnant, "days_from_civil").
int _dayNumber(_Ymd date) {
  var (y, m, d) = date;
  if (m <= 2) y -= 1;
  final era = (y >= 0 ? y : y - 399) ~/ 400;
  final yoe = y - era * 400;
  final doy = (153 * (m > 2 ? m - 3 : m + 9) + 2) ~/ 5 + d - 1;
  final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
  return era * 146097 + doe - 719468;
}

_Ymd _dateOf(DateTime carrier) => (carrier.year, carrier.month, carrier.day);

/// The local clock of [utc] in [zone], computed here (not via production).
_Clock _clockOf(DateTime utc, LocalTimeZone zone) {
  final l = utc.add(Duration(minutes: zone.offsetMinutesAt(utc)));
  return (l.year, l.month, l.day, l.hour, l.minute);
}

/// What production displays for [utc] in [zone].
_Clock _shown(DateTime utc, LocalTimeZone zone) {
  final w = localWallClock(utc, zone);
  return (w.year, w.month, w.day, w.hour, w.minute);
}

OffsetDateTime _at(String iso) => OffsetDateTime.parse(iso);

/// Mismatches between `cellDate(anchor, 1..cells)` and the `_nextDay` chain
/// from [first]; empty when every cell is right.
List<String> _chainMismatches(OffsetDateTime anchor, _Ymd first, int cells) {
  final bad = <String>[];
  var expected = first;
  for (var n = 1; n <= cells; n++) {
    final actual = _dateOf(cellDate(anchor, n));
    if (actual != expected) bad.add('cell $n: $actual, expected $expected');
    expected = _nextDay(expected);
  }
  return bad;
}

/// Every 30 minutes from 36 h before to 36 h after [transition].
Iterable<DateTime> _sweep(DateTime transition) sync* {
  for (var m = -36 * 60; m <= 36 * 60; m += 30) {
    yield transition.add(Duration(minutes: m));
  }
}

const _fullSquare = 61 * 61; // 3,721 cells, the largest square

void main() {
  // Anchors (reference values in the plan).
  final dIl = _at('2026-03-20T00:00+02:00');
  final dNy = _at('2026-10-30T23:30-04:00');
  final dtIlSpring = _at('2026-03-26T20:00+02:00');
  final dtIlAutumn = _at('2026-10-24T20:00+03:00');
  final dtNySpring = _at('2026-03-07T20:00-05:00');
  final dtNyAutumn = _at('2026-10-31T20:00-04:00');

  group('oracle self-check', () {
    test('leap rule and month lengths', () {
      expect(_isLeap(2024), isTrue);
      expect(_isLeap(2000), isTrue);
      expect(_isLeap(2026), isFalse);
      expect(_isLeap(2100), isFalse);
      expect(_isLeap(1900), isFalse);
      expect(_daysInMonth(2024, 2), 29);
      expect(_daysInMonth(2100, 2), 28);
      expect(_daysInMonth(2026, 4), 30);
      expect(_daysInMonth(2026, 12), 31);
    });

    test('day numbers and successors', () {
      expect(_dayNumber((1970, 1, 1)), 0);
      expect(_dayNumber((2000, 3, 1)), 11017);
      expect(_nextDay((2024, 2, 28)), (2024, 2, 29));
      expect(_nextDay((2024, 2, 29)), (2024, 3, 1));
      expect(_nextDay((2100, 2, 28)), (2100, 3, 1));
      expect(_nextDay((2026, 12, 31)), (2027, 1, 1));
    });
  });

  group('anchor cell is the anchor date', () {
    test('dates mode: cell 1 is the anchor’s own calendar date', () {
      final cases = {
        '2026-03-20T00:00+02:00': (2026, 3, 20),
        '2026-10-30T23:30-04:00': (2026, 10, 30), // UTC date is 31.10
        '2024-02-25T00:00+02:00': (2024, 2, 25),
        '2026-02-25T00:00+02:00': (2026, 2, 25),
        '2100-02-27T00:00+02:00': (2100, 2, 27),
        '2000-02-28T00:00+02:00': (2000, 2, 28),
      };
      cases.forEach((iso, expected) {
        expect(_dateOf(cellDate(_at(iso), 1)), expected, reason: iso);
      });
    });

    test('date-and-time mode: cell 1 is the anchor instant and wall time', () {
      final cases = [
        (
          dtIlSpring,
          _israel2026,
          DateTime.utc(2026, 3, 26, 18),
          (2026, 3, 26, 20, 0),
        ),
        (
          dtIlAutumn,
          _israel2026,
          DateTime.utc(2026, 10, 24, 17),
          (2026, 10, 24, 20, 0),
        ),
        (
          dtNySpring,
          _newYork2026,
          DateTime.utc(2026, 3, 8, 1),
          (2026, 3, 7, 20, 0),
        ),
        (
          dtNyAutumn,
          _newYork2026,
          DateTime.utc(2026, 11, 1),
          (2026, 10, 31, 20, 0),
        ),
      ];
      for (final (anchor, zone, instant, wall) in cases) {
        final cell1 = cellMoment(anchor, 1, stepHours: 4);
        expect(cell1, instant);
        expect(_shown(cell1, zone), wall);
      }
    });
  });

  group('dates mode across DST: calendar days, none skipped or duplicated', () {
    test('Israel spring (27.3.2026)', () {
      expect([1, 7, 8, 9, 81].map((n) => _dateOf(cellDate(dIl, n))).toList(), [
        (2026, 3, 20),
        (2026, 3, 26),
        (2026, 3, 27),
        (2026, 3, 28),
        (2026, 6, 8),
      ]);
    });

    test('New York autumn (1.11.2026), late-evening anchor', () {
      expect(
        [1, 2, 3, 4, 3721].map((n) => _dateOf(cellDate(dNy, n))).toList(),
        [
          (2026, 10, 30),
          (2026, 10, 31),
          (2026, 11, 1),
          (2026, 11, 2),
          (2037, 1, 5),
        ],
      );
    });

    test('every cell of a 61×61 square follows the calendar', () {
      expect(_chainMismatches(dIl, (2026, 3, 20), _fullSquare), isEmpty);
      expect(_chainMismatches(dNy, (2026, 10, 30), _fullSquare), isEmpty);
    });
  });

  group('date-and-time mode across DST: the documented one-hour jump', () {
    List<_Clock> shownCells(OffsetDateTime anchor, LocalTimeZone zone) => [
      for (var n = 1; n <= 4; n++)
        _shown(cellMoment(anchor, n, stepHours: 4), zone),
    ];

    test('Israel spring: 00:00 → 05:00', () {
      expect(shownCells(dtIlSpring, _israel2026), [
        (2026, 3, 26, 20, 0),
        (2026, 3, 27, 0, 0),
        (2026, 3, 27, 5, 0),
        (2026, 3, 27, 9, 0),
      ]);
    });

    test('Israel autumn: 00:00 → 03:00', () {
      expect(shownCells(dtIlAutumn, _israel2026), [
        (2026, 10, 24, 20, 0),
        (2026, 10, 25, 0, 0),
        (2026, 10, 25, 3, 0),
        (2026, 10, 25, 7, 0),
      ]);
    });

    test('New York spring: 00:00 → 05:00', () {
      expect(shownCells(dtNySpring, _newYork2026), [
        (2026, 3, 7, 20, 0),
        (2026, 3, 8, 0, 0),
        (2026, 3, 8, 5, 0),
        (2026, 3, 8, 9, 0),
      ]);
    });

    test('New York autumn: 00:00 → 03:00', () {
      expect(shownCells(dtNyAutumn, _newYork2026), [
        (2026, 10, 31, 20, 0),
        (2026, 11, 1, 0, 0),
        (2026, 11, 1, 3, 0),
        (2026, 11, 1, 7, 0),
      ]);
    });

    test('169 cells: absolute 4-hour steps, exactly one displayed jump', () {
      final cases = [
        (dtIlSpring, _israel2026, 300),
        (dtIlAutumn, _israel2026, 180),
        (dtNySpring, _newYork2026, 300),
        (dtNyAutumn, _newYork2026, 180),
      ];
      for (final (anchor, zone, jump) in cases) {
        final reason = '${anchor.toIso8601String()} jump $jump';
        final displayedGaps = <int>[];
        for (var n = 1; n < 169; n++) {
          final a = cellMoment(anchor, n, stepHours: 4);
          final b = cellMoment(anchor, n + 1, stepHours: 4);
          expect(
            b.difference(a),
            const Duration(hours: 4),
            reason: '$reason n=$n',
          );
          displayedGaps.add(
            localWallClock(
              b,
              zone,
            ).difference(localWallClock(a, zone)).inMinutes,
          );
        }
        expect(displayedGaps.where((g) => g != 240).toList(), [
          jump,
        ], reason: reason);
      }
    });

    test('travel: the same instant shown in another zone', () {
      expect(_shown(cellMoment(dtIlAutumn, 1, stepHours: 4), _newYork2026), (
        2026,
        10,
        24,
        13,
        0,
      ));
    });
  });

  group(
    'R-4: with 1-hour steps the transition hour shows twice or not at all',
    () {
      List<_Clock> hourly(String iso, LocalTimeZone zone, int cells) => [
        for (var n = 1; n <= cells; n++)
          _shown(cellMoment(_at(iso), n, stepHours: 1), zone),
      ];

      test('Israel autumn: 01:00 twice', () {
        expect(hourly('2026-10-24T23:00+03:00', _israel2026, 5), [
          (2026, 10, 24, 23, 0),
          (2026, 10, 25, 0, 0),
          (2026, 10, 25, 1, 0),
          (2026, 10, 25, 1, 0),
          (2026, 10, 25, 2, 0),
        ]);
      });

      test('Israel spring: 02:00 never shown', () {
        expect(hourly('2026-03-26T23:00+02:00', _israel2026, 4), [
          (2026, 3, 26, 23, 0),
          (2026, 3, 27, 0, 0),
          (2026, 3, 27, 1, 0),
          (2026, 3, 27, 3, 0),
        ]);
      });

      test('New York spring: 02:00 never shown', () {
        expect(hourly('2026-03-07T23:00-05:00', _newYork2026, 4), [
          (2026, 3, 7, 23, 0),
          (2026, 3, 8, 0, 0),
          (2026, 3, 8, 1, 0),
          (2026, 3, 8, 3, 0),
        ]);
      });

      test('New York autumn: 01:00 twice', () {
        expect(hourly('2026-10-31T23:00-04:00', _newYork2026, 5), [
          (2026, 10, 31, 23, 0),
          (2026, 11, 1, 0, 0),
          (2026, 11, 1, 1, 0),
          (2026, 11, 1, 1, 0),
          (2026, 11, 1, 2, 0),
        ]);
      });
    },
  );

  group('today is marked exactly across DST', () {
    test('dates mode, Israel: 00:30 local either side of the switch', () {
      expect(
        todayCellInDatesMode(
          dIl,
          DateTime.utc(2026, 3, 26, 22, 30),
          _israel2026,
        ),
        8,
      );
      expect(
        todayCellInDatesMode(
          dIl,
          DateTime.utc(2026, 3, 27, 21, 30),
          _israel2026,
        ),
        9,
      );
    });

    test('dates mode, New York: local midnight behind UTC', () {
      final cases = {
        DateTime.utc(2026, 10, 30, 2): null, // 29.10 22:00, before the anchor
        DateTime.utc(2026, 10, 31, 3): 1, // 30.10 23:00
        DateTime.utc(2026, 10, 31, 3, 59): 1, // 30.10 23:59
        DateTime.utc(2026, 10, 31, 4): 2, // 31.10 00:00
        DateTime.utc(2026, 11, 1, 4, 30): 3, // 1.11 00:30 EDT
        DateTime.utc(2026, 11, 2, 4, 30): 3, // 1.11 23:30 EST
        DateTime.utc(2026, 11, 2, 5, 30): 4, // 2.11 00:30 EST
      };
      cases.forEach((now, expected) {
        expect(
          todayCellInDatesMode(dNy, now, _newYork2026),
          expected,
          reason: '$now',
        );
      });
    });

    test('dates mode, travel: the anchor keeps its own date', () {
      // Anchor 20.3 00:00 +02:00 is 19.3 18:00 in New York; now is 20.3 12:00
      // in New York, so today is the anchor's own date — cell 1.
      expect(
        todayCellInDatesMode(dIl, DateTime.utc(2026, 3, 20, 16), _newYork2026),
        1,
      );
    });

    test('date-and-time mode, Israel: block boundaries across the switch', () {
      int? cell(DateTime now) =>
          nowCellInDateTimeMode(dtIlSpring, now, stepHours: 4);
      expect(cell(DateTime.utc(2026, 3, 27, 1, 59)), 2);
      expect(cell(DateTime.utc(2026, 3, 27, 2)), 3);
      expect(cell(DateTime.utc(2026, 3, 27, 3)), 3);
    });

    test('dates mode, every 30 minutes over 72 hours around each switch', () {
      final cases = [
        (dIl, (2026, 3, 20), _israel2026, DateTime.utc(2026, 3, 27)),
        (dNy, (2026, 10, 30), _newYork2026, DateTime.utc(2026, 11, 1, 6)),
      ];
      for (final (anchor, anchorDate, zone, transition) in cases) {
        for (final now in _sweep(transition)) {
          final (y, m, d, _, _) = _clockOf(now, zone);
          final days = _dayNumber((y, m, d)) - _dayNumber(anchorDate);
          expect(
            todayCellInDatesMode(anchor, now, zone),
            days < 0 ? null : days + 1,
            reason: '$now',
          );
        }
      }
    });

    test(
      'date-and-time mode, every 30 minutes over 72 hours around each switch',
      () {
        const blockMicros = 4 * Duration.microsecondsPerHour;
        final cases = [
          (
            dtIlSpring,
            DateTime.utc(2026, 3, 26, 18),
            DateTime.utc(2026, 3, 27),
          ),
          (dtNyAutumn, DateTime.utc(2026, 11, 1), DateTime.utc(2026, 11, 1, 6)),
        ];
        for (final (anchor, anchorInstant, transition) in cases) {
          for (final now in _sweep(transition)) {
            final elapsed =
                now.microsecondsSinceEpoch -
                anchorInstant.microsecondsSinceEpoch;
            expect(
              nowCellInDateTimeMode(anchor, now, stepHours: 4),
              elapsed < 0 ? null : elapsed ~/ blockMicros + 1,
              reason: '$now',
            );
          }
        }
      },
    );
  });
  group('leap years: Feb 29 present exactly when Gregorian rules say', () {
    const plus2 = _Fixed(120);

    test('dates mode: 2024 and 2000 have Feb 29; 2026 and 2100 do not', () {
      List<_Ymd> dates(String iso, List<int> cells) => [
        for (final n in cells) _dateOf(cellDate(_at(iso), n)),
      ];
      expect(dates('2024-02-25T00:00+02:00', [1, 5, 6]), [
        (2024, 2, 25),
        (2024, 2, 29),
        (2024, 3, 1),
      ]);
      expect(dates('2026-02-25T00:00+02:00', [4, 5]), [
        (2026, 2, 28),
        (2026, 3, 1),
      ]);
      expect(dates('2100-02-27T00:00+02:00', [2, 3]), [
        (2100, 2, 28),
        (2100, 3, 1),
      ]);
      expect(dates('2000-02-28T00:00+02:00', [2, 3]), [
        (2000, 2, 29),
        (2000, 3, 1),
      ]);
    });

    test('every cell of a 61×61 square across 2024–2034 and 2096–2106', () {
      final a = _at('2023-12-01T00:00+02:00');
      final b = _at('2096-01-01T00:00+02:00');
      expect(_dateOf(cellDate(a, _fullSquare)), (2034, 2, 6));
      expect(_dateOf(cellDate(b, _fullSquare)), (2106, 3, 10));
      expect(_chainMismatches(a, (2023, 12, 1), _fullSquare), isEmpty);
      expect(_chainMismatches(b, (2096, 1, 1), _fullSquare), isEmpty);
    });

    test('date-and-time mode crosses Feb 29', () {
      final anchor = _at('2024-02-28T16:00+02:00');
      expect(
        [1, 3, 8, 9]
            .map((n) => _shown(cellMoment(anchor, n, stepHours: 4), plus2))
            .toList(),
        [
          (2024, 2, 28, 16, 0),
          (2024, 2, 29, 0, 0),
          (2024, 2, 29, 20, 0),
          (2024, 3, 1, 0, 0),
        ],
      );
    });

    test('today across Feb 29', () {
      final leap = _at('2024-02-01T00:00+02:00');
      expect(
        todayCellInDatesMode(leap, DateTime.utc(2024, 2, 29, 10), plus2),
        29,
      );
      expect(
        todayCellInDatesMode(leap, DateTime.utc(2024, 3, 1, 10), plus2),
        30,
      );
      // 00:30 local on 29.2 while the UTC date is still 28.2.
      expect(
        todayCellInDatesMode(leap, DateTime.utc(2024, 2, 28, 22, 30), plus2),
        29,
      );
      final common = _at('2026-02-01T00:00+02:00');
      expect(
        todayCellInDatesMode(common, DateTime.utc(2026, 3, 1, 10), plus2),
        29,
      );
    });
  });
}
