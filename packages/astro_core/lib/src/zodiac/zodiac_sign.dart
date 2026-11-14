/// The twelve tropical zodiac signs, in zodiacal order from Aries.
///
/// The value's `name` is the stable, language-independent key (L-9): store
/// and compare signs by it, never by an index or a translated name. Display
/// names come from `ZodiannLocalizations` in `shared_ui` (ZOD-L10-007).
/// [index] is the sign index 0–11; the sign starts at `index * 30°`.
enum ZodiacSign {
  aries,
  taurus,
  gemini,
  cancer,
  leo,
  virgo,
  libra,
  scorpio,
  sagittarius,
  capricorn,
  aquarius,
  pisces;

  /// Parses the JSON form produced by [toJson] (the value's `name`).
  ///
  /// Throws [FormatException] for a non-string or an unknown name.
  static ZodiacSign fromJson(Object? json) {
    if (json is String) {
      for (final sign in values) {
        if (sign.name == json) return sign;
      }
    }
    throw FormatException('Unknown ZodiacSign', json);
  }

  /// The stable, language-independent key used in JSON (L-9).
  String toJson() => name;
}
