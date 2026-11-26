// ZOD-EPH-002: the native library has **one** shared state and every call is
// locked. Run on an Android device or emulator:
//   flutter test integration_test/swiss_ephemeris_concurrency_test.dart -d <device>
//
// The first test is deterministic: an isolate on another thread that never set
// the data path can read the data files only if the state is shared (the
// library built with TLSOFF). The second looks for races between isolates; a
// pass does not prove the absence of a race.
import 'dart:io';
import 'dart:isolate';

import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:ephemeris_swiss/ephemeris_swiss_native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _assetDirectory = 'packages/ephemeris_swiss/assets/ephe';
const _dataFiles = ['sepl_18.se1', 'semo_18.se1'];

/// UT instants go through `calcUt`; the others through `calcTt` with the
/// 69.184 s offset.
const _utInstants = ['1900-06-15T06:00:00Z', '1971-12-31T00:00:00Z'];
const _ttInstants = [
  '2000-01-01T12:00:00Z',
  '2050-01-01T00:00:00Z',
  '2100-12-31T00:00:00Z',
];

typedef _Row = ({String label, double longitude, double speed, bool usedFiles});

/// Every body at every instant, starting [rotation] positions into the grid;
/// returned in grid order. It never sets the data path.
List<_Row> _grid(int rotation) {
  final binding = SwissEphemerisBinding();
  final calls = <(String, int, bool)>[
    for (final utc in _utInstants)
      for (var body = 0; body < 10; body++) (utc, body, true),
    for (final utc in _ttInstants)
      for (var body = 0; body < 10; body++) (utc, body, false),
  ];
  final rows = List<_Row?>.filled(calls.length, null);
  for (var i = 0; i < calls.length; i++) {
    final index = (i + rotation) % calls.length;
    final (utc, body, isUt) = calls[index];
    final instant = DateTime.parse(utc);
    final result = isUt
        ? binding.calcUt(instant, body)
        : binding.calcTt(julianDayUt(instant) + 69.184 / 86400, body);
    rows[index] = (
      label: '$body $utc',
      longitude: result.longitude,
      speed: result.speed,
      usedFiles: result.usedSwissEphemerisFiles,
    );
  }
  return rows.cast<_Row>();
}

/// The grid [repeats] times, each pass in a different order. Returns every row
/// that did not use the files or differs from [baseline].
List<String> _repeatedly(int start, int repeats, List<_Row> baseline) {
  final problems = <String>[];
  for (var pass = 0; pass < repeats; pass++) {
    final rows = _grid(start + pass * 7);
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final expected = baseline[i];
      if (!row.usedFiles ||
          row.longitude != expected.longitude ||
          row.speed != expected.speed) {
        problems.add('pass $pass: $row, expected $expected');
      }
    }
  }
  return problems;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late List<_Row> baseline;

  setUpAll(() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/ephe')
      ..createSync(recursive: true);
    for (final name in _dataFiles) {
      final bundled = await rootBundle.load('$_assetDirectory/$name');
      await File('${directory.path}/$name').writeAsBytes(
        bundled.buffer.asUint8List(
          bundled.offsetInBytes,
          bundled.lengthInBytes,
        ),
        flush: true,
      );
    }
    // Once, here, in the main isolate.
    SwissEphemerisBinding().setEphePath(directory.path);
    baseline = _grid(0);
  });

  test('the sequential baseline reads the data files', () {
    expect(baseline, hasLength(50));
    expect(baseline.where((r) => !r.usedFiles), isEmpty);
  });

  test('an isolate that never set the path reads the data files', () async {
    final rows = await Isolate.run(() => _grid(0));

    expect(rows.where((r) => !r.usedFiles), isEmpty);
    expect(rows, baseline);
  });

  test('concurrent isolates match sequential results', () async {
    final expected = baseline;
    final problems = await Future.wait([
      for (var worker = 0; worker < 4; worker++)
        _runWorker(worker * 13, expected),
    ]);

    expect(problems.expand((p) => p), isEmpty);
  });
}

/// A separate function, so the isolate closure captures only what it sends.
Future<List<String>> _runWorker(int start, List<_Row> baseline) =>
    Isolate.run(() => _repeatedly(start, 50, baseline));
