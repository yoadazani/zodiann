import 'dart:math' as math;

/// The rate of change of the ecliptic longitude, in degrees per day, of a
/// body whose geocentric position in the ecliptic frame is `(x, y)` and whose
/// geocentric velocity in that frame is `(vx, vy)` (any consistent length
/// unit; `vx` and `vy` are that unit per day).
///
/// This is `(x·vy − y·vx) / (x² + y²)`, the exact rate of `atan2(y, x)` for
/// the given vectors, converted from radians to degrees. The `z` component
/// and the latitude do not enter: they cancel out of the longitude rate.
///
/// ## What this is, and what it is not (ZOD-EPH-004, decision D1)
///
/// astronomy-engine has no longitude-speed output. The adapter derives the
/// speed **analytically from the library's own position and velocity
/// vectors** (CRS-A1 forbids finite differences, and none is used). The
/// vectors it passes in leave out, and so this result leaves out:
///
/// * the time derivative of the light-time correction,
/// * the time derivative of the aberration correction, and
/// * the rotation rate of the ecliptic-of-date frame (precession about
///   3.8e-5 degrees per day; nutation smaller),
///
/// and the velocity is the instantaneous one at the observation instant, not
/// at the light-time-retarded instant. **It is therefore not the derivative of
/// the fully apparent longitude.** How good it is, is measured against Swiss
/// Ephemeris (decision D7), not asserted here.
///
/// Throws [ArgumentError] if any input is not finite, or if `x` and `y` are
/// both zero (the longitude of the origin is undefined).
double eclipticLongitudeRateDegreesPerDay({
  required double x,
  required double y,
  required double vx,
  required double vy,
}) {
  _requireFinite(x, 'x');
  _requireFinite(y, 'y');
  _requireFinite(vx, 'vx');
  _requireFinite(vy, 'vy');
  final radiusSquared = x * x + y * y;
  if (radiusSquared == 0) {
    throw ArgumentError('x and y must not both be zero');
  }
  return (x * vy - y * vx) / radiusSquared * (180 / math.pi);
}

void _requireFinite(double value, String name) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, name, 'must be finite');
  }
}
