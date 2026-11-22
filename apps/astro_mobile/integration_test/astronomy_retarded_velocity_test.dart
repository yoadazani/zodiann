// ZOD-EPH-004 D1 refinement (owner approval 2026-11-22, variant V2): for the
// Sun and the planets the adapter's longitude speed uses the body's velocity at
// the light-time-retarded instant, with the (1 - d tau / dt) factor, and the
// Earth's velocity at t. Run on an Android device or emulator:
//   flutter test integration_test/astronomy_retarded_velocity_test.dart -d <device>
//
// The expected values come from a separate implementation of the same formula
// (a scratch C program outside the repository, docs/spikes/
// ZOD-EPH-004-retarded-velocity/, using the same vendored library and written
// by the same author). It catches a transcription or unit slip in the shim; it
// does not check the formula itself, which the Swiss comparison does
// (astronomy_speed_vs_swiss_test.dart). `old` is the speed of the formulation
// before the refinement, `v2` the refined one.
// Each instant is whole seconds UTC; the C program was given the integer
// microseconds since J2000 and divided by 86400e6, as `daysSinceJ2000` does.
import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

typedef _Case = ({Body body, DateTime utc, double old, double v2});

final _cases = <_Case>[
  (
    body: Body.mercury,
    utc: DateTime.utc(1949, 10, 17, 19, 44, 35),
    old: 0.81546005004089228,
    v2: 0.81447482267193005,
  ),
  (
    body: Body.mercury,
    utc: DateTime.utc(2026, 11, 22, 6),
    old: 1.1068365141393537,
    v2: 1.1060297550606533,
  ),
  (
    body: Body.mercury,
    utc: DateTime.utc(2068, 11, 9, 12),
    old: 1.6062097734912562,
    v2: 1.6062031076855754,
  ),
  (
    body: Body.venus,
    utc: DateTime.utc(2016, 6, 7),
    old: 1.2288669592686343,
    v2: 1.2288670801002188,
  ),
  (
    body: Body.mars,
    utc: DateTime.utc(2044, 1, 11, 23, 10, 36),
    old: 0.21403926605866291,
    v2: 0.21405075412630536,
  ),
  (
    body: Body.sun,
    utc: DateTime.utc(2000, 1, 1, 12),
    old: 1.0193910633345424,
    v2: 1.0193910596536384,
  ),
  (
    body: Body.jupiter,
    utc: DateTime.utc(1967, 12, 2, 10, 2, 3),
    old: 0.062476283606494563,
    v2: 0.062482829014730901,
  ),
  (
    body: Body.pluto,
    utc: DateTime.utc(1969, 12, 10, 8, 10, 36),
    old: 0.011160669349757501,
    v2: 0.011161273029367558,
  ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final port = AstronomyEphemeris(source: const NativeBodyStateSource());

  for (final c in _cases) {
    test('${c.body.name} at ${c.utc.toIso8601String()}: the speed is the '
        'retarded-instant (V2) value, not the earlier one', () {
      final result = port.position(c.body, c.utc);
      expect(result, isA<EphemerisSuccess>());
      final speed = (result as EphemerisSuccess).position.speed;
      expect(speed, closeTo(c.v2, 1e-10), reason: 'V2 ${c.v2}');
      // Where the refinement moves the speed by more than 1e-4 degrees per
      // day (Mercury), the earlier value must be clearly excluded.
      if ((c.v2 - c.old).abs() > 1e-4) {
        expect((speed - c.old).abs(), greaterThan(1e-4));
      }
    });
  }
}
