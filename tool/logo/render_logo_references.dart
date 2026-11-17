// ZOD-FND-008: renders the logo fidelity references with headless Chrome,
// straight from the source SVGs. Run manually from the workspace root when a
// logo SVG changes (not part of lint / test; there is no CI yet):
//
//   fvm dart run tool/logo/render_logo_references.dart
//
// Chrome is C:/Program Files/Google/Chrome/Application/chrome.exe unless the
// CHROME environment variable names another executable.
//
// Writes packages/shared_ui/test/fixtures/logo/<variant>_<px>.png for each
// variant (dark, light) and pixel size, and manifest.json (Chrome version,
// sizes, each SVG's SHA-256 over LF-normalised text). Each image is the whole
// mark, N × N px, on a transparent background.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _assetsDir = 'design-reference/zodiann/assets';
const _outDir = 'packages/shared_ui/test/fixtures/logo';

/// 40 and 132 logical px (drawer, About) at device pixel ratios 1, 2 and 3.
const _sizes = [40, 80, 120, 132, 264, 396];
const _variants = ['dark', 'light'];
const _defaultChrome = 'C:/Program Files/Google/Chrome/Application/chrome.exe';

Future<void> main() async {
  final chrome = Platform.environment['CHROME'] ?? _defaultChrome;
  final sources = {
    for (final v in _variants)
      v: File('$_assetsDir/zodiann-logo-on-$v.svg')
          .readAsStringSync()
          .replaceAll('\r\n', '\n'),
  };

  final temp = Directory.systemTemp.createTempSync('zod_logo_refs_');
  try {
    Directory(_outDir).createSync(recursive: true);
    for (final MapEntry(key: variant, value: svg) in sources.entries) {
      for (final px in _sizes) {
        final html = File('${temp.path}/${variant}_$px.html')
          ..writeAsStringSync(_page(svg, px));
        final png = File('$_outDir/${variant}_$px.png');
        if (png.existsSync()) png.deleteSync();
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
          stderr.writeln('Chrome wrote no ${png.path}:\n${result.stderr}');
          exit(1);
        }
        final (w, h) = _pngSize(png.readAsBytesSync());
        if (w != px || h != px) {
          stderr.writeln('${png.path} is $w × $h, expected $px × $px');
          exit(1);
        }
        stdout.writeln('Wrote ${png.path} ($w × $h).');
      }
    }
  } finally {
    temp.deleteSync(recursive: true);
  }

  final version = await Process.run(chrome, ['--version']);
  final manifest = {
    'chrome':
        RegExp(r'[\d.]+').firstMatch('${version.stdout}')?.group(0) ??
        'unknown',
    'sizes': _sizes,
    'svgSha256': {
      for (final MapEntry(:key, :value) in sources.entries)
        'zodiann-logo-on-$key.svg': sha256
            .convert(utf8.encode(value))
            .toString(),
    },
  };
  File('$_outDir/manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('Wrote $_outDir/manifest.json.');
}

/// The HTML page for one render: the SVG inline, its root width and height
/// replaced by [px].
String _page(String svg, int px) {
  const root = 'width="1024" height="1024"';
  final open = svg.substring(0, svg.indexOf('>'));
  if (root.allMatches(open).length != 1) {
    stderr.writeln('The SVG root must carry exactly one $root.');
    exit(2);
  }
  final sized = svg.replaceFirst(root, 'width="$px" height="$px"');
  return '<!doctype html><html><head><meta charset="utf-8"><style>'
      'html,body{margin:0;padding:0;background:transparent}'
      'svg{display:block}'
      '</style></head><body>$sized</body></html>';
}

/// Width and height from a PNG's IHDR chunk.
(int, int) _pngSize(List<int> bytes) {
  int u32(int o) =>
      bytes[o] << 24 | bytes[o + 1] << 16 | bytes[o + 2] << 8 | bytes[o + 3];
  return (u32(16), u32(20));
}
