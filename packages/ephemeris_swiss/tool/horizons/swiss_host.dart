// ZOD-TST-001: compiles a host C tool of this package against the unmodified
// vendored Swiss Ephemeris source and runs it. Needs `gcc` on the PATH. Host
// tooling only, never part of the app. The flags and sources are those of
// tool/fetch_horizons_tt_reference.dart (ZOD-EPH-002).
import 'dart:io';

import 'package:ephemeris_swiss/ephemeris_swiss.dart';

/// Runs a program to its end, as [Process.runSync] does.
typedef ProcessRunner = ProcessResult Function(
  String executable,
  List<String> arguments,
);

/// The nine library objects named by upstream's `Makefile`.
const _librarySources = [
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

/// Compiles `tool/[cFileName]` of the package at [packageRoot] against the
/// vendored source, runs it with [arguments], and returns the non-empty lines of
/// its standard output, trimmed.
///
/// Throws [StateError] if compiling or running exits non-zero.
List<String> runSwissHostTool(
  Uri packageRoot,
  String cFileName,
  List<String> arguments, {
  ProcessRunner run = Process.runSync,
}) {
  final workDir = Directory.systemTemp.createTempSync('swiss_host_tool');
  try {
    final upstream = packageRoot.resolve('../../native/swisseph/upstream/');
    final executable =
        '${workDir.path}${Platform.pathSeparator}'
        '${cFileName.replaceFirst('.c', '')}';
    final compile = run('gcc', [
      '-O1',
      '-std=gnu99',
      '-I',
      upstream.toFilePath(),
      '-o',
      executable,
      packageRoot.resolve('tool/$cFileName').toFilePath(),
      for (final source in _librarySources)
        upstream.resolve(source).toFilePath(),
      '-lm',
    ]);
    if (compile.exitCode != 0) {
      throw StateError('gcc failed:\n${compile.stdout}\n${compile.stderr}');
    }
    final result = run(executable, arguments);
    if (result.exitCode != 0) {
      throw StateError('$cFileName failed: ${result.stderr}');
    }
    return [
      for (final line in (result.stdout as String).split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
  } finally {
    workDir.deleteSync(recursive: true);
  }
}

/// The delta T, in seconds, that the vendored library applies with the packaged
/// data files at each of [instants] read as UT, from `tool/tt_grid.c`.
///
/// Throws [StateError] unless the tool prints one line per instant.
List<double> libraryDeltaTSeconds(
  Uri packageRoot,
  List<DateTime> instants, {
  ProcessRunner run = Process.runSync,
}) {
  final lines = runSwissHostTool(packageRoot, 'tt_grid.c', [
    packageRoot.resolve('assets/ephe').toFilePath(),
    for (final instant in instants) '${julianDayUt(instant)}',
  ], run: run);
  if (lines.length != instants.length) {
    throw StateError(
      'tt_grid printed ${lines.length} lines for ${instants.length} instants',
    );
  }
  return [for (final line in lines) double.parse(line)];
}
