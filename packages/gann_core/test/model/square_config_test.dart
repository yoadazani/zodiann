import 'dart:convert';

import 'package:gann_core/gann_core.dart';
import 'package:test/test.dart';

final created = DateTime.utc(2026, 11, 1, 8);
final updated = DateTime.utc(2026, 11, 12, 9, 30);
final anchorIndia = OffsetDateTime(DateTime.utc(2026, 1, 1, 3, 30), 330);
final anchorNewfoundland = OffsetDateTime(DateTime.utc(2026, 7, 1, 12), -210);

SquareConfig config({
  String id = 'sq-1',
  String name = 'My square',
  SquareMode mode = SquareMode.numbers,
  OffsetDateTime? anchor,
  int stepHours = 4,
  int size = 9,
  List<HighlightRule>? highlights,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => SquareConfig(
  id: id,
  name: name,
  mode: mode,
  anchor: anchor,
  stepHours: stepHours,
  size: size,
  highlights: highlights,
  createdAt: createdAt ?? created,
  updatedAt: updatedAt ?? updated,
);

SquareConfig roundTrip(SquareConfig c) =>
    SquareConfig.fromJson(jsonDecode(jsonEncode(c.toJson())));

final customRule = HighlightRule(
  id: 'fifths',
  label: 'Fifths',
  match: MultipleOfMatch(72),
  colorToken: 'diag',
  priority: 1,
);

void main() {
  group('SquareConfig', () {
    test('a new SquareConfig gets the three default highlight rules in priority order', () {
      final c = config();

      expect(c.highlights, defaultHighlightRules);
      expect(c.highlights.map((r) => r.priority), [1, 2, 3]);
    });

    test('defaults to spiral left + clockwise and a 4-hour step', () {
      final c = SquareConfig(
        id: 'a',
        name: 'b',
        mode: SquareMode.numbers,
        size: 9,
        createdAt: created,
        updatedAt: updated,
      );

      expect(c.spiralStart, SpiralStart.left);
      expect(c.spiralRotation, SpiralRotation.cw);
      expect(c.stepHours, 4);
    });

    test('round-trips through JSON without data loss', () {
      final configs = [
        config(),
        config(mode: SquareMode.dates, anchor: anchorIndia, size: 61),
        config(
          mode: SquareMode.datetime,
          anchor: anchorNewfoundland,
          stepHours: 6,
          size: 3,
          highlights: [customRule],
        ),
      ];

      for (final c in configs) {
        expect(roundTrip(c), c);
      }
      expect(roundTrip(configs[1]).anchor!.offsetMinutes, 330);
      expect(roundTrip(configs[2]).anchor!.offsetMinutes, -210);
      expect(
        roundTrip(configs[2]).anchor!.wallClock,
        anchorNewfoundland.wallClock,
      );
    });

    test('accepts sizes 3 and 61 and rejects 1, 63, even and 0', () {
      expect(config(size: 3).size, 3);
      expect(config(size: 61).size, 61);
      for (final bad in [1, 63, 10, 0, -9]) {
        expect(() => config(size: bad), throwsArgumentError, reason: '$bad');
      }
    });

    test('anchor is present exactly when the mode is a date mode', () {
      expect(
        () => config(mode: SquareMode.numbers, anchor: anchorIndia),
        throwsArgumentError,
      );
      expect(() => config(mode: SquareMode.dates), throwsArgumentError);
      expect(() => config(mode: SquareMode.datetime), throwsArgumentError);
    });

    test('rejects invalid scalar fields', () {
      expect(() => config(stepHours: 0), throwsArgumentError);
      expect(() => config(id: ''), throwsArgumentError);
      expect(() => config(name: ''), throwsArgumentError);
      expect(() => config(createdAt: DateTime(2026)), throwsArgumentError);
      expect(() => config(updatedAt: DateTime(2026)), throwsArgumentError);
      expect(
        () => config(updatedAt: created.subtract(const Duration(seconds: 1))),
        throwsArgumentError,
      );
    });

    test('rejects duplicate highlight ids', () {
      expect(
        () => config(highlights: [customRule, customRule]),
        throwsArgumentError,
      );
    });

    test('fromJson rejects malformed input with FormatException', () {
      final good = config(mode: SquareMode.dates, anchor: anchorIndia).toJson();
      final bad = <Object?>[
        null,
        'square',
        {...good, 'mode': 'sidereal'},
        {...good}..remove('size'),
        {...good, 'size': '9'},
        {...good, 'size': 10},
        {...good, 'anchor': '2026-01-01T09:00:00'},
        {...good, 'anchor': null},
        {...good, 'createdAt': '2026-11-01T08:00:00'},
        {...good, 'highlights': 'none'},
        {
          ...good,
          'highlights': [
            {'id': 'x'},
          ],
        },
      ];

      for (final json in bad) {
        expect(
          () => SquareConfig.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });

    test('fromJson requires the anchor key (null allowed) and strict UTC timestamps', () {
      final numbers = config().toJson();

      expect(SquareConfig.fromJson(numbers), config());
      final bad = <Map<String, Object?>>[
        {...numbers}..remove('anchor'),
        {...numbers, 'createdAt': '2026-02-30T00:00:00Z'},
        {...numbers, 'createdAt': '2026-11-01T10:00:00+02:00'},
        {...numbers, 'updatedAt': '2026-11-12T09:30:00'},
      ];
      for (final json in bad) {
        expect(
          () => SquareConfig.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });

    test('copies and freezes its highlights list', () {
      final source = [customRule];
      final c = config(highlights: source);
      source.add(defaultHighlightRules.first);

      expect(c.highlights, [customRule]);
      expect(() => c.highlights.add(customRule), throwsUnsupportedError);
    });

    test('has value equality over every field', () {
      expect(config(), config());
      expect(config().hashCode, config().hashCode);
      expect(config(), isNot(config(name: 'Other')));
      expect(config(), isNot(config(highlights: [customRule])));
    });
  });
}
