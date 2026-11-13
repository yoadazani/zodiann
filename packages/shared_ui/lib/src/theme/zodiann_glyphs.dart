import 'package:astro_core/astro_core.dart' show Body;

/// MASTER.md §3's astrological glyphs (ZOD-UI-002). Each string is one code
/// point followed by U+FE0E (text presentation), so no platform renders it
/// as a colour emoji. Draw them with `ZodiannTextStyles.glyph`.
///
/// The constants are fully escaped so the source shows exactly which code
/// point each one is.
abstract final class ZodiannGlyphs {
  /// U+FE0E VARIATION SELECTOR-15: text presentation.
  static const String textPresentation = '\u{FE0E}';

  /// The signs in zodiac order: index 0 is Aries, 11 is Pisces.
  static const List<String> signs = [
    '\u{2648}\u{FE0E}', // ♈ Aries
    '\u{2649}\u{FE0E}', // ♉ Taurus
    '\u{264A}\u{FE0E}', // ♊ Gemini
    '\u{264B}\u{FE0E}', // ♋ Cancer
    '\u{264C}\u{FE0E}', // ♌ Leo
    '\u{264D}\u{FE0E}', // ♍ Virgo
    '\u{264E}\u{FE0E}', // ♎ Libra
    '\u{264F}\u{FE0E}', // ♏ Scorpio
    '\u{2650}\u{FE0E}', // ♐ Sagittarius
    '\u{2651}\u{FE0E}', // ♑ Capricorn
    '\u{2652}\u{FE0E}', // ♒ Aquarius
    '\u{2653}\u{FE0E}', // ♓ Pisces
  ];

  /// The glyph of [b].
  static String body(Body b) => switch (b) {
    Body.sun => '\u{2609}\u{FE0E}', // ☉
    Body.moon => '\u{263D}\u{FE0E}', // ☽
    Body.mercury => '\u{263F}\u{FE0E}', // ☿
    Body.venus => '\u{2640}\u{FE0E}', // ♀
    Body.mars => '\u{2642}\u{FE0E}', // ♂
    Body.jupiter => '\u{2643}\u{FE0E}', // ♃
    Body.saturn => '\u{2644}\u{FE0E}', // ♄
    Body.uranus => '\u{2645}\u{FE0E}', // ♅
    Body.neptune => '\u{2646}\u{FE0E}', // ♆
    Body.pluto => '\u{2647}\u{FE0E}', // ♇
    Body.node => '\u{260A}\u{FE0E}', // ☊
  };

  /// Conjunction ☌.
  static const String conjunction = '\u{260C}\u{FE0E}';

  /// Sextile ⚹.
  static const String sextile = '\u{26B9}\u{FE0E}';

  /// Square □.
  static const String square = '\u{25A1}\u{FE0E}';

  /// Trine △.
  static const String trine = '\u{25B3}\u{FE0E}';

  /// Opposition ☍.
  static const String opposition = '\u{260D}\u{FE0E}';

  /// Retrograde ℞.
  static const String retrograde = '\u{211E}\u{FE0E}';

  /// All 29 glyphs: signs, bodies, retrograde, aspects.
  static List<String> get all => [
    ...signs,
    for (final b in Body.values) body(b),
    retrograde,
    conjunction,
    sextile,
    square,
    trine,
    opposition,
  ];
}
