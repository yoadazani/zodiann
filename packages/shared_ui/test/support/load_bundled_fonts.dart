// Test support: flutter_test does not load the font manifest, so tests that
// measure real glyphs load the bundled files with FontLoader under the names
// the engine uses for package fonts (`packages/shared_ui/<family>`).
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_ui/shared_ui.dart';

/// Every registered font file, by family, relative to `assets/fonts/`.
const bundledFontFiles = {
  ZodiannFonts.plexSans: [
    'ibm-plex-sans/IBMPlexSans-Light.ttf',
    'ibm-plex-sans/IBMPlexSans-Regular.ttf',
    'ibm-plex-sans/IBMPlexSans-Medium.ttf',
    'ibm-plex-sans/IBMPlexSans-SemiBold.ttf',
  ],
  ZodiannFonts.plexSansHebrew: [
    'ibm-plex-sans-hebrew/IBMPlexSansHebrew-Light.ttf',
    'ibm-plex-sans-hebrew/IBMPlexSansHebrew-Regular.ttf',
    'ibm-plex-sans-hebrew/IBMPlexSansHebrew-Medium.ttf',
    'ibm-plex-sans-hebrew/IBMPlexSansHebrew-SemiBold.ttf',
  ],
  ZodiannFonts.notoSansSymbols: [
    'noto-sans-symbols/NotoSansSymbols-Regular.ttf',
  ],
  ZodiannFonts.notoSansSymbols2: [
    'noto-sans-symbols-2/NotoSansSymbols2-Regular.ttf',
  ],
  ZodiannFonts.notoSans: ['noto-sans/NotoSans-Regular.ttf'],
};

/// Loads every bundled font, one `FontLoader` per family. Run from the
/// package root (as `flutter test` does).
Future<void> loadBundledFonts({
  Map<String, List<String>> files = bundledFontFiles,
}) async {
  for (final MapEntry(key: family, value: paths) in files.entries) {
    final loader = FontLoader('packages/${ZodiannFonts.package}/$family');
    for (final path in paths) {
      final bytes = File('assets/fonts/$path').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}
