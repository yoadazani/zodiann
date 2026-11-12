import 'package:gann_core/gann_core.dart';
import 'package:test/test.dart';

/// A fake zone mirroring Israel 2026: +02:00 until 2026-03-27T00:00Z
/// (02:00 local → 03:00), +03:00 until 2026-10-24T23:00Z (02:00 local →
/// 01:00), then +02:00. Keeps DST tests independent of the machine's zone.
final class _DstZone implements LocalTimeZone {
  static final _springForward = DateTime.utc(2026, 3, 27);
  static final _fallBack = DateTime.utc(2026, 10, 24, 23);

  @override
  int offsetMinutesAt(DateTime utc) {
    if (!utc.isUtc) throw ArgumentError.value(utc, 'utc', 'must be UTC');
    if (utc.isBefore(_springForward)) return 120;
    if (utc.isBefore(_fallBack)) return 180;
    return 120;
  }
}

OffsetDateTime at(String iso) => OffsetDateTime.parse(iso);

/// (date, HH:MM-as-record) of a moment shown in [zone].
(DateTime, int, int) local(DateTime utc, LocalTimeZone zone) {
  final w = localWallClock(utc, zone);
  return (DateTime.utc(w.year, w.month, w.day), w.hour, w.minute);
}

void main() {
  final israelNov = FixedOffsetTimeZone(120);
  final designAnchor = at('2026-11-01T00:00+02:00');

  group('LocalTimeZone', () {
    test(
      'FixedOffsetTimeZone returns its offset; rejects offsets beyond ±1080',
      () {
        expect(
          FixedOffsetTimeZone(120).offsetMinutesAt(DateTime.utc(2026)),
          120,
        );
        expect(
          FixedOffsetTimeZone(-330).offsetMinutesAt(DateTime.utc(2026)),
          -330,
        );
        expect(() => FixedOffsetTimeZone(1081), throwsArgumentError);
        expect(() => FixedOffsetTimeZone(-1081), throwsArgumentError);
      },
    );

    test('DeviceTimeZone matches DateTime.toLocal for sample instants', () {
      for (final utc in [
        DateTime.utc(2026, 1, 15, 12),
        DateTime.utc(2026, 7, 15, 12),
        DateTime.utc(1999, 12, 31, 23, 59),
      ]) {
        expect(
          const DeviceTimeZone().offsetMinutesAt(utc),
          utc.toLocal().timeZoneOffset.inMinutes,
          reason: '$utc',
        );
      }
    });

    test('rejects non-UTC input', () {
      expect(
        () => FixedOffsetTimeZone(120).offsetMinutesAt(DateTime(2026)),
        throwsArgumentError,
      );
      expect(
        () => const DeviceTimeZone().offsetMinutesAt(DateTime(2026)),
        throwsArgumentError,
      );
      expect(
        () => localWallClock(DateTime(2026), FixedOffsetTimeZone(0)),
        throwsArgumentError,
      );
    });
  });

  group('numbers mode', () {
    test('cellNumber(n) == n, rejects n < 1', () {
      expect(cellNumber(1), 1);
      expect(cellNumber(52), 52);
      expect(() => cellNumber(0), throwsArgumentError);
    });
  });

  group('dates mode', () {
    test('the anchor cell is the anchor date', () {
      expect(
        cellDate(at('2026-04-15T00:00+03:00'), 1),
        DateTime.utc(2026, 4, 15),
      );
    });

    test('design reference: cell 139 is 31.8.26', () {
      expect(
        cellDate(at('2026-04-15T00:00+03:00'), 139),
        DateTime.utc(2026, 8, 31),
      );
    });

    test('consecutive calendar days, across a month and a year end', () {
      final anchor = at('2026-12-30T00:00+02:00');
      expect(
        [for (var n = 1; n <= 3; n++) cellDate(anchor, n)],
        [
          DateTime.utc(2026, 12, 30),
          DateTime.utc(2026, 12, 31),
          DateTime.utc(2027, 1, 1),
        ],
      );
    });

    test('leap year includes Feb 29; a common year does not', () {
      final leap = at('2024-02-27T00:00+02:00');
      expect(
        [for (var n = 1; n <= 4; n++) cellDate(leap, n)],
        [
          DateTime.utc(2024, 2, 27),
          DateTime.utc(2024, 2, 28),
          DateTime.utc(2024, 2, 29),
          DateTime.utc(2024, 3, 1),
        ],
      );
      expect(
        cellDate(at('2026-02-27T00:00+02:00'), 3),
        DateTime.utc(2026, 3, 1),
      );
    });

    test('is unaffected by DST', () {
      final anchor = at('2026-03-25T00:00+02:00');
      expect(
        [for (var n = 1; n <= 5; n++) cellDate(anchor, n)],
        [for (var d = 25; d <= 29; d++) DateTime.utc(2026, 3, d)],
      );
    });

    test('uses the anchor’s own calendar date, not UTC', () {
      // UTC instant is 2026-03-24T21:30Z, but the anchor's own date is 25.3.
      expect(
        cellDate(at('2026-03-25T00:30+03:00'), 1),
        DateTime.utc(2026, 3, 25),
      );
    });

    test('rejects n < 1', () {
      expect(() => cellDate(designAnchor, 0), throwsArgumentError);
    });
  });

  group('date-and-time mode', () {
    test('design reference: 1.11.2026 00:00 anchor', () {
      DateTime moment(int n) => cellMoment(designAnchor, n, stepHours: 4);
      expect(local(moment(1), israelNov), (DateTime.utc(2026, 11, 1), 0, 0));
      expect(local(moment(2), israelNov), (DateTime.utc(2026, 11, 1), 4, 0));
      expect(local(moment(52), israelNov), (DateTime.utc(2026, 11, 9), 12, 0));
      expect(local(moment(169), israelNov), (DateTime.utc(2026, 11, 29), 0, 0));
    });

    test('spring DST: the displayed hour jumps forward by one', () {
      final anchor = at('2026-03-26T20:00+02:00');
      final zone = _DstZone();
      expect(
        [
          for (var n = 1; n <= 4; n++)
            local(cellMoment(anchor, n, stepHours: 4), zone),
        ],
        [
          (DateTime.utc(2026, 3, 26), 20, 0),
          (DateTime.utc(2026, 3, 27), 0, 0),
          (DateTime.utc(2026, 3, 27), 5, 0), // not 04:00 — the documented jump
          (DateTime.utc(2026, 3, 27), 9, 0),
        ],
      );
    });

    test('autumn DST: the displayed hour jumps back by one', () {
      final anchor = at('2026-10-24T20:00+03:00');
      final zone = _DstZone();
      expect(
        [
          for (var n = 1; n <= 4; n++)
            local(cellMoment(anchor, n, stepHours: 4), zone),
        ],
        [
          (DateTime.utc(2026, 10, 24), 20, 0),
          (DateTime.utc(2026, 10, 25), 0, 0),
          (DateTime.utc(2026, 10, 25), 3, 0), // not 04:00 — the documented jump
          (DateTime.utc(2026, 10, 25), 7, 0),
        ],
      );
    });

    test(
      'travel: date-and-time cells show the anchor instant in the device zone',
      () {
        final london = FixedOffsetTimeZone(0);
        expect(local(cellMoment(designAnchor, 1, stepHours: 4), london), (
          DateTime.utc(2026, 10, 31),
          22,
          0,
        ));
        expect(local(cellMoment(designAnchor, 2, stepHours: 4), london), (
          DateTime.utc(2026, 11, 1),
          2,
          0,
        ));
      },
    );

    test('honours stepHours', () {
      expect(
        cellMoment(designAnchor, 2, stepHours: 6),
        designAnchor.instant.add(const Duration(hours: 6)),
      );
    });

    test('rejects stepHours < 1 and n < 1', () {
      expect(
        () => cellMoment(designAnchor, 2, stepHours: 0),
        throwsArgumentError,
      );
      expect(
        () => cellMoment(designAnchor, 0, stepHours: 4),
        throwsArgumentError,
      );
    });
  });

  group('distance from the anchor (SQ-18)', () {
    test('days and absolute hours after the anchor', () {
      expect(daysAfterAnchor(139), 138);
      expect(hoursAfterAnchor(52, stepHours: 4), 204);
      expect(daysAfterAnchor(1), 0);
      expect(hoursAfterAnchor(1, stepHours: 4), 0);
    });

    test('rejects n < 1 and stepHours < 1', () {
      expect(() => daysAfterAnchor(0), throwsArgumentError);
      expect(() => hoursAfterAnchor(0, stepHours: 4), throwsArgumentError);
      expect(() => hoursAfterAnchor(2, stepHours: 0), throwsArgumentError);
    });
  });

  group('overflow', () {
    test("rejects results beyond DateTime's range (no silent overflow)", () {
      expect(() => cellDate(designAnchor, 3000000000), throwsArgumentError);
      expect(() => cellDate(designAnchor, 200000002), throwsArgumentError);
      expect(
        () => cellMoment(designAnchor, 1000000001, stepHours: 4),
        throwsArgumentError,
      );
      expect(
        () => cellMoment(designAnchor, 1 << 31, stepHours: 1 << 30),
        throwsArgumentError,
      );
      expect(
        () => hoursAfterAnchor(1 << 31, stepHours: 1 << 30),
        throwsArgumentError,
      );
      final farAnchor = OffsetDateTime.parse('+275000-01-01T00:00Z');
      expect(() => cellDate(farAnchor, 50000001), throwsArgumentError);
      expect(
        () => cellMoment(farAnchor, 600000001, stepHours: 4),
        throwsArgumentError,
      );
    });
  });

  group('today’s cell', () {
    test(
      'dates mode uses the local date (00:30 local, UTC date one day earlier)',
      () {
        expect(
          todayCellInDatesMode(
            at('2026-03-25T00:00+02:00'),
            DateTime.utc(2026, 3, 27, 21, 30),
            _DstZone(),
          ),
          4,
        );
      },
    );

    test('dates mode across Feb 29: leap year 4, common year 3', () {
      expect(
        todayCellInDatesMode(
          at('2024-02-27T00:00+02:00'),
          DateTime.utc(2024, 3, 1, 10),
          israelNov,
        ),
        4,
      );
      expect(
        todayCellInDatesMode(
          at('2026-02-27T00:00+02:00'),
          DateTime.utc(2026, 3, 1, 10),
          israelNov,
        ),
        3,
      );
    });

    test('dates mode design reference: cell 209', () {
      expect(
        todayCellInDatesMode(
          at('2026-04-15T00:00+03:00'),
          DateTime.utc(2026, 11, 9, 10),
          israelNov,
        ),
        209,
      );
    });

    test('dates mode: the anchor day is cell 1; before the anchor is null', () {
      final anchor = at('2026-11-01T00:00+02:00');
      expect(
        todayCellInDatesMode(anchor, DateTime.utc(2026, 11, 1, 10), israelNov),
        1,
      );
      expect(
        todayCellInDatesMode(anchor, DateTime.utc(2026, 10, 31, 10), israelNov),
        isNull,
      );
    });

    test(
      "travel: dates mode and its today cell keep the anchor's own date",
      () {
        final anchor = at('2026-03-25T00:30+03:00');
        final london = FixedOffsetTimeZone(0);
        expect(cellDate(anchor, 1), DateTime.utc(2026, 3, 25));
        expect(
          todayCellInDatesMode(anchor, DateTime.utc(2026, 3, 25, 12), london),
          1,
        );
        expect(
          todayCellInDatesMode(anchor, DateTime.utc(2026, 3, 24, 23), london),
          isNull,
        );
      },
    );

    test("the dates-mode today cell displays today's local date", () {
      final anchor = at('2026-03-25T00:00+02:00');
      final zone = _DstZone();
      final cases = {
        DateTime.utc(2026, 3, 27, 21, 30): 4,
        DateTime.utc(2026, 3, 27, 20, 30): 3,
        DateTime.utc(2026, 10, 24, 22, 30): 215,
      };
      cases.forEach((now, expected) {
        final cell = todayCellInDatesMode(anchor, now, zone)!;
        expect(cell, expected, reason: '$now');
        final w = localWallClock(now, zone);
        expect(
          cellDate(anchor, cell),
          DateTime.utc(w.year, w.month, w.day),
          reason: '$now',
        );
      });
    });

    test('date-and-time mode: whole blocks elapsed + 1', () {
      DateTime after(Duration d) => designAnchor.instant.add(d);
      int? cell(DateTime now) =>
          nowCellInDateTimeMode(designAnchor, now, stepHours: 4);
      expect(cell(after(const Duration(hours: 204))), 52);
      expect(cell(after(const Duration(hours: 207, minutes: 59))), 52);
      expect(cell(after(const Duration(hours: 208))), 53);
      expect(cell(designAnchor.instant), 1);
    });

    test('date-and-time mode: before the anchor is null', () {
      for (final d in [
        const Duration(minutes: 1),
        const Duration(seconds: 30),
        const Duration(microseconds: 1),
      ]) {
        expect(
          nowCellInDateTimeMode(
            designAnchor,
            designAnchor.instant.subtract(d),
            stepHours: 4,
          ),
          isNull,
          reason: '−$d',
        );
      }
    });

    test('date-and-time mode honours stepHours', () {
      expect(
        nowCellInDateTimeMode(
          designAnchor,
          designAnchor.instant.add(const Duration(hours: 12)),
          stepHours: 6,
        ),
        3,
      );
    });

    test('date-and-time mode: huge stepHours does not overflow', () {
      final now = designAnchor.instant.add(const Duration(hours: 204));
      expect(
        nowCellInDateTimeMode(designAnchor, now, stepHours: 5124095576),
        1,
      );
      expect(nowCellInDateTimeMode(designAnchor, now, stepHours: 1 << 62), 1);
    });

    test('rejects non-UTC now and stepHours: 0', () {
      expect(
        () => todayCellInDatesMode(designAnchor, DateTime(2026), israelNov),
        throwsArgumentError,
      );
      expect(
        () => nowCellInDateTimeMode(designAnchor, DateTime(2026), stepHours: 4),
        throwsArgumentError,
      );
      expect(
        () => nowCellInDateTimeMode(
          designAnchor,
          designAnchor.instant,
          stepHours: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
