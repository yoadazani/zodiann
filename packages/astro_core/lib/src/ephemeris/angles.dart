/// Normalizes an angle in degrees into `[0, 360)`, the range every longitude
/// in the app uses (spec "Planet position"; T-CRS-3: never 360).
///
/// Use this instead of a bare `degrees % 360`: in Dart, `x % 360` returns
/// exactly `360.0` for tiny negative `x` (e.g. `-1e-15`), which
/// `EclipticPosition` rejects. Such a result, and `-0.0`, are returned as
/// `0.0`.
///
/// Throws [ArgumentError] if [degrees] is NaN or infinite.
double normalizeDegrees(double degrees) {
  if (!degrees.isFinite) {
    throw ArgumentError.value(degrees, 'degrees', 'must be finite');
  }
  final result = degrees % 360;
  return (result == 360 || result == 0) ? 0.0 : result;
}
