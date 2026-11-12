import 'angles.dart';
import 'ecliptic_position.dart';
import 'ephemeris_port.dart';

/// Ω at the epoch 2000-01-01 12:00 UTC, in degrees (spec "Planet position").
const double meanNodeEpochLongitude = 125.04452;

/// Rate of Ω in degrees per Julian century; Ω decreases by this much.
const double meanNodeDegreesPerCentury = 1934.136261;

/// The node's constant speed in degrees per day (negative: always moving
/// backward).
const double meanNodeSpeedDegreesPerDay = -meanNodeDegreesPerCentury / 36525;

final _epoch = DateTime.utc(2000, 1, 1, 12);
const _microsecondsPerCentury = 36525 * Duration.microsecondsPerDay;

/// The mean ascending lunar node at the UTC instant [utc]: the single
/// implementation of the formula in the app (ZOD-EPH-001).
///
/// * `Ω = 125.04452 − 1934.136261·T` degrees, where `T` is the number of
///   Julian centuries since 2000-01-01 12:00 UTC, computed from the UTC
///   instant itself (`T = (JD_UTC − 2451545.0) / 36525`). No ΔT / terrestrial
///   time conversion is applied: the spec defines `T` from UTC.
/// * The longitude is normalized to `[0, 360)` with [normalizeDegrees].
/// * The speed is the constant [meanNodeSpeedDegreesPerDay].
///
/// This is a formula-based point, not an apparent physical position.
///
/// **Accuracy:** the spec states an expected deviation of less than 0.01°
/// from the full formula over two hundred years around 2000. This bound is
/// pending independent verification by T-EPH-2 (ZOD-TST-002).
///
/// Throws [ArgumentError] if [utc] is not UTC.
EclipticPosition meanAscendingNodeAt(DateTime utc) {
  if (!utc.isUtc) {
    throw ArgumentError.value(utc, 'utc', 'must be a UTC DateTime');
  }
  final t = utc.difference(_epoch).inMicroseconds / _microsecondsPerCentury;
  return EclipticPosition(
    longitude: normalizeDegrees(
      meanNodeEpochLongitude - meanNodeDegreesPerCentury * t,
    ),
    speed: meanNodeSpeedDegreesPerDay,
  );
}

/// Provides [EphemerisPort.meanAscendingNode] from the shared formula
/// [meanAscendingNodeAt], so no adapter re-implements it.
///
/// Usage: `final class XxxPort with MeanAscendingNodeFormula implements
/// EphemerisPort`. (It is declared with `implements`, not `on`: an `interface`
/// class cannot be a superclass constraint outside its declaring library.)
///
/// `Body.node` is answered by the formula for **any** UTC instant, regardless
/// of [EphemerisPort.coveredRange]: the formula does not depend on the
/// source's data files. In `position`, put the node branch **before** the
/// covered-range check:
///
/// ```dart
/// if (body == Body.node) return EphemerisSuccess(meanAscendingNode(utc));
/// if (!coveredRange.contains(utc)) {
///   return OutOfCoveredRange(requested: utc, covered: coveredRange);
/// }
/// ```
mixin MeanAscendingNodeFormula implements EphemerisPort {
  @override
  EclipticPosition meanAscendingNode(DateTime utc) => meanAscendingNodeAt(utc);
}
