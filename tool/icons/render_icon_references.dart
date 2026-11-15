// ZOD-FND-009: renders the icon fidelity references with headless Chrome,
// straight from the source SVGs. Run manually from the workspace root when an
// SVG changes (not part of lint / test; there is no CI yet):
//
//   fvm dart run tool/icons/render_icon_references.dart
//
// Chrome is C:/Program Files/Google/Chrome/Application/chrome.exe unless the
// CHROME environment variable names another executable.
//
// Writes packages/shared_ui/test/fixtures/icons/sheet_<S>.png for each size
// and manifest.json (Chrome version, sizes, each SVG's SHA-256). Each sheet
// holds all icons in one row, file-name (code-unit) order, cell i at
// x ∈ [i·S, (i+1)·S), black on transparent; the page is 33·S × max(S, 64).
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _iconsDir = 'design-reference/zodiann/assets/icons';
const _outDir = 'packages/shared_ui/test/fixtures/icons';
const _sizes = [16, 20, 48, 60, 96];
const _defaultChrome = 'C:/Program Files/Google/Chrome/Application/chrome.exe';

Future<void> main() async {
  final chrome = Platform.environment['CHROME'] ?? _defaultChrome;
  final files =
      Directory(_iconsDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.svg'))
          .toList()
        ..sort((a, b) => _name(a).compareTo(_name(b)));
  final sources = {
    for (final f in files)
      _name(f): f.readAsStringSync().replaceAll('\r\n', '\n'),
  };

  final temp = Directory.systemTemp.createTempSync('zod_icon_refs_');
  try {
    Directory(_outDir).createSync(recursive: true);
    for (final s in _sizes) {
      final width = sources.length * s;
      final height = s < 64 ? 64 : s;
      final html = File('${temp.path}/sheet_$s.html')
        ..writeAsStringSync(_page(sources.values.toList(), s));
      final png = File('$_outDir/sheet_$s.png');
      if (png.existsSync()) png.deleteSync();
      final result = await Process.run(chrome, [
        '--headless=new',
        '--disable-gpu',
        '--hide-scrollbars',
        '--force-device-scale-factor=1',
        '--force-color-profile=srgb',
        '--default-background-color=00000000',
        '--window-size=$width,$height',
        '--screenshot=${png.absolute.path}',
        html.absolute.uri.toString(),
      ]);
      if (!png.existsSync()) {
        stderr.writeln('Chrome wrote no ${png.path}:\n${result.stderr}');
        exit(1);
      }
      final (w, h) = _pngSize(png.readAsBytesSync());
      if (w != width || h != height) {
        stderr.writeln('${png.path} is $w × $h, expected $width × $height');
        exit(1);
      }
      stdout.writeln('Wrote ${png.path} ($w × $h).');
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
        key: sha256.convert(utf8.encode(value)).toString(),
    },
  };
  File('$_outDir/manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('Wrote $_outDir/manifest.json.');
}

String _name(File f) => f.uri.pathSegments.last.replaceAll('.svg', '');

/// The HTML page for one sheet: each icon an absolutely positioned inline
/// SVG with the file's own root attributes (minus xmlns / width / height).
String _page(List<String> svgs, int s) {
  final cells = StringBuffer();
  for (var i = 0; i < svgs.length; i++) {
    final svg = svgs[i];
    final open = svg.substring(0, svg.indexOf('>'));
    final inner = svg.substring(
      svg.indexOf('>') + 1,
      svg.lastIndexOf('</svg>'),
    );
    final attributes = RegExp(r'([\w:-]+)="([^"]*)"')
        .allMatches(open)
        .where((m) => !{'xmlns', 'width', 'height'}.contains(m[1]))
        .map((m) => '${m[1]}="${m[2]}"')
        .join(' ');
    cells.write(
      '<svg $attributes width="$s" height="$s" '
      'style="position:absolute;left:${i * s}px;top:0;display:block">'
      '$inner</svg>',
    );
  }
  return '<!doctype html><html><head><meta charset="utf-8"><style>'
      'html,body{margin:0;padding:0;background:transparent;color:#000}'
      '</style></head><body>$cells</body></html>';
}

/// Width and height from a PNG's IHDR chunk.
(int, int) _pngSize(List<int> bytes) {
  int u32(int o) =>
      bytes[o] << 24 | bytes[o + 1] << 16 | bytes[o + 2] << 8 | bytes[o + 3];
  return (u32(16), u32(20));
}
