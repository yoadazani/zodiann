/// The five aspects, in the spec's table order (conjunction first; the first
/// match in this order decides, ZOD-ASP-001).
///
/// The value's `name` is the stable, language-independent key (L-9): store
/// and compare aspects by it, never by an index or a translated name.
/// ZOD-ASP-001 adds the angles and orbs; keep the order and the keys.
enum AspectKind {
  conjunction,
  sextile,
  square,
  trine,
  opposition;

  /// Parses the JSON form produced by [toJson] (the value's `name`).
  ///
  /// Throws [FormatException] for a non-string or an unknown name.
  static AspectKind fromJson(Object? json) {
    if (json is String) {
      for (final aspect in values) {
        if (aspect.name == json) return aspect;
      }
    }
    throw FormatException('Unknown AspectKind', json);
  }

  /// The stable, language-independent key used in JSON (L-9).
  String toJson() => name;
}
