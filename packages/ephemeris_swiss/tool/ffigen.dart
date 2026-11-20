// ZOD-FND-003: generates lib/src/ffi/swisseph_bindings.g.dart from the
// vendored, unmodified Swiss Ephemeris header. Run from this package's root:
//
//   dart run tool/ffigen.dart
//
// Needs libclang (LLVM 18 or newer) and the Android NDK. The header is parsed
// as Android (arm64, API 24) against the NDK sysroot, so `sweodef.h` takes its
// POSIX branch and not the `_WIN32` one that needs `wtypes.h` (the host is
// Windows). The bound functions have only int, double and char* parameters, so
// the parse target does not change the generated Dart. The output is
// committed; re-run only when the set of bound functions changes. The asset id
// of the generated bindings must stay equal to hook/build.dart's `assetName`:
// package:ephemeris_swiss/src/ffi/swisseph_bindings.g.dart.
import 'dart:io';

import 'package:ffigen/ffigen.dart';

/// The only C functions the spike binds.
const _functions = {
  'swe_set_ephe_path',
  'swe_close',
  'swe_version',
  'swe_calc_ut',
};

const _ndkVersion = '28.2.13676358';

String _ndkRoot() {
  final sdk =
      Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'] ??
      '${Platform.environment['LOCALAPPDATA']}/Android/Sdk';
  final root = '$sdk/ndk/$_ndkVersion/toolchains/llvm/prebuilt/windows-x86_64';
  if (!Directory('$root/sysroot').existsSync()) {
    stderr.writeln('Android NDK $_ndkVersion not found at $root.');
    exit(2);
  }
  return root;
}

/// clang's own builtin headers (float.h, stddef.h ...), one directory per
/// clang version inside the NDK.
String _clangIncludes(String ndkRoot) {
  final versions = Directory('$ndkRoot/lib/clang')
      .listSync()
      .whereType<Directory>();
  return '${versions.first.path}/include';
}

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
        packageRoot.resolve('../../native/swisseph/upstream/swephexp.h'),
      ],
      compilerOptions: [
        '--target=aarch64-linux-android24',
        '--sysroot=${_ndkRoot()}/sysroot',
        '-isystem',
        _clangIncludes(_ndkRoot()),
      ],
      appendCompilerOptions: true,
    ),
    visitors: [
      Visitor(func: (node) => node.isIncluded = _functions.contains(node.name)),
    ],
  );
  await generator.generate();
}
