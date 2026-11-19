import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_ui/shared_ui.dart';

import 'repo_root.dart';

/// The glyph fonts the sign ring draws with, by family, relative to
/// `packages/shared_ui/assets/fonts/`.
const _glyphFontFiles = {
  ZodiannFonts.notoSansSymbols: [
    'noto-sans-symbols/NotoSansSymbols-Regular.ttf',
  ],
  ZodiannFonts.notoSansSymbols2: [
    'noto-sans-symbols-2/NotoSansSymbols2-Regular.ttf',
  ],
  ZodiannFonts.notoSans: ['noto-sans/NotoSans-Regular.ttf'],
};

/// Loads the glyph fonts under the names the engine uses for package fonts
/// (`packages/shared_ui/<family>`); `flutter_test` loads no font manifest.
/// Paths resolve from [repoRoot], so this works from the repo root and from
/// the package directory.
Future<void> loadWheelGlyphFonts() async {
  final base = '${repoRoot().path}/packages/shared_ui/assets/fonts';
  for (final MapEntry(key: family, value: paths) in _glyphFontFiles.entries) {
    final loader = FontLoader('packages/${ZodiannFonts.package}/$family');
    for (final path in paths) {
      final bytes = File('$base/$path').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}
