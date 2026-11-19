import 'package:astro_core/astro_core.dart' show ZodiacSign;

/// The four classical elements; each colours three signs (MASTER §2.3).
enum ZodiacElement {
  /// Fire: Aries, Leo, Sagittarius.
  fire,

  /// Earth: Taurus, Virgo, Capricorn.
  earth,

  /// Air: Gemini, Libra, Aquarius.
  air,

  /// Water: Cancer, Scorpio, Pisces.
  water,
}

/// The element of [sign]. An exhaustive switch: a new sign fails to compile.
ZodiacElement elementOf(ZodiacSign sign) => switch (sign) {
  ZodiacSign.aries ||
  ZodiacSign.leo ||
  ZodiacSign.sagittarius => ZodiacElement.fire,
  ZodiacSign.taurus ||
  ZodiacSign.virgo ||
  ZodiacSign.capricorn => ZodiacElement.earth,
  ZodiacSign.gemini ||
  ZodiacSign.libra ||
  ZodiacSign.aquarius => ZodiacElement.air,
  ZodiacSign.cancer ||
  ZodiacSign.scorpio ||
  ZodiacSign.pisces => ZodiacElement.water,
};
