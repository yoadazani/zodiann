// ZOD-TST-001: writes the device test's constant copy of the Horizons dataset.
// Offline. Run from this package's root, then format the written file:
//
//   dart run tool/gen_horizons_copy.dart
//   dart format ../../apps/astro_mobile/integration_test/horizons_reference.dart
//
// Reads ../astro_core/test/fixtures/horizons_reference.json and writes
// ../../apps/astro_mobile/integration_test/horizons_reference.dart (a fixture
// is not an app asset, so the device test cannot read the JSON).
import 'dart:convert';
import 'dart:io';

import 'horizons/horizons.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  final dataset = jsonDecode(
    File.fromUri(
      packageRoot.resolve(
        '../astro_core/test/fixtures/horizons_reference.json',
      ),
    ).readAsStringSync(),
  ) as Map<String, Object?>;
  File.fromUri(
    packageRoot.resolve(
      '../../apps/astro_mobile/integration_test/horizons_reference.dart',
    ),
  ).writeAsStringSync(horizonsCopySource(dataset));
  stdout.writeln('wrote the copy of dataset version ${dataset['version']}');
}
