// ZOD-FND-003 (decision D3): compiles the vendored Swiss Ephemeris source into
// `libswisseph` through Dart native assets. It builds for Android only.
//
// For any other target (the host that runs `dart test` / `flutter test`, and
// iOS until the iOS half of the spike is verified) it adds no asset and
// returns at once, so host tests never need a C toolchain. The host machine
// has no MSVC, and `windows-latest` would otherwise pay a C build on every
// run. Host tests must not import the native bindings.
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Relative to this package's root: the vendored, unmodified upstream source.
const _upstream = '../../native/swisseph/upstream';

/// The nine library objects named by upstream's `Makefile` (`SWEOBJ`).
const _sources = [
  'swedate.c',
  'swehouse.c',
  'swejpl.c',
  'swemmoon.c',
  'swemplan.c',
  'sweph.c',
  'swephlib.c',
  'swecl.c',
  'swehel.c',
];

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    if (input.config.code.targetOS != OS.android) return;

    final builder = CBuilder.library(
      name: 'swisseph',
      // Must equal the asset id in ffigen.yaml and the `@Native` bindings:
      // package:ephemeris_swiss/src/ffi/swisseph_bindings.g.dart
      assetName: 'src/ffi/swisseph_bindings.g.dart',
      sources: [for (final file in _sources) '$_upstream/$file'],
      includes: [_upstream],
      libraries: ['m'],
    );
    await builder.run(
      input: input,
      output: output,
      // The root logger: a named logger cannot change its level unless
      // `hierarchicalLoggingEnabled` is set.
      logger: Logger('')
        ..level = Level.INFO
        ..onRecord.listen((record) => print(record.message)),
    );
  });
}
