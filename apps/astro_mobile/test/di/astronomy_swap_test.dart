// ZOD-EPH-004 Task 7 (acceptance criterion: "swap is only a DI override"):
// the astronomy-engine adapter replaces any other `EphemerisPort` with one
// provider override, and the code that consumes the port is unchanged. No
// production wiring exists: the app binds no source (D5; ZOD-EPH-002 owns the
// automatic source selection).
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:astro_mobile/src/di/app_overrides.dart';
import 'package:astro_mobile/src/di/ephemeris_providers.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/port_consumer.dart';

/// A native-source stand-in: the Sun on the x axis at 123.456 degrees (the
/// shim's own longitude), moving at 0.01 radians per day.
final class _FixedSource implements BodyStateSource {
  @override
  BodyState bodyState(Body body, DateTime utc) => const BodyState(
    longitude: 123.456,
    x: 1,
    y: 0,
    z: 0,
    vx: 0,
    vy: 0.01,
    vz: 0,
  );
}

/// An unrelated `EphemerisPort`, standing for the Swiss adapter.
final class _OtherPort implements EphemerisPort {
  @override
  UtcRange get coveredRange => UtcRange(DateTime.utc(1800), DateTime.utc(2400));

  @override
  EphemerisResult position(Body body, DateTime utc) =>
      EphemerisSuccess(EclipticPosition(longitude: 7.5, speed: -0.25));

  @override
  EclipticPosition meanAscendingNode(DateTime utc) =>
      EclipticPosition(longitude: 1, speed: 0);
}

/// Whether a Dart source imports or exports `ephemeris_astronomy`.
bool importsEphemerisAstronomy(String dartSource) => RegExp(
  r'''^\s*(import|export)\s+['"]package:ephemeris_astronomy/''',
  multiLine: true,
).hasMatch(dartSource);

Iterable<File> _dartFiles(Directory directory) => directory
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

/// The `packages/feature_*` directories.
List<Directory> _featurePackages() => Directory('../../packages')
    .listSync()
    .whereType<Directory>()
    .where(
      (d) => d.uri.pathSegments
          .lastWhere((s) => s.isNotEmpty)
          .startsWith('feature_'),
    )
    .toList();

void main() {
  final utc = DateTime.utc(2026, 11, 22, 6);

  group('the swap is one provider override', () {
    test('with the astronomy-engine adapter the consumer gets its position '
        'and its analytic speed', () {
      final override = ephemerisPortProvider.overrideWithValue(
        AstronomyEphemeris(source: _FixedSource()),
      );
      final container = ProviderContainer.test(overrides: [override]);
      final sun = sunFrom(container, utc);
      expect(sun.longitude, 123.456);
      // 0.01 rad/day = 0.5729577951308232 deg/day: (x vy - y vx) / (x^2 + y^2).
      expect(sun.speed, closeTo(0.5729577951308232, 1e-12));
    });

    test('with another port the same consumer runs unchanged', () {
      final container = ProviderContainer.test(
        overrides: [ephemerisPortProvider.overrideWithValue(_OtherPort())],
      );
      final sun = sunFrom(container, utc);
      expect(sun.longitude, 7.5);
      expect(sun.speed, -0.25);
    });

    test('each swap is exactly one override of the same provider', () {
      final adapter = [
        ephemerisPortProvider.overrideWithValue(
          AstronomyEphemeris(source: _FixedSource()),
        ),
      ];
      final other = [ephemerisPortProvider.overrideWithValue(_OtherPort())];
      expect(adapter, hasLength(1));
      expect(other, hasLength(1));
      final a = ProviderContainer.test(overrides: adapter);
      final b = ProviderContainer.test(overrides: other);
      expect(a.read(ephemerisPortProvider), isA<AstronomyEphemeris>());
      expect(b.read(ephemerisPortProvider), isA<_OtherPort>());
    });

    test('the adapter is not wired into the app: appOverrides binds nothing '
        'and an unbound container still fails', () {
      expect(appOverrides, isEmpty);
      final container = ProviderContainer.test();
      expect(() => container.read(ephemerisPortProvider), throwsA(anything));
    });
  });

  group('feature code does not know the astronomy-engine adapter', () {
    test('the scanner recognises an import and an export, and ignores a '
        'comment and other packages', () {
      expect(
        importsEphemerisAstronomy(
          "import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';",
        ),
        isTrue,
      );
      expect(
        importsEphemerisAstronomy(
          'export "package:ephemeris_astronomy/src/x.dart";',
        ),
        isTrue,
      );
      expect(
        importsEphemerisAstronomy(
          '// import package:ephemeris_astronomy/x.dart is not allowed here',
        ),
        isFalse,
      );
      expect(
        importsEphemerisAstronomy(
          "import 'package:astro_core/astro_core.dart';",
        ),
        isFalse,
      );
    });

    test('the consumer library imports nothing from ephemeris_astronomy', () {
      final source = File('test/di/support/port_consumer.dart')
          .readAsStringSync();
      expect(importsEphemerisAstronomy(source), isFalse);
      expect(source, contains('ephemerisPortProvider'));
    });

    test('no file of the app library or of any feature package imports '
        'ephemeris_astronomy, and no feature package depends on it', () {
      final features = _featurePackages();
      expect(features.length, greaterThanOrEqualTo(2));
      final roots = [
        Directory('lib'),
        for (final f in features) Directory('${f.path}/lib'),
      ];
      var scanned = 0;
      for (final root in roots) {
        expect(root.existsSync(), isTrue, reason: root.path);
        for (final file in _dartFiles(root)) {
          scanned++;
          expect(
            importsEphemerisAstronomy(file.readAsStringSync()),
            isFalse,
            reason: file.path,
          );
        }
      }
      expect(scanned, greaterThan(0));
      for (final feature in features) {
        final pubspec = File('${feature.path}/pubspec.yaml').readAsStringSync();
        expect(
          pubspec.contains('ephemeris_astronomy'),
          isFalse,
          reason: feature.path,
        );
      }
    });
  });
}
