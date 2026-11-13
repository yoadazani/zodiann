/// The font families bundled with `shared_ui` (ZOD-FND-007, MASTER.md §3).
///
/// They are package assets, so a `TextStyle` names them with
/// `fontFamily: ZodiannFonts.plexSans, package: ZodiannFonts.package`; the
/// engine sees `packages/shared_ui/<family>`. `package` also prefixes every
/// `fontFamilyFallback` entry.
abstract final class ZodiannFonts {
  /// The package that declares the fonts.
  static const String package = 'shared_ui';

  /// The Latin UI family (weights 300, 400, 500, 600).
  static const String plexSans = 'IBM Plex Sans';

  /// The Hebrew UI family, which also covers Latin (weights 300–600).
  static const String plexSansHebrew = 'IBM Plex Sans Hebrew';

  /// First glyph font: signs, most bodies, aspects.
  static const String notoSansSymbols = 'Noto Sans Symbols';

  /// Second glyph font: ☉, □, △.
  static const String notoSansSymbols2 = 'Noto Sans Symbols 2';

  /// Third glyph font: ℞, which neither Symbols font has.
  static const String notoSans = 'Noto Sans';

  /// The astrological glyph fallback order: MASTER §3's Symbols then
  /// Symbols 2, plus Noto Sans for ℞ (FND-007 product-owner decision).
  static const List<String> glyphFallback = [
    notoSansSymbols,
    notoSansSymbols2,
    notoSans,
  ];
}
