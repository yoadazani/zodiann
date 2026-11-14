/// The eight compass directions of a square cell seen from the centre
/// (L-9's "north-west"; SQ-17, EX-2), in the order of the spiral angle.
///
/// The value's `name` is the stable, language-independent key (L-9): store
/// and compare directions by it, never by an index or a translated name.
enum CompassDirection {
  west,
  northWest,
  north,
  northEast,
  east,
  southEast,
  south,
  southWest;

  /// The spiral angle of this direction: 0° on the west axis (cell 2),
  /// increasing clockwise (`SpiralCell.angle`).
  double get angleDegrees => index * 45.0;

  /// The direction whose [angleDegrees] equals [degrees] exactly, else null.
  ///
  /// Takes a spiral angle in [0, 360) (`SpiralCell.angle`, exact on the axes
  /// and diagonals); 360 returns null, so normalise a non-normalised angle
  /// first. Assumes the fixed SQ-8 orientation (start left, clockwise);
  /// ZOD-EXT-010 must remap it for other starts or rotations.
  static CompassDirection? atAngle(double degrees) {
    for (final d in values) {
      if (d.angleDegrees == degrees) return d;
    }
    return null;
  }

  /// Parses the JSON form produced by [toJson] (the value's `name`).
  ///
  /// Throws [FormatException] for a non-string or an unknown name.
  static CompassDirection fromJson(Object? json) {
    if (json is String) {
      for (final d in values) {
        if (d.name == json) return d;
      }
    }
    throw FormatException('Unknown CompassDirection', json);
  }

  /// The stable, language-independent key used in JSON (L-9).
  String toJson() => name;
}
