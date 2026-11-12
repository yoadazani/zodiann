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

  /// Whether this body's retrograde state is the fixed "℞ Mean" rather than
  /// derived from the sign of its speed (spec "Planet position": for the
  /// node, retrograde is defined as constant, and the table shows mean ℞).
  ///
  /// True only for [node]. A fixed flag by design (ZOD-EPH-001), never
  /// computed: retrograde detection (ZOD-EPH-005) reads it instead of the
  /// speed sign for such bodies.
  bool get hasConstantMeanRetrograde => this == node;
}
