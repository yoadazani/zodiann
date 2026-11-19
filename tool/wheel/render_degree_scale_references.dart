// ZOD-WHL-003: renders the degree scale's visual references with headless
// Chrome, straight from the design kit (`kit.css`, `kit.js` `wheelSVG`). Run
// manually from the workspace root when the kit changes (not part of lint /
// test):
//
//   fvm dart run tool/wheel/render_degree_scale_references.dart
//
// The Chrome invocation, size check and manifest are shared with the other
// wheel reference tools (`kit_reference.dart`, which explains the wrapper
// page). Only the ticks and the degree labels are shown.
//
// These are GENERATED visual references, not designer assets: kit.css and
// MASTER.md stay authoritative.
//
// Writes packages/feature_wheel/test/fixtures/degree_scale/scale_<theme>_<table>.png
// (644 × 656 @1) and manifest.json.
import 'dart:io';

import 'kit_reference.dart';

const _outDir = 'packages/feature_wheel/test/fixtures/degree_scale';

// Ticks and `.deg-lbl` are direct children of the `<svg class="wheel">`.
const _hide = 'svg.wheel > *:not(.tick):not(.deg-lbl) { display: none; }';

Future<void> main() async {
  final chrome = chromePath();
  Directory(_outDir).createSync(recursive: true);
  final temp = Directory.systemTemp.createTempSync('zod_scale_refs_');
  try {
    for (final theme in referenceThemes) {
      for (final table in referenceTables) {
        await renderReference(
          chrome: chrome,
          temp: temp,
          outDir: _outDir,
          filePrefix: 'scale',
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
