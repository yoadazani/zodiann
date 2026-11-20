// ZOD-FND-004: the pure and near-pure parts of the CI step timer
// (tool/ci/timed.dart): row formatting, the budget warning and executable
// discovery. Kept free of process spawning so the tests can reach them.
import 'dart:io';

String _seconds(Duration elapsed) =>
    (elapsed.inMilliseconds / 1000).toStringAsFixed(1);

/// One CSV row: `label,<seconds, one decimal>,<exit code>`.
String formatCsvRow(String label, Duration elapsed, int exitCode) =>
    '$label,${_seconds(elapsed)},$exitCode\n';

/// One Markdown table row for the GitHub job summary.
String formatSummaryRow(String label, Duration elapsed, int exitCode) {
  final result = exitCode == 0 ? 'ok' : 'FAILED ($exitCode)';
  return '| $label | ${_seconds(elapsed)} s | $result |\n';
}

/// The header of the summary table; written once per summary file.
const summaryHeader = '| Step | Time | Result |\n| --- | --- | --- |\n';

/// A non-failing GitHub warning annotation when [elapsed] exceeds the budget,
/// else null (also null with no budget, and exactly at the budget).
String? budgetWarning(String label, Duration elapsed, int? budgetSeconds) {
  if (budgetSeconds == null || elapsed <= Duration(seconds: budgetSeconds)) {
    return null;
  }
  return '::warning title=CI runtime budget::'
      '$label took ${_seconds(elapsed)} s, budget $budgetSeconds s';
}

/// Finds [name] the way a shell would: a name with a directory part is taken
/// as is, otherwise each `PATH` entry is searched. On Windows `PATHEXT` is
/// honoured (so `flutter` finds `flutter.bat`) and tried before the bare name
/// (Flutter's `bin/` also holds extensionless shell scripts). Returns null
/// when nothing exists; the caller maps that to exit code 127 itself, because
/// `Process.start` reports a missing program differently per platform.
String? resolveExecutable(
  String name,
  Map<String, String> environment, {
  required bool isWindows,
}) {
  final separators = isWindows ? r'/\' : '/';
  final hasDirectory = name.split('').any(separators.contains);
  final pathKey = environment.keys.firstWhere(
    (key) => isWindows ? key.toUpperCase() == 'PATH' : key == 'PATH',
    orElse: () => 'PATH',
  );
  final pathSeparator = isWindows ? ';' : ':';
  final directories = hasDirectory
      ? ['']
      : (environment[pathKey] ?? '')
            .split(pathSeparator)
            .where((dir) => dir.isNotEmpty)
            .toList();
  final extensions = isWindows
      ? [
          ...(environment['PATHEXT'] ?? '.COM;.EXE;.BAT;.CMD')
              .split(';')
              .where((ext) => ext.isNotEmpty),
          '',
        ]
      : [''];
  for (final directory in directories) {
    final base = directory.isEmpty
        ? name
        : '$directory${isWindows ? r'\' : '/'}$name';
    for (final extension in extensions) {
      if (File('$base$extension').existsSync()) return '$base$extension';
    }
  }
  return null;
}
