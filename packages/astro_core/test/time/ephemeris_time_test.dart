// ZOD-EPH-002: the approved time conversion
// (docs/decisions/ZOD-EPH-002-time-scale.md, section 1).
import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

const _tick = Duration(microseconds: 1);

/// 32.184 s + [taiMinusUtcSeconds], exactly.
Duration _offset(int taiMinusUtcSeconds) =>
    Duration(microseconds: 32184000 + taiMinusUtcSeconds * 1000000);

void _expectTt(EphemerisTime time, Duration offset, TtBasis basis) {
  expect(time, isA<TerrestrialTime>());
  final tt = time as TerrestrialTime;
  expect(tt.ttMinusUtc, offset);
  expect(tt.basis, basis);
}

void main() {
  final table = LeapSecondTable.bundled;

  test('at every step, one microsecond either side', () {
    for (var i = 0; i < table.steps.length; i++) {
      final step = table.steps[i];
      for (final instant in [step.from, step.from.add(_tick)]) {
        _expectTt(
          ephemerisTimeFor(instant),
          _offset(step.taiMinusUtcSeconds),
          TtBasis.publishedLeapSeconds,
        );
      }
      final before = ephemerisTimeFor(step.from.subtract(_tick));
      if (i == 0) {
        expect(before, isA<UniversalTime>());
      } else {
        _expectTt(
          before,
          _offset(table.steps[i - 1].taiMinusUtcSeconds),
          TtBasis.publishedLeapSeconds,
        );
      }
    }
  });

  test('before 1972 the input is Universal Time', () {
    expect(ephemerisTimeFor(DateTime.utc(1900)), isA<UniversalTime>());
  });

  test('from the validity end the last offset is held and labelled', () {
    _expectTt(
      ephemerisTimeFor(table.validUntil.subtract(_tick)),
      _offset(37),
      TtBasis.publishedLeapSeconds,
    );
    for (final instant in [
      table.validUntil,
      table.validUntil.add(_tick),
      DateTime.utc(2100, 12, 31),
    ]) {
      _expectTt(
        ephemerisTimeFor(instant),
        _offset(37),
        TtBasis.assumedContinuousUtc,
      );
    }
  });

  test('the table is replaceable data', () {
    final custom = LeapSecondTable(
      steps: [LeapSecondStep(from: DateTime.utc(2000), taiMinusUtcSeconds: 5)],
      validUntil: DateTime.utc(2001),
      source: 's',
      bulletin: 'b',
    );
    expect(
      ephemerisTimeFor(DateTime.utc(1999), table: custom),
      isA<UniversalTime>(),
    );
    _expectTt(
      ephemerisTimeFor(DateTime.utc(2000, 6), table: custom),
      _offset(5),
      TtBasis.publishedLeapSeconds,
    );
    _expectTt(
      ephemerisTimeFor(DateTime.utc(2002), table: custom),
      _offset(5),
      TtBasis.assumedContinuousUtc,
    );
  });

  test('a non-UTC instant is rejected', () {
    expect(() => ephemerisTimeFor(DateTime(2000)), throwsArgumentError);
    expect(() => ephemerisTimeFor(DateTime(1900)), throwsArgumentError);
  });
}
