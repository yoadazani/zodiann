import 'ephemeris/body.dart';

/// A degree crossing: the moment a body's longitude equals a whole degree
/// (spec "Degree crossings" and "Data model and user settings").
///
/// **Derived, never persisted** (spec data model: Crossing — Saved? No;
/// DATA-2: computation results are not saved because they can be
/// recomputed). It deliberately has no JSON form, and a workspace
/// architecture test fails if a storage layer refers to it.
final class Crossing {
  /// Throws [ArgumentError] if [timeUtc] is not UTC or [degree] is outside
  /// 0…359 (the absolute whole degree; T-CRS-3: never 360 or negative).
  Crossing({
    required this.timeUtc,
    required this.body,
    required this.degree,
    required this.retrograde,
  }) {
    if (!timeUtc.isUtc) {
      throw ArgumentError.value(timeUtc, 'timeUtc', 'must be UTC');
    }
    if (degree < 0 || degree > 359) {
      throw ArgumentError.value(degree, 'degree', 'must be in 0…359');
    }
  }

  /// The crossing moment, in UTC.
  final DateTime timeUtc;

  final Body body;

  /// The absolute whole degree crossed, 0…359.
  final int degree;

  /// Whether the body was moving retrograde at the crossing.
  final bool retrograde;

  @override
  bool operator ==(Object other) =>
      other is Crossing &&
      other.timeUtc == timeUtc &&
      other.body == body &&
      other.degree == degree &&
      other.retrograde == retrograde;

  @override
  int get hashCode => Object.hash(timeUtc, body, degree, retrograde);

  @override
  String toString() =>
      'Crossing(${body.name} $degree° at $timeUtc${retrograde ? ' ℞' : ''})';
}
