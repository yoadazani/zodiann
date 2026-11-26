// ZOD-EPH-002: generates lib/src/ffi/swisseph_bindings.g.dart from the
// project-authored lock header, so Dart can reach only the locked functions.
// Run from this package's root:
//
//   dart run tool/ffigen.dart
//
// Needs libclang (LLVM 18 or newer). The header declares plain int, double and
// char arguments and includes no system header, so no target or sysroot is
// needed. The output is committed; re-run only when the lock header changes.
// The asset id of the generated bindings must stay equal to hook/build.dart's
// `assetName`: package:ephemeris_swiss/src/ffi/swisseph_bindings.g.dart.
import 'dart:io';

import 'package:ffigen/ffigen.dart';

/// The C functions bound.
const _functions = {
  'zodiann_swiss_version',
  'zodiann_swiss_set_ephe_path',
  'zodiann_swiss_close',
  'zodiann_swiss_calc_ut',
  'zodiann_swiss_calc_tt',
};

Future<void> main() async {
  final packageRoot = Platform.script.resolve('../');
  final generator = FfiGenerator(
    output: Output(
      dart: DartOutput(
        path: packageRoot.resolve('lib/src/ffi/swisseph_bindings.g.dart'),
      ),
    ),
    input: Input(
      entryPoints: [
        packageRoot.resolve('../../native/swisseph/zodiann_swiss_lock.h'),
      ],
    ),
    visitors: [
      Visitor(func: (node) => node.isIncluded = _functions.contains(node.name)),
    ],
  );
  await generator.generate();
}
