// ZOD-FND-008: renders the Android and iOS launcher icons from the logo SVGs
// in design-reference/zodiann/assets with headless Chrome, and records them in
// tool/launcher/manifest.json. Run from the workspace root:
//
//   fvm dart run tool/launcher/gen_launcher_icons.dart [--check]
//       [--source-dir=<dir>] [--root=<dir>]
//
// --check recomputes the source hashes, the expected output list and every
// output file's hash, and fails if anything differs from the manifest. It
// needs no Chrome, so it is fast and deterministic (`melos run launcher:check`).
//
// --source-dir (default design-reference/zodiann/assets) holds the SVGs.
// --root (default .) is what the output paths and the manifest resolve
// against (the tests point it at a temp copy).
//
// Chrome is C:/Program Files/Google/Chrome/Application/chrome.exe unless the
// CHROME environment variable names another executable.
//
// Exit codes: 0 up to date, 1 stale or missing (--check), 2 bad input or a
// failed render, 64 usage.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

import 'launcher_spec.dart';

const defaultSourceDir = 'design-reference/zodiann/assets';
const manifestPath = 'tool/launcher/manifest.json';
const specPath = 'tool/launcher/launcher_spec.dart';
const _tiledName = 'zodiann-logo.svg';
const _onDarkName = 'zodiann-logo-on-dark.svg';
const _defaultChrome = 'C:/Program Files/Google/Chrome/Application/chrome.exe';

String _lf(String s) => s.replaceAll('\r\n', '\n');

String _hashText(String text) =>
    sha256.convert(utf8.encode(_lf(text))).toString();

String _hashBytes(List<int> bytes) => sha256.convert(bytes).toString();

String _readSource(String sourceDir, String name) {
  final file = File('$sourceDir/$name');
  if (!file.existsSync()) {
    throw LauncherException('Missing source SVG: ${file.path}.');
  }
  return file.readAsStringSync();
}

/// The SHA-256 (LF-normalised) of each SVG the launcher icons come from.
Map<String, String> sourceHashes(String sourceDir) => {
  for (final name in [_tiledName, _onDarkName])
    name: _hashText(_readSource(sourceDir, name)),
};

/// Checks the committed outputs against the manifest (no Chrome). Returns the
/// exit code: 0 up to date, 1 stale or missing, 2 bad input.
Future<int> checkLauncher({
  required String sourceDir,
  required String root,
}) async {
  try {
    final tiled = _readSource(sourceDir, _tiledName);
    final onDark = _readSource(sourceDir, _onDarkName);
    // The sources must still have the shape the generator relies on.
    fullBleedSvg(tiled);
    backgroundSvg(tiled);
    foregroundSvg(onDark, 108);

    final contents = File('$root/$iosContentsPath');
    if (!contents.existsSync()) {
      throw LauncherException('Missing ${contents.path}.');
    }
    final outputs = launcherOutputs(contents.readAsStringSync());
    final manifestFile = File('$root/$manifestPath');
    if (!manifestFile.existsSync()) {
      stderr.writeln('Missing $manifestPath. Run: ${_regenerate()}');
      return 1;
    }
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
    final problems = <String>[];

    final recordedSources = (manifest['sources'] as Map?)
        ?.cast<String, String>();
    sourceHashes(sourceDir).forEach((name, hash) {
      if (recordedSources?[name] != hash) problems.add('$name changed.');
    });

    final spec = File('$root/$specPath');
    if (!spec.existsSync() ||
        manifest['spec'] != _hashText(spec.readAsStringSync())) {
      problems.add('$specPath changed.');
    }

    final recorded =
        (manifest['outputs'] as Map?)?.cast<String, Object?>() ?? {};
    final expected = {for (final o in outputs) o.path};
    for (final path in recorded.keys.where((p) => !expected.contains(p))) {
      problems.add('$path is in the manifest but no longer an output.');
    }
    for (final o in outputs) {
      final entry = recorded[o.path] as Map<String, Object?>?;
      final file = File('$root/${o.path}');
      if (entry == null) {
        problems.add('${o.path} is missing from the manifest.');
      } else if (!file.existsSync()) {
        problems.add('${o.path} is missing.');
      } else if (entry['pixels'] != o.pixels) {
        problems.add(
          '${o.path} is recorded at ${entry['pixels']} px, expected ${o.pixels}.',
        );
      } else if (entry['sha256'] != _hashBytes(file.readAsBytesSync())) {
        problems.add('${o.path} was changed.');
      }
    }

    if (problems.isEmpty) return 0;
    stderr.writeln(
      'The launcher icons are stale:\n  ${problems.join('\n  ')}\n'
      'Regenerate: ${_regenerate()}',
    );
    return 1;
  } on LauncherException catch (e) {
    stderr.writeln(e.message);
    return 2;
  }
}

