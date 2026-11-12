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
}
