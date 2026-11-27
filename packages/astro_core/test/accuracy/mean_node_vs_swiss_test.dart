// ZOD-TST-001: the mean ascending node against Swiss Ephemeris (ACC-1 takes the
// node out of the JPL Horizons comparison and validates it separately; the
// formula itself is T-EPH-2's).
//
// The reference is Swiss Ephemeris body `SE_MEAN_NODE` on the mean equinox of
// date (`SEFLG_NONUT`), the frame of the formula's definition, computed on the
// host from the vendored source at the TT of each shared instant
// (fixtures/swiss_mean_node.json, written by
// packages/ephemeris_swiss/tool/gen_swiss_mean_node.dart). The same comparison
// runs on a device over every month from 1900 to 2100
// (apps/astro_mobile/integration_test/swiss_mean_node_test.dart). Design:
// docs/superpowers/specs/2026-11-26-zod-tst-001-horizons-reference-design.md,
// section 7.
//
// The tolerance alone cannot tell the frame: the default Swiss flags (true
// equinox) would also pass it, so the flags of the reference are asserted.
//
// Run from `packages/astro_core` (as `melos exec` / `melos run test` do): the
// fixture paths are relative to the package.
import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart' show meanAscendingNodeAt;
import 'package:test/test.dart';

/// The owner's tolerance (decision D6), degrees.
const _toleranceDegrees = 0.01;

// Swiss Ephemeris flag bits (swephexp.h).
const _seflgSwieph = 2;
const _seflgJ2000 = 32;
const _seflgNonut = 64;
const _seflgSpeed = 256;
const _seflgSidereal = 65536;

Map<String, Object?> _read(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, Object?>;

/// The shortest angle between two longitudes, in degrees.
double _degreesBetween(double a, double b) => ((b - a + 180) % 360 - 180).abs();

void main() {
  late Map<String, Object?> node;
  late Map<String, Object?> dataset;
  late Map<String, Object?> dateFile;
  late List<Map<String, Object?>> entries;

  setUpAll(() {
    node = _read('swiss_mean_node.json');
    dataset = _read('horizons_reference.json');
    dateFile = _read('reference_dates.json');
    entries = (node['entries']! as List<Object?>).cast<Map<String, Object?>>();
  });

  double number(Map<String, Object?> entry, String field) =>
      (entry[field]! as num).toDouble();

  test('the fixture belongs to the shared dataset', () {
    expect(node['version'], 1);
    expect(node['referenceDatesVersion'], dateFile['version']);
    expect(node['requestedFlags'], _seflgSwieph | _seflgSpeed | _seflgNonut);
    expect(node['source'], contains('Swiss Ephemeris'));
    final ttOf = {
      for (final row
          in (dataset['entries']! as List<Object?>)
              .cast<Map<String, Object?>>())
        row['utc']: row['jdTt'],
    };
    for (final entry in entries) {
      expect(entry['jdTt'], ttOf[entry['utc']], reason: '${entry['utc']}');
    }
  });

  test('covers every shared instant once', () {
    final instants = [for (final entry in entries) entry['utc']];
    expect(instants, hasLength(64));
    expect(instants.toSet(), (dateFile['dates']! as List<Object?>).toSet());
  });

  test('the reference is the mean node on the mean equinox of date', () {
    for (final entry in entries) {
      final flags = entry['returnedFlags']! as int;
      final reason = '${entry['utc']}: flags $flags';
      expect(flags & _seflgNonut, isNot(0), reason: reason);
      expect(flags & _seflgJ2000, 0, reason: reason);
      expect(flags & _seflgSidereal, 0, reason: reason);
    }
  });

  test(
    'the formula is within 0.01 degrees of Swiss at every shared instant',
    () {
      var worst = 0.0;
      var at = '';
      for (final entry in entries) {
        final utc = entry['utc']! as String;
        final difference = _degreesBetween(
          meanAscendingNodeAt(DateTime.parse(utc)).longitude,
          number(entry, 'meanNodeDegrees'),
        );
        if (difference > worst) {
          worst = difference;
          at = utc;
        }
        expect(difference, lessThanOrEqualTo(_toleranceDegrees), reason: utc);
      }
      // ignore: avoid_print
      print('mean node formula vs Swiss: max $worst deg at $at');
    },
  );

  test(
    'controls: J2000 and the true node differ by more than 0.01 degrees',
    () {
      for (final field in ['j2000Degrees', 'trueNodeDegrees']) {
        final worst = [
          for (final entry in entries)
            _degreesBetween(
              meanAscendingNodeAt(DateTime.parse(entry['utc']! as String))
                  .longitude,
              number(entry, field),
            ),
        ].reduce((a, b) => a > b ? a : b);
        expect(worst, greaterThan(_toleranceDegrees), reason: field);
      }
    },
  );
}
