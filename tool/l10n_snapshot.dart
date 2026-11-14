// ZOD-L10-001: pure helpers for tool/check_l10n.dart (`melos run l10n:check`).
import 'dart:io';

/// Every `*.dart` file directly in [l10nDir], by basename, with `\r\n`
/// normalised to `\n`: a CRLF checkout (core.autocrlf) equals gen-l10n's LF
/// output.
Map<String, String> snapshotGenerated(Directory l10nDir) => {
  for (final file in l10nDir.listSync().whereType<File>())
    if (file.path.endsWith('.dart'))
      file.uri.pathSegments.last: file.readAsStringSync().replaceAll(
        '\r\n',
        '\n',
      ),
};

/// `changed: <name>`, `added: <name>` or `removed: <name>` for every file
/// that differs between [before] and [after], sorted by name; empty when the
/// snapshots are equal.
List<String> snapshotDiff(
  Map<String, String> before,
  Map<String, String> after,
) {
  final names = {...before.keys, ...after.keys}.toList()..sort();
  return [
    for (final name in names)
      if (!before.containsKey(name))
        'added: $name'
      else if (!after.containsKey(name))
        'removed: $name'
      else if (before[name] != after[name])
        'changed: $name',
  ];
}

/// The pinned Flutter: `<MELOS_SDK_PATH>/bin/flutter` when Melos runs the
/// script, otherwise the `bin/flutter` of the SDK whose
/// `bin/cache/dart-sdk/bin/dart` is running. Never the global Flutter on
/// PATH. `.bat` on Windows.
String flutterExecutable({
  required Map<String, String> environment,
  required String resolvedDartExecutable,
  required bool isWindows,
}) {
  final sep = isWindows ? r'\' : '/';
  final suffix = isWindows ? '.bat' : '';
  final melos = environment['MELOS_SDK_PATH'];
  if (melos != null && melos.isNotEmpty) {
    return '$melos${sep}bin${sep}flutter$suffix';
  }
  var dir = resolvedDartExecutable;
  // dart → dart-sdk/bin → dart-sdk → cache → <sdk>/bin
  for (var i = 0; i < 4; i++) {
    dir = dir.substring(0, dir.lastIndexOf(RegExp(r'[\\/]')));
  }
  return '$dir${sep}flutter$suffix';
}
