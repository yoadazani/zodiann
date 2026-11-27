// ZOD-TST-001: writes the Swiss Ephemeris lunar node reference at every instant
// of the Horizons dataset. Offline; needs `gcc` on the PATH. Run from this
// package's root:
//
//   dart run tool/gen_swiss_mean_node.dart
//
// Reads ../astro_core/test/fixtures/horizons_reference.json (the instants and
// the TT the app gives each, `jdTt`) and writes
// ../astro_core/test/fixtures/swiss_mean_node.json, from tool/node_grid.c
// compiled against the vendored upstream source.
import 'dart:convert';
import 'dart:io';

import 'package:ephemeris_swiss/ephemeris_swiss.dart';

import 'horizons/swiss_host.dart';

/// SEFLG_NONUT: no nutation, the mean equinox of date.
const _seflgNonut = 64;

void main() {
  final packageRoot = Platform.script.resolve('../');
  File fixture(String name) =>
      File.fromUri(packageRoot.resolve('../astro_core/test/fixtures/$name'));

  final dataset = jsonDecode(
    fixture('horizons_reference.json').readAsStringSync(),
  ) as Map<String, Object?>;
  // One row per instant, in the dataset's order.
  final instants = {
    for (final row
        in (dataset['entries']! as List<Object?>).cast<Map<String, Object?>>())
      row['utc']! as String: row['jdTt']! as String,
  };

  final lines = runSwissHostTool(packageRoot, 'node_grid.c', [
    packageRoot.resolve('assets/ephe').toFilePath(),
    ...instants.values,
  ]);
  if (lines.length != instants.length + 1 ||
      !lines.first.startsWith('version ')) {
    throw StateError(
      'node_grid printed ${lines.length} lines for ${instants.length} instants',
    );
  }
  final version = lines.first.substring('version '.length);

  final entries = <Map<String, Object?>>[];
  for (final (i, MapEntry(key: utc, value: jdTt)) in instants.entries.indexed) {
    final fields = lines[i + 1].split(' ');
    entries.add({
      'utc': utc,
      'jdTt': jdTt,
      'meanNodeDegrees': double.parse(fields[0]),
      'returnedFlags': int.parse(fields[1]),
      'j2000Degrees': double.parse(fields[2]),
      'trueNodeDegrees': double.parse(fields[3]),
    });
  }
  fixture('swiss_mean_node.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'version': 1, 'referenceDatesVersion': dataset['referenceDatesVersion'], 'source': 'Swiss Ephemeris $version, vendored source compiled on the host (tool/node_grid.c) with the packaged data files; SE_MEAN_NODE on the mean equinox of date (SEFLG_NONUT) at the TT of the Horizons dataset, with J2000 and SE_TRUE_NODE controls', 'requestedFlags': seflgSwieph | seflgSpeed | _seflgNonut, 'entries': entries})}\n',
  );
  stdout.writeln(
    'wrote ${entries.length} node entries (Swiss Ephemeris $version)',
  );
}
