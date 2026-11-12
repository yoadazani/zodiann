import 'dart:convert';

import 'package:gann_core/gann_core.dart';
import 'package:test/test.dart';

HighlightRule rule({
  String id = 'r1',
  String label = 'Fifths',
  String colorToken = 'axis',
  int priority = 4,
}) => HighlightRule(
  id: id,
  label: label,
  match: MultipleOfMatch(72),
  colorToken: colorToken,
  priority: priority,
);

void main() {
  group('HighlightRule', () {
    test('round-trips through JSON', () {
      final r = rule();

      expect(HighlightRule.fromJson(jsonDecode(jsonEncode(r.toJson()))), r);
    });

    test('rejects empty id, label or colorToken', () {
      expect(() => rule(id: ''), throwsArgumentError);
      expect(() => rule(label: ''), throwsArgumentError);
      expect(() => rule(colorToken: ''), throwsArgumentError);
    });

    test('fromJson rejects malformed input with FormatException', () {
      final good = rule().toJson();
      final bad = <Object?>[
        null,
        [good],
        {...good, 'priority': '1'},
        {...good, 'priority': 1.5},
        {...good}..remove('match'),
        {...good, 'match': 'angles'},
        {...good, 'id': ''},
        {...good, 'colorToken': 7},
      ];

      for (final json in bad) {
        expect(
          () => HighlightRule.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });

    test('has value equality including the match', () {
      expect(rule(), rule());
      expect(rule().hashCode, rule().hashCode);
      expect(rule(), isNot(rule(priority: 5)));
      expect(
        rule(),
        isNot(
          HighlightRule(
            id: 'r1',
            label: 'Fifths',
            match: MultipleOfMatch(36),
            colorToken: 'axis',
            priority: 4,
          ),
        ),
      );
    });
  });

  group('defaultHighlightRules', () {
    test('are Axes, Diagonals, Eighths in priority order 1, 2, 3 with the spec angles and token colors', () {
      final [axes, diagonals, eighths] = defaultHighlightRules;

      expect(axes.id, 'axes');
      expect(axes.label, 'axes');
      expect(axes.match, AnglesMatch([0, 90, 180, 270]));
      expect(axes.colorToken, 'axis');
      expect(axes.priority, 1);

      expect(diagonals.id, 'diagonals');
      expect(diagonals.label, 'diagonals');
      expect(diagonals.match, AnglesMatch([45, 135, 225, 315]));
      expect(diagonals.colorToken, 'diag');
      expect(diagonals.priority, 2);

      expect(eighths.id, 'eighths');
      expect(eighths.label, 'eighths');
      expect(eighths.match, MultipleOfMatch(22.5));
      expect(eighths.colorToken, 'eighth');
      expect(eighths.priority, 3);
    });

    test('colors are token names, not hex', () {
      for (final r in defaultHighlightRules) {
        expect(r.colorToken.startsWith('#'), isFalse);
      }
    });

    test('is unmodifiable', () {
      expect(() => defaultHighlightRules.add(rule()), throwsUnsupportedError);
    });
  });
}
