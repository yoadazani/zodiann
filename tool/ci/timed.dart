// ZOD-FND-004: runs a command, records how long it took and exits with the
// command's own exit code.
//
//   dart run tool/ci/timed.dart <label> [--budget-seconds N] -- <command> [args...]
//
// Appends `label,seconds,exit` to the file named by CI_TIMING_FILE (default
// build/ci-timing.csv) and a table row to the file named by
// GITHUB_STEP_SUMMARY when set. Prints a GitHub warning annotation (never a
// failure) when the command ran longer than the budget. Exit codes: the
// command's own; 127 when the executable cannot be found; 2 on a usage error.
import 'dart:io';

import 'timing.dart';

const _usage =
    'usage: dart run tool/ci/timed.dart <label> [--budget-seconds N] '
    '-- <command> [args...]';

Future<void> main(List<String> args) async {
  final separator = args.indexOf('--');
  if (args.isEmpty || separator < 1 || separator == args.length - 1) {
    stderr.writeln(_usage);
    exit(2);
  }
  final label = args.first;
  int? budgetSeconds;
  final options = args.sublist(1, separator);
  if (options.isNotEmpty) {
    budgetSeconds = options.length == 2 && options.first == '--budget-seconds'
        ? int.tryParse(options.last)
        : null;
    if (budgetSeconds == null) {
      stderr.writeln(_usage);
      exit(2);
    }
  }
  final command = args.sublist(separator + 1);

  final environment = Platform.environment;
  final executable = resolveExecutable(
    command.first,
    environment,
    isWindows: Platform.isWindows,
  );
  var exitCode = 127;
  final stopwatch = Stopwatch()..start();
  if (executable == null) {
    stderr.writeln('${command.first}: command not found');
  } else {
    try {
      final process = await Process.start(
        executable,
        command.sublist(1),
        mode: ProcessStartMode.inheritStdio,
      );
      exitCode = await process.exitCode;
    } on ProcessException catch (error) {
      // Found but not startable (not executable, not a program): 126, as a
      // shell reports it.
      stderr.writeln('${command.first}: cannot execute: ${error.message}');
      exitCode = 126;
    }
  }
  stopwatch.stop();
  final elapsed = stopwatch.elapsed;

  final csvPath = environment['CI_TIMING_FILE'] ?? 'build/ci-timing.csv';
  _record(csvPath, () => formatCsvRow(label, elapsed, exitCode));
  final summaryPath = environment['GITHUB_STEP_SUMMARY'];
  if (summaryPath != null && summaryPath.isNotEmpty) {
    _record(summaryPath, () {
      final file = File(summaryPath);
      final hasHeader =
          file.existsSync() &&
          file.readAsLinesSync().any((line) => line.startsWith('| Step |'));
      return (hasHeader ? '' : summaryHeader) +
          formatSummaryRow(label, elapsed, exitCode);
    });
  }
  final warning = budgetWarning(label, elapsed, budgetSeconds);
  if (warning != null) stdout.writeln(warning);
  exit(exitCode);
}

/// Appends [text] to [path]. Recording is best effort: a failure to write is
/// reported on stderr and never changes the wrapped command's exit code.
void _record(String path, String Function() text) {
  try {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(text(), mode: FileMode.append);
  } on FileSystemException catch (error) {
    stderr.writeln(
      'tool/ci/timed.dart: could not write $path: ${error.message}',
    );
  }
}
