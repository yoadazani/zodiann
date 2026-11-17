// ZOD-NAV-002: renders the navigation drawer's visual references with
// headless Chrome, straight from the design kit (`_source/wheel.html?drawer=1`,
// kit.css and kit.js). Run manually from the workspace root when the kit
// changes (not part of lint / test; there is no CI yet):
//
//   fvm dart run tool/drawer/render_drawer_references.dart
//
// Chrome is C:/Program Files/Google/Chrome/Application/chrome.exe unless the
// CHROME environment variable names another executable.
//
// These are GENERATED visual references, not designer-provided assets:
// kit.css and MASTER.md remain authoritative, and the images never override
// them. The designer's own dark PNGs (screens/00-navigation-drawer_* and
// responsive/mobile/navigation-drawer_*) stay the primary oracle for the dark
// theme; this tool exists chiefly to produce the light theme the designer
// did not render (the task's "both themes" criterion), and its dark output
// proves it reproduces the designer's images.
//
// Writes packages/shared_ui/test/fixtures/drawer/generated_<theme>_<lang>_
// <device>.png (desktop 1440 × 900 @1, mobile 390 × 844 @2, the designer
// renderer's devices) and manifest.json (Chrome version, SHA-256 of every
// kit file the renders depend on, LF-normalised).
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _kit = 'design-reference/zodiann/_source';
const _assets = 'design-reference/zodiann/assets';
const _outDir = 'packages/shared_ui/test/fixtures/drawer';
const _defaultChrome = 'C:/Program Files/Google/Chrome/Application/chrome.exe';

/// The designer renderer's devices: viewport width, height, device pixel ratio,
/// and the browser window to render in. Chrome will not make a window
/// narrower than about 500 px, so the phone page is loaded in an exactly
/// 390 × 844 iframe inside a 500-wide window (the page's media queries see
/// the iframe's viewport); the PNG is then the whole window (1000 × 1688 at
/// @2) and a test crops the left 780 device px.
const _devices = {
  'desktop': (1440, 900, 1, 1440, false),
  'mobile': (390, 844, 2, 500, true),
};
const _themes = ['dark', 'light'];
const _langs = ['en', 'he'];

/// Every file a render depends on (hashed into the manifest).
const _inputs = [
  '$_kit/wheel.html',
  '$_kit/kit.css',
  '$_kit/kit.js',
  '$_assets/fonts/fonts.css',
  '$_assets/zodiann-logo-on-dark.svg',
  '$_assets/zodiann-logo-on-light.svg',
];

Future<void> main() async {
  final chrome = Platform.environment['CHROME'] ?? _defaultChrome;
  Directory(_outDir).createSync(recursive: true);
  final temp = Directory.systemTemp.createTempSync('zod_drawer_refs_');
  try {
    await _render(chrome, temp);
  } finally {
    temp.deleteSync(recursive: true);
  }
  await _writeManifest(chrome);
}

Future<void> _render(String chrome, Directory temp) async {
  for (final theme in _themes) {
    for (final lang in _langs) {
      for (final MapEntry(key: device, value: (vw, vh, dpr, winW, wrapped))
          in _devices.entries) {
        final png = File('$_outDir/generated_${theme}_${lang}_$device.png');
        if (png.existsSync()) png.deleteSync();
        var url = Uri.file(File('$_kit/wheel.html').absolute.path)
            .replace(query: 'lang=$lang&theme=$theme&drawer=1');
        if (wrapped) {
          // The kit page in an exactly vw × vh iframe, top left of the window.
          final wrapper = File('${temp.path}/${theme}_${lang}_$device.html')
            ..writeAsStringSync(
              '<!doctype html><html><body style="margin:0;background:#000">'
              '<iframe src="$url" width="$vw" height="$vh" '
              'style="border:0;display:block"></iframe></body></html>',
            );
          url = wrapper.absolute.uri;
        }
        final w = winW, h = vh;
        final result = await Process.run(chrome, [
          '--headless=new',
          '--disable-gpu',
          '--hide-scrollbars',
          // Web fonts load from file://, hinting off and sRGB, as the
          // designer renderer (_source/render/render.js) runs.
          '--allow-file-access-from-files',
          '--force-color-profile=srgb',
          '--font-render-hinting=none',
          '--force-device-scale-factor=$dpr',
          '--window-size=$w,$h',
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
        if (pw != w * dpr || ph != h * dpr) {
          stderr.writeln(
            '${png.path} is $pw × $ph, expected ${w * dpr} × ${h * dpr}',
          );
          exit(1);
        }
        stdout.writeln('Wrote ${png.path} ($pw × $ph).');
      }
    }
  }
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
    'devices': {
      for (final MapEntry(key: k, value: (w, h, dpr, win, wrapped))
          in _devices.entries)
        k: {
          'viewportWidth': w,
          'viewportHeight': h,
          'dpr': dpr,
          'windowWidth': win,
          'iframe': wrapped,
          // The PNG is the whole window.
          'pngWidth': win * dpr,
          'pngHeight': h * dpr,
        },
    },
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
