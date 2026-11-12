import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

Crossing crossing({DateTime? timeUtc, int degree = 15, bool retro = false}) =>
    Crossing(
      timeUtc: timeUtc ?? DateTime.utc(2026, 11, 12, 6, 30, 15),
      body: Body.mars,
      degree: degree,
      retrograde: retro,
    );

void main() {
  group('Crossing', () {
    test('accepts degrees 0 and 359', () {
      expect(crossing(degree: 0).degree, 0);
      expect(crossing(degree: 359).degree, 359);
    });

    test('rejects degrees outside 0..359 (T-CRS-3 boundary)', () {
      expect(() => crossing(degree: 360), throwsArgumentError);
      expect(() => crossing(degree: -1), throwsArgumentError);
    });

    test('rejects a non-UTC time', () {
      expect(
        () => crossing(timeUtc: DateTime(2026, 11, 12)),
        throwsArgumentError,
      );
    });

    test('has value equality', () {
      expect(crossing(), crossing());
      expect(crossing().hashCode, crossing().hashCode);
      expect(crossing(), isNot(crossing(retro: true)));
    });
  });
}
