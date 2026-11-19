// Shared by the wheel's reference-render tools (ZOD-WHL-002, ZOD-WHL-003):
// the headless Chrome invocation, the PNG size check and the manifest writer.
//
// A temporary wrapper page links the design kit (`kit.css`, `kit.js`) by file
// URL and inserts `wheelSVG({ pointerLon: 227.05, compact })` into a 644
// px-wide div: R = 300 px, centre (322, 334). Each tool passes the CSS that
// hides everything but its own layer. `_source/wheel.html` cannot be used
// directly (it picks the compact wheel by `innerWidth <= 1100` and sizes the
// SVG by CSS inside a panel).
//
// `pointerLon: 227.05` is `BODIES[0].lon` (kit.js, the Sun), the kit's own
// default, passed explicitly and written to the manifest.
//
// Chrome is C:/Program Files/Google/Chrome/Application/chrome.exe unless the
// CHROME environment variable names another executable.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _kit = 'design-reference/zodiann/_source';
const _defaultChrome = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const _pointerLon = 227.05;
const _width = 644;
const _height = 656;

/// The two themes a reference is rendered in.
const referenceThemes = ['dark', 'light'];

/// The two proportion tables a reference is rendered with.
const referenceTables = ['desktop', 'compact'];

/// Every file a render depends on (hashed into the manifest).
const _inputs = [
  '$_kit/kit.css',
  '$_kit/kit.js',
  'design-reference/zodiann/assets/fonts/fonts.css',
];

/// The Chrome executable to use.
String chromePath() => Platform.environment['CHROME'] ?? _defaultChrome;

String _fileUrl(String path) => Uri.file(File(path).absolute.path).toString();

/// Renders one reference to `<outDir>/<filePrefix>_<theme>_<table>.png`.
/// [hideCss] is the page's CSS that hides everything but the tool's layer.
Future<void> renderReference({
  required String chrome,
  required Directory temp,
  required String outDir,
  required String filePrefix,
  required String theme,
  required String table,
  required String hideCss,
}) async {
  final png = File('$outDir/${filePrefix}_${theme}_$table.png');
  if (png.existsSync()) png.deleteSync();
  final compact = table == 'compact';
  final page = File('${temp.path}/${theme}_$table.html')
    ..writeAsStringSync('''
<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="${_fileUrl('$_kit/kit.css')}">
<style>
html, body { margin: 0; background: var(--surface); }
#w { width: ${_width}px; }
$hideCss
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

/// Writes `<outDir>/manifest.json` (Chrome version, pointer, geometry and the
/// SHA-256 of every input).
Future<void> writeReferenceManifest(String chrome, String outDir) async {
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
  File('$outDir/manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('Wrote $outDir/manifest.json.');
}

/// Width and height from a PNG's IHDR chunk.
(int, int) _pngSize(List<int> bytes) {
  int u32(int o) =>
      bytes[o] << 24 | bytes[o + 1] << 16 | bytes[o + 2] << 8 | bytes[o + 3];
  return (u32(16), u32(20));
}
