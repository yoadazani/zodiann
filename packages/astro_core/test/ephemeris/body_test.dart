import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  test('Body has exactly the spec values in spec order', () {
    expect(Body.values.map((b) => b.name), [
      'sun',
      'moon',
      'mercury',
      'venus',
      'mars',
      'jupiter',
      'saturn',
      'uranus',
      'neptune',
      'pluto',
      'node',
    ]);
  });

  test('round-trips every value through JSON', () {
    for (final body in Body.values) {
      expect(Body.fromJson(body.toJson()), body);
    }
    expect(Body.node.toJson(), 'node');
  });

  test('rejects unknown names and non-strings', () {
    for (final bad in <Object?>['chiron', 'Sun', 3, null]) {
      expect(() => Body.fromJson(bad), throwsFormatException, reason: '$bad');
    }
  });
}
