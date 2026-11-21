// ZOD-EPH-004: compiles the project-authored shim (which includes the
// unmodified vendored astronomy-engine source) into `libastronomy` through
// Dart native assets. It builds for Android only, as ZOD-FND-003's hook does.
//
// For any other target (the host that runs `dart test` / `flutter test`, and
// iOS, which stays deferred) it adds no asset and returns at once, so host
// tests never need a C toolchain. Host tests must not import the native
// bindings.
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Relative to this package's root.
const _native = '../../native/astronomy_c';

/// The one source compiled: the shim, which `#include`s `upstream/astronomy.c`
/// (and, from Task 3 Step 1b, `zodiann_moon_rate.c`). Files the shim includes
/// are not compiled separately.
const _shim = '$_native/zodiann_astronomy_shim.c';

/// Files whose change must trigger a rebuild although the compiler is only
/// given the shim.
const _tracked = [
  '$_native/upstream/astronomy.c',
  '$_native/upstream/astronomy.h',
  '$_native/zodiann_astronomy_shim.h',
  '$_native/zodiann_moon_rate.c',
  '$_native/zodiann_moon_rate.h',
  '$_native/zodiann_moon_terms.h',
];

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    if (input.config.code.targetOS != OS.android) return;

    final builder = CBuilder.library(
      name: 'astronomy',
      // Must equal the asset id of the `@Native` bindings:
      // package:ephemeris_astronomy/src/ffi/astronomy_bindings.g.dart
      assetName: 'src/ffi/astronomy_bindings.g.dart',
      sources: [_shim],
      includes: [_native, '$_native/upstream'],
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
      for (final path in _tracked) input.packageRoot.resolve(path),
    ]);
  });
}
