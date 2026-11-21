// ZOD-EPH-004: generates lib/src/ffi/astronomy_bindings.g.dart from the
// project-authored shim header. Run from this package's root:
//
//   dart run tool/ffigen.dart
//
// Needs libclang (LLVM 18 or newer). The header declares plain int and double
// arguments and includes no system header, so no target or sysroot is needed.
// The output is committed; re-run only when the shim header changes. The asset
// id of the generated bindings must stay equal to hook/build.dart's
// `assetName`: package:ephemeris_astronomy/src/ffi/astronomy_bindings.g.dart.
import 'dart:io';

import 'package:ffigen/ffigen.dart';

/// The C functions bound.
const _functions = {
  'zodiann_body_state',
  // Test-only (Task 3 Step 1b).
  'zodiann_test_moon_series',
  'zodiann_test_moon_state',
};

Future<void> main() async {
  final packageRoot = Platform.script.resolve('../');
  final generator = FfiGenerator(
    output: Output(
      dart: DartOutput(
        path: packageRoot.resolve('lib/src/ffi/astronomy_bindings.g.dart'),
      ),
    ),
    input: Input(
      entryPoints: [
        packageRoot.resolve(
          '../../native/astronomy_c/zodiann_astronomy_shim.h',
        ),
      ],
    ),
    visitors: [
      Visitor(func: (node) => node.isIncluded = _functions.contains(node.name)),
    ],
  );
  await generator.generate();
}
