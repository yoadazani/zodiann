// ZOD-FND-009: generates packages/shared_ui/lib/src/icons/zodiann_icons.g.dart
// from design-reference/zodiann/assets/icons/*.svg, the single source of
// truth. Run from the workspace root:
//
//   fvm dart run tool/gen_icons.dart          # write the generated file
//   fvm dart run tool/gen_icons.dart --check  # `melos run icons:check`
//
// Exit codes: 0 ok, 1 stale (--check), 2 unsupported icon source, 64 usage.
import 'dart:io';

import 'icons/icon_source_emitter.dart';
import 'icons/svg_icon.dart';

export 'icons/icon_source_emitter.dart' show generatedPath;

const iconsDir = 'design-reference/zodiann/assets/icons';

final _validName = RegExp(r'^[a-z][A-Za-z0-9]*$');

/// Dart reserved words, plus names that would clash with `ZodiannIcons`'
/// own members or Object's.
const _forbiddenNames = {
  'assert', 'break', 'case', 'catch', 'class', 'const', 'continue', //
  'default', 'do', 'else', 'enum', 'extends', 'false', 'final', 'finally',
  'for', 'if', 'in', 'is', 'new', 'null', 'rethrow', 'return', 'super',
  'switch', 'this', 'throw', 'true', 'try', 'var', 'void', 'while', 'with',
  'values', 'hashCode', 'runtimeType', 'toString', 'noSuchMethod',
};

/// The formatted generated library for the icons in [dir].
Future<String> generateIconsSource(Directory dir) async {
  // Every entry must be an icon: a stray file (star.SVG, notes.txt) is an
  // error, never silently skipped.
  final entries = dir.listSync();
  for (final entry in entries) {
    final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (entry is! File || !name.endsWith('.svg')) {
      throw IconGeneratorException(
        '$name in ${dir.path}: only <name>.svg icon files are allowed',
      );
    }
  }
  final files = entries.cast<File>().toList()
    ..sort((a, b) => _fileName(a).compareTo(_fileName(b)));
  if (files.isEmpty) {
    throw IconGeneratorException('no .svg files in ${dir.path}');
  }
  final icons = <SvgIcon>[];
  for (final file in files) {
    final fileName = _fileName(file);
    final name = fileName.substring(0, fileName.length - '.svg'.length);
    if (!_validName.hasMatch(name) || _forbiddenNames.contains(name)) {
      throw IconGeneratorException(
        '$fileName: the name must match ${_validName.pattern} and must not be '
        'a Dart reserved word or a ZodiannIcons member',
      );
    }
    icons.add(parseSvgIcon(name, file.readAsStringSync()));
  }
  return formatDart(emitIconsLibrary(icons));
}

String _fileName(File f) => f.uri.pathSegments.last;

/// 0 when [generated] matches the icons in [iconsDir] (line endings aside),
/// otherwise 1. Throws [IconGeneratorException] for an unsupported source.
Future<int> checkGenerated({
  required Directory iconsDir,
  required File generated,
}) async {
  final expected = await generateIconsSource(iconsDir);
  final actual = generated.existsSync()
      ? generated.readAsStringSync().replaceAll('\r\n', '\n')
      : null;
  if (actual != expected) {
    stderr.writeln(
      'Generated icons are stale; run: fvm dart run tool/gen_icons.dart',
    );
    return 1;
  }
  stdout.writeln('Generated icons are up to date.');
  return 0;
}

Future<void> main(List<String> arguments) async {
  var check = false;
  var icons = iconsDir;
  var out = generatedPath;
  for (final argument in arguments) {
    if (argument == '--check') {
      check = true;
    } else if (argument.startsWith('--icons-dir=')) {
      icons = argument.substring('--icons-dir='.length);
    } else if (argument.startsWith('--out=')) {
      out = argument.substring('--out='.length);
    } else {
      stderr.writeln(
        'usage: dart run tool/gen_icons.dart [--check] '
        '[--icons-dir=<dir>] [--out=<file>]',
      );
      exit(64);
    }
  }
  try {
    if (check) {
      exit(
        await checkGenerated(iconsDir: Directory(icons), generated: File(out)),
      );
    }
    final source = await generateIconsSource(Directory(icons));
    File(out).writeAsStringSync(source);
    stdout.writeln('Wrote $out.');
  } on IconGeneratorException catch (e) {
    stderr.writeln(e.message);
    exit(2);
  }
}
