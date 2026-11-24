// ZOD-UI-013: renders the delete-confirmation dialog's visual references with
// headless Chrome, straight from the design kit
// (`_source/settings.html?lang=<lang>&theme=<theme>&dialog=delete`, kit.css
// and kit.js; the designer's own render job is the dark English one in
// `_source/render/jobs.json`). Run manually from the workspace root when the
// kit changes (not part of lint / test):
//
//   fvm dart run tool/dialog/render_dialog_references.dart
//
// Chrome is C:/Program Files/Google/Chrome/Application/chrome.exe unless the
// CHROME environment variable names another executable.
//
// These are GENERATED visual references, not designer-provided assets:
// kit.css and MASTER.md remain authoritative, and the images never override
// them. The designer's own PNG (screens/04-settings_delete-dialog_desktop_en_
// dark.png) stays the oracle for the dark English dialog; this tool exists to
// produce the light and the Hebrew dialogs the designer did not render (the
// task's "both themes" criterion), and its dark English output proves it
// reproduces the designer's image.
//
// Writes packages/shared_ui/test/fixtures/dialog/generated_<theme>_<lang>_
// desktop.png (1440 x 900 @1, the designer renderer's device) and
// manifest.json (Chrome version, SHA-256 of every file the renders depend on,
// LF-normalised).
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _kit = 'design-reference/zodiann/_source';
const _assets = 'design-reference/zodiann/assets';
const _outDir = 'packages/shared_ui/test/fixtures/dialog';
const _defaultChrome = 'C:/Program Files/Google/Chrome/Application/chrome.exe';

const _width = 1440;
const _height = 900;
const _themes = ['dark', 'light'];
const _langs = ['en', 'he'];

/// Every file a render depends on (hashed into the manifest).
const _inputs = [
  '$_kit/settings.html',
  '$_kit/kit.css',
  '$_kit/kit.js',
  '$_assets/fonts/fonts.css',
  '$_assets/zodiann-logo-on-dark.svg',
  '$_assets/zodiann-logo-on-light.svg',
];

Future<void> main() async {
  final chrome = Platform.environment['CHROME'] ?? _defaultChrome;
  Directory(_outDir).createSync(recursive: true);
  for (final theme in _themes) {
    for (final lang in _langs) {
      await _render(chrome, theme, lang);
    }
  }
  await _writeManifest(chrome);
}

Future<void> _render(String chrome, String theme, String lang) async {
  final png = File('$_outDir/generated_${theme}_${lang}_desktop.png');
  if (png.existsSync()) png.deleteSync();
  final url = Uri.file(File('$_kit/settings.html').absolute.path)
      .replace(query: 'lang=$lang&theme=$theme&dialog=delete');
  final result = await Process.run(chrome, [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    // Web fonts load from file://, hinting off and sRGB, as the designer
    // renderer (_source/render/render.js) runs.
    '--allow-file-access-from-files',
    '--force-color-profile=srgb',
    '--font-render-hinting=none',
    '--force-device-scale-factor=1',
    '--window-size=$_width,$_height',
    // The page waits for its fonts before the screenshot.
    '--virtual-time-budget=5000',
    '--screenshot=${png.absolute.path}',
    url.toString(),
  ]);
  if (!png.existsSync()) {
    stderr.writeln('Chrome wrote no ${png.path}:\n${result.stderr}');
    exit(1);
  }
  final (pw, ph) = _pngSize(png.readAsBytesSync());
  if (pw != _width || ph != _height) {
    stderr.writeln('${png.path} is $pw x $ph, expected $_width x $_height');
    exit(1);
  }
  stdout.writeln('Wrote ${png.path} ($pw x $ph).');
}

Future<void> _writeManifest(String chrome) async {
  final version = await Process.run(chrome, ['--version']);
  final manifest = {
    'note':
        'Generated visual references, not designer-provided assets; kit.css '
        'and MASTER.md remain authoritative.',
    'chrome':
        RegExp(r'[\d.]+').firstMatch('${version.stdout}')?.group(0) ??
        'unknown',
    'device': {'viewportWidth': _width, 'viewportHeight': _height, 'dpr': 1},
    'sha256': {
      for (final input in _inputs)
        input: sha256
            .convert(
              utf8.encode(
                File(input).readAsStringSync().replaceAll('\r\n', '\n'),
              ),
            )
            .toString(),
    },
  };
  File('$_outDir/manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('Wrote $_outDir/manifest.json.');
}

/// Width and height from a PNG's IHDR chunk.
(int, int) _pngSize(List<int> bytes) {
  int u32(int o) =>
      bytes[o] << 24 | bytes[o + 1] << 16 | bytes[o + 2] << 8 | bytes[o + 3];
  return (u32(16), u32(20));
}
