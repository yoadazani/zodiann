// ZOD-EPH-002: astro_core's bundled time data agrees with the vendored Swiss
// Ephemeris source, so a library upgrade or a table edit cannot leave one of
// them stale.
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

const _upstream = '../../native/swisseph/upstream';

void main() {
  test('the leap-second steps match swedate.c', () {
    final source = File('$_upstream/swedate.c').readAsStringSync();
    final block = RegExp(
      r'leap_seconds\[NLEAP_SECONDS_SPACE\]\s*=\s*\{([^}]*)\}',
    ).firstMatch(source);
    expect(block, isNotNull, reason: 'the list was not found');
    // The list names the day that ends with the leap second: the step takes
    // effect at 00:00 UTC of the following day.
    final steps = [
      for (final m in RegExp(
        r'\b(\d{4})(\d{2})(\d{2}),',
      ).allMatches(block!.group(1)!))
        DateTime.utc(
          int.parse(m.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!) + 1,
        ),
    ];
    final after1972 = LeapSecondTable.bundled.steps.skip(1).toList();

    expect(steps, hasLength(27));
    expect(steps, [for (final s in after1972) s.from]);
    expect(
      [for (final s in after1972) s.taiMinusUtcSeconds],
      [for (var n = 11; n <= 37; n++) n],
    );
  });

  test('the estimated delta T ends where the vendored table ends', () {
    final source = File('$_upstream/swephlib.c').readAsStringSync();
    final match = RegExp(
      r'^#define\s+TABEND\s+(\d{4})',
      multiLine: true,
    ).firstMatch(source);
    expect(match, isNotNull, reason: 'TABEND was not found');

    expect(
      DeltaTDataset.bundled.estimatedBefore,
      DateTime.utc(int.parse(match!.group(1)!) + 1),
    );
  });
}
