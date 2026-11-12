/// A body's tropical ecliptic longitude and its rate of change at one moment.
///
/// Spec "Planet position": the output is a longitude in degrees in the range
/// 0 to 360, **not including 360**. The speed comes directly from the
/// ephemeris source (CRS-A1); a negative speed means retrograde.
final class EclipticPosition {
  /// Creates a validated position.
  ///
  /// Throws [ArgumentError] if [longitude] is not finite or is outside
  /// `[0, 360)`, or if [speed] is not finite. A longitude of `-0.0` is
  /// stored as `0.0`.
  EclipticPosition({required double longitude, required this.speed})
    : longitude = longitude == 0 ? 0.0 : longitude {
    if (!longitude.isFinite || longitude < 0 || longitude >= 360) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'must be a finite number of degrees in [0, 360)',
      );
    }
    if (!speed.isFinite) {
      throw ArgumentError.value(speed, 'speed', 'must be finite');
    }
  }

  /// Tropical ecliptic longitude in degrees, in `[0, 360)`.
  final double longitude;

  /// Rate of change of [longitude] in degrees per day. Negative means the
  /// body is retrograde.
  final double speed;

  @override
  bool operator ==(Object other) =>
      other is EclipticPosition &&
      other.longitude == longitude &&
      other.speed == speed;

  @override
  int get hashCode => Object.hash(longitude, speed);

  @override
  String toString() =>
      'EclipticPosition(longitude: $longitude°, speed: $speed°/day)';
}