String _regenerate() => 'fvm dart run tool/launcher/gen_launcher_icons.dart';

/// Renders [svg] at [px] × [px] with headless Chrome into [png].
Future<void> _render(
  String chrome,
  Directory temp,
  String svg,
  int px,
  File png,
) async {
  final html = File('${temp.path}/${png.uri.pathSegments.last}.html')
    ..writeAsStringSync(
      '<!doctype html><html><head><meta charset="utf-8"><style>'
      'html,body{margin:0;padding:0;background:transparent}'
      'svg{display:block}</style></head><body>$svg</body></html>',
    );
  if (png.existsSync()) png.deleteSync();
  png.parent.createSync(recursive: true);
  final result = await Process.run(chrome, [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--force-device-scale-factor=1',
    '--force-color-profile=srgb',
    '--default-background-color=00000000',
    '--window-size=$px,$px',
    '--screenshot=${png.absolute.path}',
    html.absolute.uri.toString(),
  ]);
  if (!png.existsSync()) {
    throw LauncherException('Chrome wrote no ${png.path}:\n${result.stderr}');
  }
}

/// [pngBytes] as an RGB PNG (no alpha channel); fails unless every pixel is
/// fully opaque.
Uint8List _opaqueRgb(String path, Uint8List pngBytes) {
  final image = img.decodePng(pngBytes);
  if (image == null) throw LauncherException('$path is not a PNG.');
  for (final p in image) {
    if (p.a != image.maxChannelValue) {
      throw LauncherException(
        '$path has a transparent pixel at (${p.x}, ${p.y}); it must be '
        'opaque (the full-bleed render is wrong).',
      );
    }
  }
  return img.encodePng(image.convert(numChannels: 3));
}

/// Renders every output and writes the manifest. Returns the exit code.
Future<int> generateLauncher({
  required String sourceDir,
  required String root,
  required String chrome,
}) async {
  final temp = Directory.systemTemp.createTempSync('zod_launcher_');
  try {
    final tiled = _readSource(sourceDir, _tiledName);
    final onDark = _readSource(sourceDir, _onDarkName);
    final outputs = launcherOutputs(
      File('$root/$iosContentsPath').readAsStringSync(),
    );
    final recorded = <String, Object?>{};
    for (final o in outputs) {
      final svg = switch (o.kind) {
        LauncherKind.iosIcon => sizedSvg(fullBleedSvg(tiled), o.pixels),
        LauncherKind.androidLegacy => sizedSvg(tiled, o.pixels),
        LauncherKind.androidForeground => foregroundSvg(onDark, o.pixels),
        LauncherKind.androidBackground => sizedSvg(
          backgroundSvg(tiled),
          o.pixels,
        ),
      };
      final raw = File('${temp.path}/raw_${o.path.hashCode}.png');
      await _render(chrome, temp, svg, o.pixels, raw);
      var bytes = raw.readAsBytesSync();
      if (o.kind == LauncherKind.iosIcon ||
          o.kind == LauncherKind.androidBackground) {
        bytes = _opaqueRgb(o.path, bytes);
      }
      final out = File('$root/${o.path}');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes);
      recorded[o.path] = {'pixels': o.pixels, 'sha256': _hashBytes(bytes)};
      stdout.writeln('Wrote ${o.path} (${o.pixels} px).');
    }
    final version = await Process.run(chrome, ['--version']);
    final manifest = {
      'chrome':
          RegExp(r'[\d.]+').firstMatch('${version.stdout}')?.group(0) ??
          'unknown',
      'sources': sourceHashes(sourceDir),
      'spec': _hashText(File('$root/$specPath').readAsStringSync()),
      'outputs': recorded,
    };
    File('$root/$manifestPath').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    );
    stdout.writeln('Wrote $manifestPath.');
    return 0;
  } on LauncherException catch (e) {
    stderr.writeln(e.message);
    return 2;
  } finally {
    temp.deleteSync(recursive: true);
  }
}

Future<void> main(List<String> args) async {
  var check = false;
  var sourceDir = defaultSourceDir;
  var root = '.';
  for (final arg in args) {
    if (arg == '--check') {
      check = true;
    } else if (arg.startsWith('--source-dir=')) {
      sourceDir = arg.substring('--source-dir='.length);
    } else if (arg.startsWith('--root=')) {
      root = arg.substring('--root='.length);
    } else {
      stderr.writeln(
        'usage: dart run tool/launcher/gen_launcher_icons.dart [--check] '
        '[--source-dir=<dir>] [--root=<dir>]',
      );
      exit(64);
    }
  }
  exit(
    check
        ? await checkLauncher(sourceDir: sourceDir, root: root)
        : await generateLauncher(
            sourceDir: sourceDir,
            root: root,
            chrome: Platform.environment['CHROME'] ?? _defaultChrome,
          ),
  );
}
