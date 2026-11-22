import 'package:astro_core/astro_core.dart';

/// The number of doubles the native shim writes for one body: `out[0]` through
/// `out[7]` (decision D2). The caller owns a buffer of exactly this many
/// doubles.
const int bodyStateLength = 8;

/// The number of doubles the test-only Moon series function writes (decision
/// D2, Task 3 Step 1b): the project-authored value path (longitude, latitude,
/// distance), its three analytic rates per TT century, and upstream's own
/// `CalcMoon` longitude, latitude and distance. The caller owns a buffer of
/// exactly this many doubles.
const int moonSeriesLength = 9;

/// The number of doubles the test-only Moon state function writes: the ECM
/// position (3), the ECM velocity (3), the ECT position (3) and the ECT
/// velocity (3), velocities in AU per day. The caller owns a buffer of exactly
/// this many doubles.
const int moonStateLength = 12;

/// The number of doubles the test-only time function writes (D12): the UT days
/// since J2000, then the TT days since J2000, as the shim's single conversion
/// helper computes them. The caller owns a buffer of exactly this many doubles.
const int timeStateLength = 2;

/// The native shim's body ids (D2). An explicit table, not `Body.index`, so a
/// reordering of the [Body] enum cannot silently change what is sent across
/// the FFI boundary. [Body.node] is absent: the node is formula-based and is
/// never a native body.
const Map<Body, int> shimBodyIds = {
  Body.sun: 0,
  Body.moon: 1,
  Body.mercury: 2,
  Body.venus: 3,
  Body.mars: 4,
  Body.jupiter: 5,
  Body.saturn: 6,
  Body.uranus: 7,
  Body.neptune: 8,
  Body.pluto: 9,
};

/// The J2000 epoch, 2000-01-01T12:00:00Z, in microseconds since the Unix epoch.
const int _j2000Microseconds = 946728000000000;

/// Days since J2000 (2000-01-01T12:00Z) of the UTC instant [utc], the `ut`
/// argument of the library's `Astronomy_TimeFromDays`. The integer
/// microseconds are subtracted before the division, so no precision is lost
/// to a large floating-point day number.
///
/// Throws [ArgumentError] if [utc] is not UTC.
double daysSinceJ2000(DateTime utc) {
  if (!utc.isUtc) {
    throw ArgumentError.value(utc, 'utc', 'must be a UTC DateTime');
  }
  return (utc.microsecondsSinceEpoch - _j2000Microseconds) / 86400000000;
}

/// One body's geocentric state as the native shim reports it (decision D2):
/// the apparent longitude, the apparent position and the velocity in the true
/// ecliptic of date, and, where the library offers one, a longitude from an
/// independent path.
final class BodyState {
  const BodyState({
    required this.longitude,
    required this.x,
    required this.y,
    required this.z,
    required this.vx,
    required this.vy,
    required this.vz,
    this.independentLongitude,
  });

  /// Reads the shim's buffer: `[longitude, x, y, z, vx, vy, vz, independent]`.
  ///
  /// Throws [ArgumentError] unless [out] has exactly [bodyStateLength]
  /// elements. A `NaN` in the last element becomes a null
  /// [independentLongitude].
  factory BodyState.fromBuffer(List<double> out) {
    if (out.length != bodyStateLength) {
      throw ArgumentError.value(
        out.length,
        'out.length',
        'must be $bodyStateLength',
      );
    }
    return BodyState(
      longitude: out[0],
      x: out[1],
      y: out[2],
      z: out[3],
      vx: out[4],
      vy: out[5],
      vz: out[6],
      independentLongitude: out[7].isNaN ? null : out[7],
    );
  }

  /// Apparent ecliptic longitude in degrees, true equinox of date.
  final double longitude;

  /// Geocentric position in the true ecliptic of date, in AU.
  final double x, y, z;

  /// Geocentric velocity in the true ecliptic of date, in AU per day.
  final double vx, vy, vz;

  /// A longitude in degrees from an independent library path; non-null only
  /// for the Sun (`Astronomy_SunPosition`).
  final double? independentLongitude;
}

/// Where the adapter gets a body's state. The native implementation is device
/// only; host tests inject a fake.
abstract interface class BodyStateSource {
  /// The state of [body] at the UTC instant [utc]. Throws [ArgumentError] if
  /// [utc] is not UTC or if [body] is [Body.node].
  BodyState bodyState(Body body, DateTime utc);
}
