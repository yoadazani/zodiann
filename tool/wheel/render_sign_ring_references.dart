// ZOD-WHL-002: renders the sign ring's visual references with headless Chrome,
// straight from the design kit (`kit.css`, `kit.js` `wheelSVG`). Run manually
// from the workspace root when the kit changes (not part of lint / test):
//
//   fvm dart run tool/wheel/render_sign_ring_references.dart
//
// Chrome is C:/Program Files/Google/Chrome/Application/chrome.exe unless the
// CHROME environment variable names another executable.
//
// These are GENERATED visual references, not designer assets: kit.css and
// MASTER.md stay authoritative. `_source/wheel.html` cannot be used directly
// (it picks the compact wheel by `innerWidth <= 1100` and sizes the SVG by CSS
// inside a panel), so a temporary wrapper page links the kit by file URL and
// inserts `wheelSVG({ pointerLon: 227.05, compact })` into a 644 px-wide div:
// R = 300 px, centre (322, 334). Everything but the sign ring is hidden.
//
// `pointerLon: 227.05` is `BODIES[0].lon` (kit.js, the Sun), the kit's own
// default, passed explicitly and written to the manifest.
//
// Writes packages/feature_wheel/test/fixtures/sign_ring/ring_<theme>_<table>.png
// (644 × 656 @1) and manifest.json.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _kit = 'design-reference/zodiann/_source';
const _outDir = 'packages/feature_wheel/test/fixtures/sign_ring';
const _defaultChrome = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const _pointerLon = 227.05;
const _width = 644;
const _height = 656;
const _themes = ['dark', 'light'];
const _tables = ['desktop', 'compact'];

/// Every file a render depends on (hashed into the manifest).
const _inputs = [
  '$_kit/kit.css',
  '$_kit/kit.js',
  'design-reference/zodiann/assets/fonts/fonts.css',
];

Future<void> main() async {
  final chrome = Platform.environment['CHROME'] ?? _defaultChrome;
  Directory(_outDir).createSync(recursive: true);
  final temp = Directory.systemTemp.createTempSync('zod_ring_refs_');
  try {
    for (final theme in _themes) {
      for (final table in _tables) {
        await _render(chrome, temp, theme, table);
      }
    }
  } finally {
    temp.deleteSync(recursive: true);
  }
  await _writeManifest(chrome);
}

String _fileUrl(String path) => Uri.file(File(path).absolute.path).toString();

Future<void> _render(
  String chrome,
  Directory temp,
  String theme,
  String table,
) async {
  final png = File('$_outDir/ring_${theme}_$table.png');
  if (png.existsSync()) png.deleteSync();
  final compact = table == 'compact';
  final page = File('${temp.path}/${theme}_$table.html')
    ..writeAsStringSync('''
<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="${_fileUrl('$_kit/kit.css')}">
<style>
html, body { margin: 0; background: var(--surface); }
#w { width: ${_width}px; }
/* Only the sign ring stays: sectors, glyphs, separators, rims and halo. The
   classless circles are the true-position dots. */
.wheel .tick, .wheel .deg-lbl, .wheel .inner, .wheel .asp, .wheel .connector,
.wheel .body-bg, .wheel .body-glyph, .wheel .body-deg, .wheel .pointer,
.wheel .pointer-line, .wheel .hub, .wheel circle:not([class]) { display: none; }
</style></head><body><div id="w"></div>
<script src="${_fileUrl('$_kit/kit.js')}"></script>
<script>
document.getElementById('w').innerHTML =
  wheelSVG({ pointerLon: $_pointerLon, compact: $compact });
</script></body></html>
''');
  final url = Uri.file(page.absolute.path).replace(query: 'theme=$theme');
  final result = await Process.run(chrome, [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
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
    stderr.writeln('${png.path} is $pw × $ph, expected $_width × $_height');
    exit(1);
  }
  stdout.writeln('Wrote ${png.path} ($pw × $ph).');
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
    'pointerLongitude': _pointerLon,
    'width': _width,
    'height': _height,
    'radius': 300,
    'centre': [322, 334],
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
