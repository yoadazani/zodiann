// ZOD-EPH-002: where the packaged Swiss Ephemeris files really end, measured
// on the device through the production time conversion, and the check that
// `SwissEphemeris.fileCoverage` states exactly that. Run on an Android device
// or emulator:
//   flutter test integration_test/swiss_file_edges_test.dart -d <device>
//
// "Fails at t" means the calculation gives no result or did not use the data
// files. Rule: the covered range starts at the first 00:00 UTC at least 24 h
// after the latest failing instant of any body at the lower edge, and ends at
// the last 00:00 UTC at least 24 h before the earliest failing instant at the
// upper edge.
import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:ephemeris_swiss/ephemeris_swiss_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/swiss_data.dart';

const _day = Duration(days: 1);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final binding = SwissEphemerisBinding();
  final source = NativeSwissCalculationSource(binding);

  setUpAll(() async {
    binding.setEphePath((await installTestSwissData()).path);
  });

  bool fails(Body body, DateTime utc) {
    final result = calculateSwissBody(source, body, utc);
    return result == null || !result.usedSwissEphemerisFiles;
  }

  /// The failing instant closest to the files, to one minute, between a
  /// [bad] instant and a [good] one.
  DateTime lastFailure(Body body, DateTime bad, DateTime good) {
    expect(fails(body, bad), isTrue, reason: '$body must fail at $bad');
    expect(fails(body, good), isFalse, reason: '$body must work at $good');
    var failing = bad;
    var working = good;
    while (working.difference(failing).abs() > const Duration(minutes: 1)) {
      final middle = failing.add(
        Duration(microseconds: working.difference(failing).inMicroseconds ~/ 2),
      );
      if (fails(body, middle)) {
        failing = middle;
      } else {
        working = middle;
      }
    }
    return failing;
  }

  test('fileCoverage is the measured coverage of all ten bodies', () {
    DateTime? latestLower;
    DateTime? earliestUpper;
    for (final body in swissBodyIds.keys) {
      final lower = lastFailure(body, DateTime.utc(1790), DateTime.utc(1801));
      final upper = lastFailure(body, DateTime.utc(2410), DateTime.utc(2398));
      // ignore: avoid_print
      print('EDGE ${body.name}: fails up to $lower, fails from $upper');
      if (latestLower == null || lower.isAfter(latestLower)) {
        latestLower = lower;
      }
      if (earliestUpper == null || upper.isBefore(earliestUpper)) {
        earliestUpper = upper;
      }
    }
    // The first midnight at least a day after the latest lower failure.
    final earliest = latestLower!.add(_day);
    final floor = DateTime.utc(earliest.year, earliest.month, earliest.day);
    final start = floor == earliest ? floor : floor.add(_day);
    // The last midnight at least a day before the earliest upper failure.
    final latest = earliestUpper!.subtract(_day);
    final end = DateTime.utc(latest.year, latest.month, latest.day);
    // ignore: avoid_print
    print('EDGE measured coverage: $start to $end');

    expect(SwissEphemeris.fileCoverage, UtcRange(start, end));
  });

  test('every body works hourly over the first and last 40 days', () {
    final range = SwissEphemeris.fileCoverage;
    final failures = <String>[];
    for (var hour = 0; hour <= 40 * 24; hour++) {
      final offset = Duration(hours: hour);
      for (final utc in [range.start.add(offset), range.end.subtract(offset)]) {
        for (final body in swissBodyIds.keys) {
          if (fails(body, utc)) failures.add('${body.name} $utc');
        }
      }
    }

    expect(failures, isEmpty);
  });

  test('40 days outside either end at least one body fails', () {
    final range = SwissEphemeris.fileCoverage;
    const margin = Duration(days: 40);

    for (final utc in [range.start.subtract(margin), range.end.add(margin)]) {
      expect(
        swissBodyIds.keys.where((body) => fails(body, utc)),
        isNotEmpty,
        reason: '$utc',
      );
    }
  });
}
