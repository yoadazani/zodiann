import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('UtcRange', () {
    final a = DateTime.utc(1800, 1, 1);
    final b = DateTime.utc(2400, 1, 1);

    test('contains its start and end (inclusive)', () {
      final range = UtcRange(a, b);

      expect(range.contains(a), isTrue);
      expect(range.contains(b), isTrue);
    });

    test('excludes instants outside', () {
      final range = UtcRange(a, b);
      const tick = Duration(microseconds: 1);

      expect(range.contains(a.subtract(tick)), isFalse);
      expect(range.contains(b.add(tick)), isFalse);
    });

    test('allows a single-instant range', () {
      expect(UtcRange(a, a).contains(a), isTrue);
    });

    test('rejects end before start', () {
      expect(() => UtcRange(b, a), throwsArgumentError);
    });

    test('rejects non-UTC bounds', () {
      expect(() => UtcRange(DateTime(1800), b), throwsArgumentError);
      expect(() => UtcRange(a, DateTime(2400)), throwsArgumentError);
    });

    test('contains rejects a non-UTC instant', () {
      expect(
        () => UtcRange(a, b).contains(DateTime(2000)),
        throwsArgumentError,
      );
    });

    test('has value equality', () {
      expect(UtcRange(a, b), UtcRange(a, b));
      expect(UtcRange(a, b).hashCode, UtcRange(a, b).hashCode);
      expect(UtcRange(a, b), isNot(UtcRange(a, a)));
    });
  });
}
