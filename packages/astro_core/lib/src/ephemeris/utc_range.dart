/// An inclusive range of UTC instants, such as the dates a position source
/// covers with its stated accuracy (R-2: outside it the app must show a clear
/// message instead of a wrong result).
final class UtcRange {
  /// Creates the range `[start, end]`, both ends included.
  ///
  /// Throws [ArgumentError] if either bound is not UTC or if [end] is before
  /// [start]. A single-instant range (`start == end`) is allowed.
  UtcRange(this.start, this.end) {
    _requireUtc(start, 'start');
    _requireUtc(end, 'end');
    if (end.isBefore(start)) {
      throw ArgumentError.value(
        end,
        'end',
        'must not be before start ($start)',
      );
    }
  }

  /// First covered instant (inclusive).
  final DateTime start;

  /// Last covered instant (inclusive).
  final DateTime end;

  /// Whether [utc] lies within `[start, end]`.
  ///
  /// Throws [ArgumentError] if [utc] is not UTC: local times must be
  /// converted by the caller, never silently treated as UTC.
  bool contains(DateTime utc) {
    _requireUtc(utc, 'utc');
    return !utc.isBefore(start) && !utc.isAfter(end);
  }

  static void _requireUtc(DateTime value, String name) {
    if (!value.isUtc) {
      throw ArgumentError.value(value, name, 'must be a UTC DateTime');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is UtcRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'UtcRange($start, $end)';
}
