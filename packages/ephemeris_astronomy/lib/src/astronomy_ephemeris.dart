import 'package:astro_core/astro_core.dart';

import 'body_state.dart';
import 'longitude_rate.dart';

/// The `EphemerisPort` over astronomy-engine (ZOD-EPH-004): the backup
/// position source and an independent oracle for the Swiss Ephemeris adapter.
/// Swapping it in is one dependency-injection override (ARCH-4).
///
/// ## The speed, and how this adapter reads CRS-A1
///
/// CRS-A1 says the longitude speed "comes directly from the ephemeris".
/// astronomy-engine has **no longitude-speed output**. This adapter therefore
/// **derives the speed analytically from the position and velocity vectors the
/// library provides** (see [eclipticLongitudeRateDegreesPerDay]). **No finite
/// difference is used anywhere**, including inside the library's code that
/// this adapter relies on: for the Moon, whose upstream velocity function
/// differences positions, the velocity is instead the exact analytic
/// derivative of upstream's own Moon series, computed by project-authored code
/// (`native/astronomy_c/zodiann_moon_rate.c`,
/// `docs/spikes/ZOD-EPH-004-moon-derivative.md`).
///
/// **This is not claimed to equal the derivative of the fully apparent
/// longitude.** For the Sun and the planets the velocity is the body's at the
/// light-time-retarded instant (scaled by one minus the rate of the light
/// time) minus the Earth's at the observation instant, so the light-time
/// derivative is included
/// (`docs/spikes/ZOD-EPH-004-retarded-velocity.md`). What it leaves out is the
/// time derivative of the aberration correction (about 1e-4 degrees per day)
/// and the rotation rate of the ecliptic-of-date frame (precession about
/// 3.8e-5 degrees per day). For the Moon, the omitted terms are the rate of
/// the nutation and obliquity rotation (about 5e-5 degrees per day at most)
/// and of the time scale, and its precession rate is included. How close the
/// result is to Swiss Ephemeris, including at planetary stations, is measured
/// and recorded in `docs/spikes/ZOD-EPH-004-astronomy-engine-adapter.md`, not
/// asserted here.
///
/// ## Positions: what is not modelled
///
/// The library applies light time and aberration to the Sun and the planets
/// and **no gravitational deflection of light for any body**; the Moon's
/// position carries neither light time nor aberration (about 1 arcsecond). The
/// port's contract describes apparent positions corrected for light
/// deflection too; the effect is inside the measured accuracy (at most 17.6
/// arcseconds against JPL Horizons at equivalent TT instants, 60 required), but
/// a caller must not assume deflection parity with Swiss Ephemeris near solar
/// conjunction.
///
/// ## Time
///
/// The library converts the UTC instant to TT with its own delta T model,
/// which differs from other sources' for future dates: at UTC instants the
/// Moon can differ from Horizons by up to 78.6 arcseconds at 2100
/// (`docs/spikes/ZOD-EPH-004-delta-t.md`).
///
/// ## Threading
///
/// The vendored library keeps unsynchronised global state (the Pluto segment
/// cache publishes a segment before it is filled), so calls from several
/// isolates or threads at once can return a wrong Pluto position without any
/// error. Serialize calls (the same rule as for the Swiss binding).
///
/// ## Range
///
/// [coveredRange] is 1899-12-31T12:00Z to 2100-01-01T12:00Z (T = -1 to +1
/// Julian centuries), the span the accuracy against JPL Horizons is proved
/// over. The library itself claims a far wider range; the adapter does not
/// claim what it did not verify. Outside it, [position] returns
/// [OutOfCoveredRange] (R-2), never an approximate position. [Body.node] is
/// the exception: it comes from the shared mean-node formula for any instant.
final class AstronomyEphemeris
    with MeanAscendingNodeFormula
    implements EphemerisPort {
  AstronomyEphemeris({required this._source});

  final BodyStateSource _source;

  static final UtcRange _coveredRange = UtcRange(
    DateTime.utc(1899, 12, 31, 12),
    DateTime.utc(2100, 1, 1, 12),
  );

  @override
  UtcRange get coveredRange => _coveredRange;

  @override
  EphemerisResult position(Body body, DateTime utc) {
    if (!utc.isUtc) {
      throw ArgumentError.value(utc, 'utc', 'must be a UTC DateTime');
    }
    // The node first: it is formula-based and not bounded by the range.
    if (body == Body.node) {
      return EphemerisSuccess(meanAscendingNode(utc));
    }
    if (!coveredRange.contains(utc)) {
      return OutOfCoveredRange(requested: utc, covered: coveredRange);
    }
    // One call per position: the speed is derived from this state's own
    // vectors, never from a second call at a neighbouring instant.
    final state = _source.bodyState(body, utc);
    final speed = eclipticLongitudeRateDegreesPerDay(
      x: state.x,
      y: state.y,
      vx: state.vx,
      vy: state.vy,
    );
    return EphemerisSuccess(
      EclipticPosition(
        longitude: normalizeDegrees(state.longitude),
        speed: speed,
      ),
    );
  }
}
