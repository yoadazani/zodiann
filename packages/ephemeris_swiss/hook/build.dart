// ZOD-FND-003 (decision D3): compiles the vendored Swiss Ephemeris source into
// `libswisseph` through Dart native assets. It builds for Android only.
//
// For any other target (the host that runs `dart test` / `flutter test`, and
// iOS until the iOS half of the spike is verified) it adds no asset and
// returns at once, so host tests never need a C toolchain. The host machine
// has no MSVC, and `windows-latest` would otherwise pay a C build on every
// run. Host code may compile an import of the native bindings (the app's
// wiring does), but no host test may rely on a native call succeeding.
//
// ZOD-EPH-002: the project's lock (native/swisseph/zodiann_swiss_lock.c) is
// compiled with the library, and TLSOFF gives it one state shared by every
// thread. An iOS target must do the same.
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Relative to this package's root: the project-authored native sources.
const _native = '../../native/swisseph';

/// The vendored, unmodified upstream source.
const _upstream = '$_native/upstream';

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

/// The locked entry points.
const _lock = '$_native/zodiann_swiss_lock.c';
const _lockHeader = '$_native/zodiann_swiss_lock.h';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    if (input.config.code.targetOS != OS.android) return;

    final builder = CBuilder.library(
      name: 'swisseph',
      // Must equal the asset id in tool/ffigen.dart's output and the
      // `@Native` bindings:
      // package:ephemeris_swiss/src/ffi/swisseph_bindings.g.dart
      assetName: 'src/ffi/swisseph_bindings.g.dart',
      sources: [for (final file in _sources) '$_upstream/$file', _lock],
      includes: [_native, _upstream],
      defines: {'TLSOFF': null},
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
    output.dependencies.addAll([
      for (final path in [_lock, _lockHeader]) input.packageRoot.resolve(path),
    ]);
  });
}
