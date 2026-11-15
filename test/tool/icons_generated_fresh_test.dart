// ZOD-FND-009: the committed generated icon code matches the source SVGs
// (the same check as `melos run icons:check`, on every `melos run test`), and
// the SVGs match the second source, kit.js's IC table.
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/gen_icons.dart';
import '../../tool/icons/svg_icon.dart';

String _lf(String s) => s.replaceAll('\r\n', '\n');

List<File> _svgFiles() =>
    Directory(iconsDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'))
        .toList();

String _nameOf(File f) => f.uri.pathSegments.last.replaceAll('.svg', '');

/// A temp copy of the real icons and generated file.
({Directory icons, File generated}) _tempCopy() {
  final root = Directory.systemTemp.createTempSync('zod_icons_');
  addTearDown(() => root.deleteSync(recursive: true));
  final icons = Directory('${root.path}/icons')..createSync();
  for (final f in _svgFiles()) {
    f.copySync('${icons.path}/${f.uri.pathSegments.last}');
  }
  final generated = File('${root.path}/zodiann_icons.g.dart');
  File(generatedPath).copySync(generated.path);
  return (icons: icons, generated: generated);
}

Directory _tempIcons(Map<String, String> files) {
  final dir = Directory.systemTemp.createTempSync('zod_icons_');
  addTearDown(() => dir.deleteSync(recursive: true));
  files.forEach((name, content) {
    File('${dir.path}/$name').writeAsStringSync(content);
  });
  return dir;
}

const _validSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
    'viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" '
    'stroke-linecap="round" stroke-linejoin="round"><path d="M1 1h1"/></svg>';

void main() {
  test('the committed generated file is up to date', () async {
    final generated = await generateIconsSource(Directory(iconsDir));
    expect(generated, _lf(File(generatedPath).readAsStringSync()));
  });

  test('33 icons, named as the files', () {
    final files = _svgFiles();
    expect(files, hasLength(33));
    final source = File(generatedPath).readAsStringSync();
    for (final f in files) {
      expect(
        source,
        contains('static const ZodiannIconData ${_nameOf(f)} ='),
        reason: _nameOf(f),
      );
    }
  });

  test('second source: kit.js IC matches the SVG files', () {
    final kit = File('design-reference/zodiann/_source/kit.js')
        .readAsStringSync();
    final start = kit.indexOf('const IC = {');
    final end = kit.indexOf('};', start);
    expect(start, greaterThanOrEqualTo(0));
    final entries = {
      for (final m in RegExp(
        r"(\w+): '([^']*)'",
      ).allMatches(kit.substring(start, end)))
        m[1]!: m[2]!,
    };
    final files = {
      for (final f in _svgFiles()) _nameOf(f): _lf(f.readAsStringSync()),
    };
    expect(entries.keys.toSet(), files.keys.toSet());
    files.forEach((name, svg) {
      final inner = svg
          .substring(svg.indexOf('>') + 1, svg.lastIndexOf('</svg>'))
          .trim();
      expect(inner, entries[name], reason: name);
    });
  });

  group('--check', () {
    test('exits 0 on the real tree', () async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'tool/gen_icons.dart',
        '--check',
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(result.stdout, contains('Generated icons are up to date.'));
    });

    test('exits 1 on a stale file', () async {
      final copy = _tempCopy();
      final text = copy.generated.readAsStringSync();
      final i = text.indexOf('IconMoveTo(') + 'IconMoveTo('.length;
      final digit = text[i] == '1' ? '2' : '1';
      copy.generated.writeAsStringSync(text.replaceRange(i, i + 1, digit));
      expect(
        await checkGenerated(iconsDir: copy.icons, generated: copy.generated),
        1,
      );
    });

    test('exits 1 on a missing file', () async {
      final copy = _tempCopy();
      copy.generated.deleteSync();
      expect(
        await checkGenerated(iconsDir: copy.icons, generated: copy.generated),
        1,
      );
    });

    test('a CRLF checkout of a fresh file is up to date', () async {
      final copy = _tempCopy();
      copy.generated.writeAsStringSync(
        _lf(copy.generated.readAsStringSync()).replaceAll('\n', '\r\n'),
      );
      expect(
        await checkGenerated(iconsDir: copy.icons, generated: copy.generated),
        0,
      );
    });
  });

  group('invalid icon names fail', () {
    for (final name in ['Bad', '9a', 'class', 'values', 'hashCode', 'a-b']) {
      test('$name.svg', () {
        final dir = _tempIcons({'$name.svg': _validSvg});
        expect(
          () => generateIconsSource(dir),
          throwsA(
            isA<IconGeneratorException>().having(
              (e) => e.message,
              'message',
              contains('$name.svg'),
            ),
          ),
        );
      });
    }

    test('an empty directory', () {
      final dir = _tempIcons({});
      expect(
        () => generateIconsSource(dir),
        throwsA(
          isA<IconGeneratorException>().having(
            (e) => e.message,
            'message',
            contains(dir.path),
          ),
        ),
      );
    });
  });

  test('an unsupported file fails the generator with exit 2', () async {
    final dir = _tempIcons({
      'bad.svg': _validSvg.replaceFirst('<path d="M1 1h1"/>', '<g/>'),
    });
    final out = File('${dir.path}/out.g.dart');
    expect(
      () => checkGenerated(iconsDir: dir, generated: out),
      throwsA(isA<IconGeneratorException>()),
    );
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'tool/gen_icons.dart',
      '--check',
      '--icons-dir=${dir.path}',
      '--out=${out.path}',
    ]);
    expect(result.exitCode, 2, reason: '${result.stdout}${result.stderr}');
    expect(result.stderr, contains('bad.svg'));
  });

  test('an unknown argument exits 64', () async {
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'tool/gen_icons.dart',
      '--nope',
    ]);
    expect(result.exitCode, 64);
  });
}
