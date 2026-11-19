// ZOD-WHL-002: renders the sign ring's visual references with headless Chrome,
// straight from the design kit (`kit.css`, `kit.js` `wheelSVG`). Run manually
// from the workspace root when the kit changes (not part of lint / test):
//
//   fvm dart run tool/wheel/render_sign_ring_references.dart
//
// The Chrome invocation, size check and manifest are shared with the other
// wheel reference tools (`kit_reference.dart`, which explains the wrapper
// page). Everything but the sign ring is hidden.
//
// These are GENERATED visual references, not designer assets: kit.css and
// MASTER.md stay authoritative.
//
// Writes packages/feature_wheel/test/fixtures/sign_ring/ring_<theme>_<table>.png
// (644 × 656 @1) and manifest.json.
import 'dart:io';

import 'kit_reference.dart';

const _outDir = 'packages/feature_wheel/test/fixtures/sign_ring';

// Only the sign ring stays: sectors, glyphs, separators, rims and halo. The
// classless circles are the true-position dots.
const _hide = '''
.wheel .tick, .wheel .deg-lbl, .wheel .inner, .wheel .asp, .wheel .connector,
.wheel .body-bg, .wheel .body-glyph, .wheel .body-deg, .wheel .pointer,
.wheel .pointer-line, .wheel .hub, .wheel circle:not([class]) { display: none; }''';

Future<void> main() async {
  final chrome = chromePath();
  Directory(_outDir).createSync(recursive: true);
  final temp = Directory.systemTemp.createTempSync('zod_ring_refs_');
  try {
    for (final theme in referenceThemes) {
      for (final table in referenceTables) {
        await renderReference(
          chrome: chrome,
          temp: temp,
          outDir: _outDir,
          filePrefix: 'ring',
          theme: theme,
          table: table,
          hideCss: _hide,
        );
      }
    }
  } finally {
    temp.deleteSync(recursive: true);
  }
  await writeReferenceManifest(chrome, _outDir);
}
