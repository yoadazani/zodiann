// ZOD-TST-001: the app's mean ascending node against Swiss Ephemeris on a device
// (ACC-1 takes the node out of the JPL Horizons comparison and validates it
// separately). The reference is the library's own `SE_MEAN_NODE` on the mean
// equinox of date (`SEFLG_NONUT`), the frame of the app formula's definition,
// at the TT the app gives each instant: every instant of the shared date set and
// every month from 1900 to 2100, within 0.01 degrees. The tolerance alone cannot
// tell the frame, so the flags the library used are asserted too. Run on an
// Android device or emulator:
//   flutter test integration_test/swiss_mean_node_test.dart -d <device>
//
// Design: docs/superpowers/specs/
// 2026-11-26-zod-tst-001-horizons-reference-design.md, section 7.
import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:ephemeris_swiss/ephemeris_swiss_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'horizons_reference.dart';
import 'support/swiss_data.dart';

/// The owner's tolerance (decision D6), degrees.
const _toleranceDegrees = 0.01;

// Swiss Ephemeris numbers (swephexp.h): the lunar node bodies and the flags the
// adapter does not use.
const _seMeanNode = 10;
const _seTrueNode = 11;
const _seflgJ2000 = 32;
const _seflgNonut = 64;
const _meanNodeFlags = seflgSwieph | seflgSpeed | _seflgNonut;

/// The shortest angle between two longitudes, in degrees.
double _degreesBetween(double a, double b) => ((b - a + 180) % 360 - 180).abs();

/// Largest values seen, for the report.
final class _Worst {
  double degrees = 0;
  String at = '';

  void add(double value, String instant) {
    if (value > degrees) {
      degrees = value;
      at = instant;
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final binding = SwissEphemerisBinding();
  final port = SwissEphemeris(source: NativeSwissCalculationSource(binding));

  setUpAll(() async {
    final data = await installTestSwissData();
    binding.setEphePath(data.path);
  });

  /// The app's node at [utc], in degrees.
  double appNode(DateTime utc) {
    final result = port.position(Body.node, utc);
    expect(result, isA<EphemerisSuccess>(), reason: '$utc');
    return (result as EphemerisSuccess).position.longitude;
  }

  /// Compares the app's node at each instant with the library, which [calculate]
  /// asks at the TT of that instant, and with both controls.
  void check(
    String name,
    Iterable<(DateTime, SwissCalcResult Function(int body, int flags))>
    instants, {
    required int expected,
  }) {
    final mean = _Worst();
    final j2000 = _Worst();
    final trueNode = _Worst();
    var checked = 0;
    final over = <String>[];
    for (final (utc, calculate) in instants) {
      final app = appNode(utc);
      final reference = calculate(_seMeanNode, _meanNodeFlags);
      expect(reference.error, isEmpty, reason: '$utc');
      expect(
        reference.returnFlags & _seflgNonut,
        isNot(0),
        reason: '$utc: flags ${reference.returnFlags}',
      );
      expect(
        reference.returnFlags & _seflgJ2000,
        0,
        reason: '$utc: flags ${reference.returnFlags}',
      );
      final control = calculate(_seMeanNode, _meanNodeFlags | _seflgJ2000);
      expect(control.returnFlags & _seflgJ2000, isNot(0), reason: '$utc');
      final truth = calculate(_seTrueNode, seflgSwieph | seflgSpeed);
      expect(truth.error, isEmpty, reason: '$utc');

      final difference = _degreesBetween(app, reference.longitude);
      if (difference > _toleranceDegrees) over.add('$utc $difference');
      mean.add(difference, '$utc');
      j2000.add(_degreesBetween(app, control.longitude), '$utc');
      trueNode.add(_degreesBetween(app, truth.longitude), '$utc');
      checked++;
    }
    // ignore: avoid_print
    print(
      'node $name: $checked instants; mean node max ${mean.degrees} deg at '
      '${mean.at}; controls J2000 max ${j2000.degrees} at ${j2000.at}, true '
      'node max ${trueNode.degrees} at ${trueNode.at}',
    );
    expect(checked, expected, reason: name);
    expect(over, isEmpty, reason: name);
    // Controls: another equinox and the true node are not the same quantity.
    expect(j2000.degrees, greaterThan(_toleranceDegrees), reason: name);
    expect(trueNode.degrees, greaterThan(_toleranceDegrees), reason: name);
  }

  test('the mean node at every shared instant, at the dataset TT', () {
    check('shared instants', [
      for (final reference in horizonsReference)
        if (reference.body == 'sun')
          (
            DateTime.parse(reference.utc),
            (int body, int flags) => binding.calcTt(
              double.parse(reference.jdTt),
              body,
              flags: flags,
            ),
          ),
    ], expected: 64);
  });

  test('the mean node every month from 1900 to 2100', () {
    check('monthly', [
      for (var year = 1900; year <= 2100; year++)
        for (var month = 1; month <= 12; month++)
          () {
            final utc = DateTime.utc(year, month);
            return (
              utc,
              (int body, int flags) => switch (ephemerisTimeFor(utc)) {
                UniversalTime() => binding.calcUt(utc, body, flags: flags),
                TerrestrialTime(:final ttMinusUtc) => binding.calcTt(
                  julianDayUt(utc.add(ttMinusUtc)),
                  body,
                  flags: flags,
                ),
              },
            );
          }(),
    ], expected: 2412);
  });
}
