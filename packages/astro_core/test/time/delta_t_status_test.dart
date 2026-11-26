// ZOD-EPH-002: how well delta T is known, kept separate from the time
// conversion (docs/decisions/ZOD-EPH-002-time-scale.md, section 2).
import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

const _tick = Duration(microseconds: 1);

void main() {
  test('the bundled boundaries', () {
    final observedEnd = DateTime.utc(2024);
    final estimatedEnd = DateTime.utc(2029);

    expect(deltaTStatusAt(DateTime.utc(1900)), DeltaTStatus.observed);
    expect(deltaTStatusAt(observedEnd.subtract(_tick)), DeltaTStatus.observed);
    expect(deltaTStatusAt(observedEnd), DeltaTStatus.estimated);
    expect(
      deltaTStatusAt(estimatedEnd.subtract(_tick)),
      DeltaTStatus.estimated,
    );
    expect(deltaTStatusAt(estimatedEnd), DeltaTStatus.forecast);
  });

  test('the classification follows the dataset', () {
    final dataset = DeltaTDataset(
      observedBefore: DateTime.utc(2030),
      estimatedBefore: DateTime.utc(2032),
      source: 's',
    );
    DeltaTStatus at(int year) =>
        deltaTStatusAt(DateTime.utc(year), dataset: dataset);

    expect(at(2029), DeltaTStatus.observed);
    expect(at(2031), DeltaTStatus.estimated);
    expect(at(2032), DeltaTStatus.forecast);
  });

  test('a non-UTC instant is rejected', () {
    expect(() => deltaTStatusAt(DateTime(2000)), throwsArgumentError);
  });

  group('construction rejects', () {
    test('non-UTC boundaries', () {
      expect(
        () => DeltaTDataset(
          observedBefore: DateTime(2024),
          estimatedBefore: DateTime.utc(2029),
          source: 's',
        ),
        throwsArgumentError,
      );
      expect(
        () => DeltaTDataset(
          observedBefore: DateTime.utc(2024),
          estimatedBefore: DateTime(2029),
          source: 's',
        ),
        throwsArgumentError,
      );
    });

    test('an estimated end before the observed end', () {
      expect(
        () => DeltaTDataset(
          observedBefore: DateTime.utc(2029),
          estimatedBefore: DateTime.utc(2024),
          source: 's',
        ),
        throwsArgumentError,
      );
    });
  });
}
