import 'body.dart';
import 'ecliptic_position.dart';
import 'ephemeris_port.dart';
import 'ephemeris_result.dart';
import 'supported_date_range.dart';
import 'utc_range.dart';

/// The product-range guard in front of every [EphemerisPort] source
/// (ZOD-FND-011, owner decision 2026-11-25).
///
/// [position] returns [OutsideSupportedRange] for any instant outside
/// [SupportedDateRange], **for every body, the mean node included**, without
/// calling the wrapped source. Inside the range it returns the source's result
/// unchanged, so an [OutOfCoveredRange] from the source (data missing for a
/// date the product allows: a defect) passes through and is never hidden or
/// turned into a success.
///
/// ## Why the node is limited here and not in `meanAscendingNode`
///
/// [meanAscendingNode] returns a plain position with no failure channel, and
/// the contract has no exception for it, so it cannot report a limit. It is the
/// unlimited formula primitive and this class delegates it unchanged.
/// [position] is the only entry point that can fail, so it is the one place the
/// range is enforced. Production consumers must therefore never call the raw
/// node API; `test/architecture/node_bypass_test.dart` fails the build when
/// they do, and `test/architecture/port_binding_test.dart` fails it when a
/// production binding of the port does not wrap its source in this class.
///
/// [coveredRange] is the wrapped source's physical data coverage, not the
/// product range (see [EphemerisPort.coveredRange]).
final class SupportedRangeEphemeris implements EphemerisPort {
  const SupportedRangeEphemeris(this._source);

  final EphemerisPort _source;

  @override
  UtcRange get coveredRange => _source.coveredRange;

  /// Throws [ArgumentError] if [utc] is not UTC, before anything else, like
  /// every port.
  @override
  EphemerisResult position(Body body, DateTime utc) =>
      switch (SupportedDateRange.classify(utc)) {
        SupportedRangeSide.inside => _source.position(body, utc),
        SupportedRangeSide.before ||
        SupportedRangeSide.after => OutsideSupportedRange(
          requested: utc,
          supported: SupportedDateRange.range,
        ),
      };

  /// The raw formula primitive: delegated unchanged and never limited. Use
  /// `position(Body.node, utc)` to get the product limit.
  @override
  EclipticPosition meanAscendingNode(DateTime utc) =>
      _source.meanAscendingNode(utc);
}
