// ZOD-L10-001: ARB helpers for l10n_key_parity_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

String _yamlValue(String packageDir, String yaml, String key) {
  final m = RegExp('^$key:\\s*(\\S+)\\s*\$', multiLine: true).firstMatch(yaml);
  if (m == null) fail('$packageDir/l10n.yaml has no $key');
  return m.group(1)!;
}

/// ZOD-L10-014: the template file name and the raw source of every
/// `app_<locale>.arb` in [packageDir]'s `arb-dir`, per its `l10n.yaml`.
/// Fails (naming the file) if `l10n.yaml` lacks `arb-dir` or
/// `template-arb-file`. Other files in the directory are ignored.
({String template, Map<String, String> sources}) loadArbSources(
  String packageDir,
) {
  final yaml = File('$packageDir/l10n.yaml').readAsStringSync();
  final arbDir = _yamlValue(packageDir, yaml, 'arb-dir');
  final template = _yamlValue(packageDir, yaml, 'template-arb-file');
  return (
    template: template,
    sources: {
      for (final f in Directory(
        '$packageDir/$arbDir',
      ).listSync().whereType<File>())
        if (RegExp(r'^app_[A-Za-z_]+\.arb$').hasMatch(f.uri.pathSegments.last))
          f.uri.pathSegments.last: f.readAsStringSync(),
    },
  );
}

Map<String, dynamic> _object(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('the top level is not a JSON object');
  }
  return decoded;
}

/// The message keys of an ARB file: top-level keys not starting with `@`.
/// Throws [FormatException] on invalid JSON or a non-object top level.
Set<String> arbMessageKeys(String json) => {
  for (final key in _object(json).keys)
    if (!key.startsWith('@')) key,
};

/// The file's `@@locale`, or null.
String? arbLocale(String json) => _object(json)['@@locale'] as String?;

/// Whether [key] has an `@key` entry with a non-empty `description`.
bool arbHasDescription(String json, String key) {
  final meta = _object(json)['@$key'];
  return meta is Map &&
      meta['description'] is String &&
      (meta['description'] as String).isNotEmpty;
}

/// One line per file whose keys differ from [template]'s, sorted by file,
/// keys sorted within a line: `<file> is missing: …` and
/// `<file> has keys not in <template>: …`.
List<String> keyParityProblems(
  String template,
  Map<String, Set<String>> keysByFile,
) {
  final expected = keysByFile[template]!;
  final files = keysByFile.keys.where((f) => f != template).toList()..sort();
  String list(Iterable<String> keys) => (keys.toList()..sort()).join(', ');
  return [
    for (final file in files) ...[
      if (expected.difference(keysByFile[file]!) case final missing
          when missing.isNotEmpty)
        '$file is missing: ${list(missing)}',
      if (keysByFile[file]!.difference(expected) case final extra
          when extra.isNotEmpty)
        '$file has keys not in $template: ${list(extra)}',
    ],
  ];
}
