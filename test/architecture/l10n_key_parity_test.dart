// ZOD-L10-001 (L-8): a test fails when a translation key exists in one
// language file but not another. Every app_*.arb in shared_ui's arb-dir is
// checked against the template, so a future language (L-1) is covered by
// adding its file. Runs from the workspace root on every `melos run test`.
import 'dart:io';

import 'package:test/test.dart';

import 'arb_keys.dart';

const _package = 'packages/shared_ui';

String _yamlValue(String yaml, String key) {
  final m = RegExp('^$key:\\s*(\\S+)\\s*\$', multiLine: true).firstMatch(yaml);
  if (m == null) fail('$_package/l10n.yaml has no $key');
  return m.group(1)!;
}

void main() {
  late String template;
  late Map<String, String> sources;

  setUpAll(() {
    final yaml = File('$_package/l10n.yaml').readAsStringSync();
    final arbDir = _yamlValue(yaml, 'arb-dir');
    template = _yamlValue(yaml, 'template-arb-file');
    sources = {
      for (final f in Directory(
        '$_package/$arbDir',
      ).listSync().whereType<File>())
        if (RegExp(r'^app_[A-Za-z_]+\.arb$').hasMatch(f.uri.pathSegments.last))
          f.uri.pathSegments.last: f.readAsStringSync(),
    };
  });

  /// [read] on [file]'s source; a malformed file fails naming the file.
  T parse<T>(String file, T Function(String json) read) {
    try {
      return read(sources[file]!);
    } on FormatException catch (e) {
      fail('$file is not a valid ARB JSON object: ${e.message}');
    }
  }

  test('the template and at least en + he exist', () {
    expect(sources.keys, containsAll({template, 'app_en.arb', 'app_he.arb'}));
  });

  test('every ARB file is a valid JSON object', () {
    for (final file in sources.keys) {
      parse(file, arbMessageKeys);
    }
  });

  test("every ARB file's @@locale matches its filename", () {
    for (final file in sources.keys) {
      final expected = file.substring('app_'.length, file.length - 4);
      expect(
        parse(file, arbLocale),
        expected,
        reason: '$file: @@locale must be present and equal "$expected"',
      );
    }
  });

  test("every language has exactly the template's keys", () {
    final problems = keyParityProblems(template, {
      for (final file in sources.keys) file: parse(file, arbMessageKeys),
    });
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('every template key has @key metadata with a description', () {
    final missing = [
      for (final key in parse(template, arbMessageKeys))
        if (!parse(template, (s) => arbHasDescription(s, key))) key,
    ];
    expect(
      missing,
      isEmpty,
      reason: '$template: add "@<key>": {"description"}',
    );
  });
}
