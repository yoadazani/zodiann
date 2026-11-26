// ZOD-FND-011 (owner decision 2026-11-25): the app ships exactly the Swiss
// Ephemeris pair sepl_18 + semo_18 and no neighbouring 600-year block. The
// files nominally cover 1800 to 2400 (named after the upstream blocks; NOT
// device-verified until ZOD-EPH-002 measures the edges), while the product
// range is narrower (1900 to 2100, `SupportedDateRange` in astro_core).
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

/// Nominal coverage of the `_18` block, from the upstream block names.
/// Informational: `SwissCalcResult.usedSwissEphemerisFiles` on every call is
/// the authoritative runtime check.
final _nominalStart = DateTime.utc(1800);
final _nominalEnd = DateTime.utc(2400);

void main() {
  final dir = Directory('assets/ephe');

  test('the packaged set is exactly sepl_18 and semo_18', () {
    final names =
        dir
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .toList()
          ..sort();

    expect(names, ['semo_18.se1', 'sepl_18.se1']);
  });

  test(
    'the file sizes are the measured raw sizes (FND-003 findings, sec. 4)',
    () {
      expect(File('assets/ephe/sepl_18.se1').lengthSync(), 484061);
      expect(File('assets/ephe/semo_18.se1').lengthSync(), 1304771);
    },
  );

  test('the nominal coverage encloses the product range with margin', () {
    expect(
      SupportedDateRange.start.difference(_nominalStart).inDays,
      greaterThanOrEqualTo(36500),
    );
    expect(
      _nominalEnd.difference(SupportedDateRange.end).inDays,
      greaterThanOrEqualTo(100000),
    );
  });
}
