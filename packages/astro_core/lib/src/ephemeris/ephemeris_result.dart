import 'ecliptic_position.dart';
import 'utc_range.dart';

/// The outcome of asking an `EphemerisPort` for a position.
///
/// Sealed so that callers must handle every outcome with an exhaustive
/// `switch`: a result outside the covered date range can never be used as if
/// it were a valid position (R-2).
sealed class EphemerisResult {
  const EphemerisResult();
}

/// A valid position within the source's covered range.
final class EphemerisSuccess extends EphemerisResult {
  const EphemerisSuccess(this.position);

  final EclipticPosition position;

  @override
  bool operator ==(Object other) =>
      other is EphemerisSuccess && other.position == position;

  @override
  int get hashCode => position.hashCode;

  @override
  String toString() => 'EphemerisSuccess($position)';
}

/// A position could not be provided with the source's stated accuracy.
///
/// Sealed so that new failure kinds remain exhaustively handled by every
/// consumer.
sealed class EphemerisFailure extends EphemerisResult {
  const EphemerisFailure();
}

/// The requested moment is outside the range the source's data covers
/// (spec R-2 and "Computation settings": outside the range a clear message is
/// shown instead of a wrong result).
final class OutOfCoveredRange extends EphemerisFailure {
  const OutOfCoveredRange({required this.requested, required this.covered});

  /// The UTC moment that was requested.
  final DateTime requested;

  /// The range the source does cover, for the user-facing message.
  final UtcRange covered;

  @override
  bool operator ==(Object other) =>
      other is OutOfCoveredRange &&
      other.requested == requested &&
      other.covered == covered;

  @override
  int get hashCode => Object.hash(requested, covered);

  @override
  String toString() =>
      'OutOfCoveredRange(requested: $requested, covered: $covered)';
}
