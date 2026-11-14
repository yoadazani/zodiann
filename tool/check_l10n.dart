// ZOD-L10-001: `melos run l10n:check`. Regenerates shared_ui's committed
// gen-l10n output and fails if anything changed, because `flutter test` and
// `dart analyze` never regenerate it. Run from the workspace root.
import 'dart:io';

import 'l10n_snapshot.dart';

const _package = 'packages/shared_ui';

Future<void> main() async {
  final dir = Directory('$_package/lib/l10n');
  final before = snapshotGenerated(dir);
  final flutter = flutterExecutable(
    environment: Platform.environment,
    resolvedDartExecutable: Platform.resolvedExecutable,
    isWindows: Platform.isWindows,
  );
  final result = await Process.run(flutter, [
    'gen-l10n',
  ], workingDirectory: _package);
  if (result.exitCode != 0) {
    stderr
      ..writeln('flutter gen-l10n failed (${result.exitCode}):')
      ..write(result.stdout)
      ..write(result.stderr);
    exit(1);
  }
  final diff = snapshotDiff(before, snapshotGenerated(dir));
  if (diff.isNotEmpty) {
    stderr.writeln(
      'Generated localizations were stale and have been regenerated; '
      'commit them:',
    );
    for (final line in diff) {
      stderr.writeln('  $line');
    }
    exit(1);
  }
  stdout.writeln('Generated localizations are up to date.');
}
