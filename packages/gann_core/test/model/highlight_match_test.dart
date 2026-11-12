import 'dart:convert';

import 'package:gann_core/gann_core.dart';
import 'package:test/test.dart';

HighlightMatch roundTrip(HighlightMatch m) =>
    HighlightMatch.fromJson(jsonDecode(jsonEncode(m.toJson())));

void main() {
  group('HighlightMatch', () {
    test('round-trips both kinds through JSON', () {
      final angles = AnglesMatch([0, 90, 180, 270]);
      final multiple = MultipleOfMatch(22.5);

      expect(roundTrip(angles), angles);
      expect(roundTrip(multiple), multiple);
      expect(angles.toJson(), {
        'type': 'angles',
        'degrees': [0.0, 90.0, 180.0, 270.0],
      });
      expect(multiple.toJson(), {'type': 'multipleOf', 'degrees': 22.5});
    });

    test('decodes integer-valued degrees', () {
      expect(
        HighlightMatch.fromJson({
          'type': 'angles',
          'degrees': [0, 90],
        }),
        AnglesMatch([0.0, 90.0]),
      );
      expect(
        HighlightMatch.fromJson({'type': 'multipleOf', 'degrees': 22}),
        MultipleOfMatch(22.0),
      );
    });

    test('fromJson rejects malformed input with FormatException', () {
      final bad = <Object?>[
        null,
        'angles',
        {'degrees': 22.5},
        {'type': 'spiral', 'degrees': 22.5},
        {'type': 'multipleOf'},
        {'type': 'multipleOf', 'degrees': '22.5'},
        {'type': 'angles', 'degrees': 90},
        {
          'type': 'angles',
          'degrees': [90, 'x'],
        },
        {'type': 'angles', 'degrees': <Object?>[]},
        {
          'type': 'angles',
          'degrees': [360],
        },
        {'type': 'multipleOf', 'degrees': 0},
      ];

      for (final json in bad) {
        expect(
          () => HighlightMatch.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });

    test('constructors reject out-of-range degrees', () {
      expect(() => AnglesMatch([]), throwsArgumentError);
      expect(() => AnglesMatch([360]), throwsArgumentError);
      expect(() => AnglesMatch([-1]), throwsArgumentError);
      expect(() => AnglesMatch([double.nan]), throwsArgumentError);
      expect(() => MultipleOfMatch(0), throwsArgumentError);
      expect(() => MultipleOfMatch(-22.5), throwsArgumentError);
      expect(() => MultipleOfMatch(double.infinity), throwsArgumentError);
    });

    test('copies and freezes its list', () {
      final source = [0.0, 90.0];
      final match = AnglesMatch(source);
      source.add(180);

      expect(match.degrees, [0.0, 90.0]);
      expect(() => match.degrees.add(45), throwsUnsupportedError);
    });
  });
}
