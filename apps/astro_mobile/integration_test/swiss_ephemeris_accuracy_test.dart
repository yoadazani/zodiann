// ZOD-EPH-002 (T-EPH-1 and the owner's gate of 2026-11-26): the Swiss
// Ephemeris adapter, running the real library through FFI, against JPL
// Horizons for all ten physical bodies at every instant of
// packages/astro_core/test/fixtures/reference_dates.json, within one
// arcsecond, both by UTC input and at matched TT. Run on an Android device or
// emulator:
//   flutter test integration_test/swiss_ephemeris_accuracy_test.dart -d <device>
//
// The adapter is tested bare, without the supported-range wrapper: the first
// reference instant is 1899-12-31T12:00Z, which the wrapper rejects.
//
// An extra precession, sidereal or J2000 correction would move every longitude
// by far more than the tolerance, so these gates also guard ACC-5.
//
// Limit: the Swiss data files and Horizons both descend from JPL ephemerides.
// This checks time handling, the apparent-place chain and the packaged files,
// not orbit theory independently.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:ephemeris_swiss/ephemeris_swiss_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'astronomy_reference_longitudes.dart';
import 'support/swiss_data.dart';
import 'swiss_reference_longitudes_tt.dart';

/// Smallest angle between two longitudes, in arcseconds.
double arcsecondsBetween(double a, double b) {
  var difference = (a - b).abs() % 360;
  if (difference > 180) difference = 360 - difference;
  return difference * 3600;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final binding = SwissEphemerisBinding();
  final port = SwissEphemeris(source: NativeSwissCalculationSource(binding));
  late Directory data;

  setUpAll(() async {
    data = await installTestSwissData();
    binding.setEphePath(data.path);
  });

  EclipticPosition at(Body body, DateTime utc) {
    final result = port.position(body, utc);
    expect(result, isA<EphemerisSuccess>(), reason: '${body.name} $utc');
    return (result as EphemerisSuccess).position;
  }

  void expectUnavailable(Body body, DateTime utc) => expect(
    port.position(body, utc),
    isA<OutOfCoveredRange>(),
    reason: '${body.name} $utc',
  );

  /// Prints each body's worst error, then requires all within [tolerance].
  void gate(
    String name,
    Map<String, List<(String, double)>> errors,
    double tolerance,
  ) {
    var rows = 0;
    final over = <String>[];
    errors.forEach((body, list) {
      rows += list.length;
      final worst = list.reduce((a, b) => b.$2 > a.$2 ? b : a);
      // ignore: avoid_print
      print(
        '$name $body: max ${worst.$2.toStringAsFixed(4)} arcsec at '
        '${worst.$1} (${list.length} instants)',
      );
      over.addAll([
        for (final (utc, off) in list)
          if (off > tolerance) '$body $utc $off',
      ]);
    });
    expect(errors, hasLength(10), reason: name);
    expect(rows, 530, reason: name);
    expect(over, isEmpty, reason: name);
  }

  test('the comparison itself', () {
    expect(
      arcsecondsBetween(10, 10 + 1.01 / 3600),
      greaterThan(swissTtToleranceArcseconds),
    );
    expect(
      arcsecondsBetween(10, 10 + 0.99 / 3600),
      lessThan(swissTtToleranceArcseconds),
    );
    expect(arcsecondsBetween(359.99, 0.01), closeTo(72, 1e-6));
  });

  test('UTC input: all ten bodies, 53 instants, within 1 arcsecond', () {
    final errors = <String, List<(String, double)>>{};
    for (final reference in astronomyReferenceLongitudes) {
      final position = at(
        Body.fromJson(reference.body),
        DateTime.parse(reference.utc),
      );
      errors.putIfAbsent(reference.body, () => []).add((
        reference.utc,
        arcsecondsBetween(position.longitude, reference.longitudeDegrees),
      ));
    }

    gate('UTC', errors, swissTtToleranceArcseconds);
  });

  test('matched TT: all ten bodies within 1 arcsecond', () {
    final errors = <String, List<(String, double)>>{};
    for (final reference in swissTtReferenceLongitudes) {
      final result = binding.calcTt(
        double.parse(reference.jdTt),
        swissBodyIds[Body.fromJson(reference.body)]!,
      );
      expect(
        result.usedSwissEphemerisFiles,
        isTrue,
        reason: '${reference.body} ${reference.utc}',
      );
      errors.putIfAbsent(reference.body, () => []).add((
        reference.utc,
        arcsecondsBetween(result.longitude, reference.longitudeDegrees),
      ));
    }

    gate('TT', errors, swissTtToleranceArcseconds);
  });

  test('the fixture TT is the TT the adapter uses', () {
    // The Moon moves about 0.5 arcsec per second, so 0.0005 arcsec pins the
    // device's own conversion to the fixture within about a millisecond, on
    // both sides of 1972.
    var rows = 0;
    var worst = 0.0;
    for (final reference in swissTtReferenceLongitudes) {
      if (reference.body != 'moon') continue;
      rows++;
      final utc = DateTime.parse(reference.utc);
      final atFixtureTt = binding.calcTt(double.parse(reference.jdTt), 1);
      final off = arcsecondsBetween(
        at(Body.moon, utc).longitude,
        atFixtureTt.longitude,
      );
      worst = math.max(worst, off);
      expect(off, lessThanOrEqualTo(0.0005), reason: reference.utc);
    }
    // ignore: avoid_print
    print('TT pin: max $worst arcsec over $rows Moon instants');
    expect(rows, 53);
  });

  test('speed is the library speed', () {
    for (final utc in [DateTime.utc(2026, 11, 26), DateTime.utc(1950)]) {
      for (final MapEntry(key: body, value: id) in swissBodyIds.entries) {
        final time = ephemerisTimeFor(utc);
        final direct = switch (time) {
          UniversalTime() => binding.calcUt(utc, id),
          TerrestrialTime(:final ttMinusUtc) => binding.calcTt(
            julianDayUt(utc.add(ttMinusUtc)),
            id,
          ),
        };
        expect(at(body, utc).speed, direct.speed, reason: '${body.name} $utc');
      }
    }
  });

  test('supported and covered edges', () {
    final coverage = port.coveredRange;
    for (final utc in [
      SupportedDateRange.start,
      SupportedDateRange.end,
      coverage.start,
      coverage.end,
    ]) {
      for (final body in swissBodyIds.keys) {
        at(body, utc);
      }
    }
    const tick = Duration(microseconds: 1);
    for (final utc in [coverage.start.subtract(tick), coverage.end.add(tick)]) {
      for (final body in swissBodyIds.keys) {
        expectUnavailable(body, utc);
      }
    }
  });

  test('empty directory', () {
    final empty = Directory.systemTemp.createTempSync('swiss_empty');
    addTearDown(() {
      binding.setEphePath(data.path);
      empty.deleteSync(recursive: true);
    });
    binding.setEphePath(empty.path);

    for (final body in swissBodyIds.keys) {
      expectUnavailable(body, DateTime.utc(2000, 1, 1, 12));
    }
  });

  test('damaged files', () {
    final utc = DateTime.utc(2000, 1, 1, 12);
    final intact = {
      for (final body in swissBodyIds.keys) body: at(body, utc).longitude,
    };
    Directory damaged(String name, List<int> Function(Uint8List) damage) {
      final directory = Directory.systemTemp.createTempSync(name);
      for (final file in testSwissDataFiles) {
        File('${directory.path}/$file').writeAsBytesSync(
          damage(File('${data.path}/$file').readAsBytesSync()),
        );
      }
      return directory;
    }

    final zeroed = damaged('swiss_zeroed', (_) => Uint8List(4096));
    final truncated = damaged(
      'swiss_truncated',
      (bytes) => bytes.sublist(0, bytes.length ~/ 2),
    );
    addTearDown(() {
      binding.setEphePath(data.path);
      zeroed.deleteSync(recursive: true);
      truncated.deleteSync(recursive: true);
    });

    binding.setEphePath(zeroed.path);
    for (final body in swissBodyIds.keys) {
      expectUnavailable(body, utc);
    }

    binding.setEphePath(truncated.path);
    for (final body in swissBodyIds.keys) {
      final result = port.position(body, utc);
      // ignore: avoid_print
      print('truncated ${body.name}: $result');
      if (result is EphemerisSuccess) {
        expect(
          arcsecondsBetween(result.position.longitude, intact[body]!),
          lessThanOrEqualTo(swissTtToleranceArcseconds),
          reason: body.name,
        );
      } else {
        expect(result, isA<OutOfCoveredRange>(), reason: body.name);
      }
    }

    // The process survived, and the intact files work again.
    binding.setEphePath(data.path);
    for (final body in swissBodyIds.keys) {
      expect(at(body, utc).longitude, intact[body], reason: body.name);
    }
  });
}
