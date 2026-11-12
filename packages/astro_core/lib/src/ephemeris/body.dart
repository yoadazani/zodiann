/// The bodies shown on the zodiac wheel (spec: "Data model and user
/// settings"). The order is the spec's and is significant.
///
/// [sun] … [pluto] are **physical bodies**: their positions are apparent,
/// geocentric ecliptic longitudes of date (see `EphemerisPort`).
///
/// [node] is **not a physical body**. It is the formula-based mean ascending
/// lunar node, a mathematical point whose longitude comes from a closed-form
/// formula rather than an ephemeris (see `EphemerisPort.meanAscendingNode`).
enum Body {
  sun,
  moon,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  pluto,

  /// The mean ascending lunar node (formula-based, not a physical body).
  node;

  /// Parses the JSON form produced by [toJson] (the value's `name`).
  ///
  /// Throws [FormatException] for a non-string or an unknown name.
  static Body fromJson(Object? json) {
    if (json is String) {
      for (final body in values) {
        if (body.name == json) return body;
      }
    }
    throw FormatException('Unknown Body', json);
  }

  /// The stable, language-independent key used in JSON (L-9).
  String toJson() => name;
}
