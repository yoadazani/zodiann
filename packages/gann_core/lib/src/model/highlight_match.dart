import 'json_read.dart';
import 'list_equality.dart';

/// Which cells a highlight rule matches, by the cell's angle (spec "Data
/// model and user settings"; angles per SQ-11, in degrees in `[0, 360)`).
///
/// JSON uses a `"type"` discriminator: `"angles"` or `"multipleOf"`.
sealed class HighlightMatch {
  const HighlightMatch();

  Map<String, Object?> toJson();

  /// Throws [FormatException] for any malformed or invalid input.
  static HighlightMatch fromJson(Object? json) {
    final map = asJsonObject(json, 'HighlightMatch');
    final type = readField<String>(map, 'type');
    return switch (type) {
      'angles' => buildOrFormatError(
        'AnglesMatch',
        () => AnglesMatch([
          for (final value in readField<List<Object?>>(map, 'degrees'))
            asDouble(value, 'Each angle'),
        ]),
      ),
      'multipleOf' => buildOrFormatError(
        'MultipleOfMatch',
        () => MultipleOfMatch(readDouble(map, 'degrees')),
      ),
      _ => throw FormatException('Unknown HighlightMatch type "$type"', type),
    };
  }
}

/// Matches cells whose angle is one of [degrees] (e.g. the axes 0, 90, 180,
/// 270).
final class AnglesMatch extends HighlightMatch {
  /// Throws [ArgumentError] if [degrees] is empty or any value is not finite
  /// or outside `[0, 360)`. The list is copied and stored unmodifiable.
  AnglesMatch(List<double> degrees)
    : degrees = List.unmodifiable(degrees),
      super() {
    if (this.degrees.isEmpty) {
      throw ArgumentError.value(degrees, 'degrees', 'must not be empty');
    }
    for (final value in this.degrees) {
      if (!value.isFinite || value < 0 || value >= 360) {
        throw ArgumentError.value(
          value,
          'degrees',
          'each angle must be finite and in [0, 360)',
        );
      }
    }
  }

  final List<double> degrees;

  @override
  Map<String, Object?> toJson() => {'type': 'angles', 'degrees': degrees};

  @override
  bool operator ==(Object other) =>
      other is AnglesMatch && listEquals(other.degrees, degrees);

  @override
  int get hashCode => listHash(degrees);

  @override
  String toString() => 'AnglesMatch($degrees)';
}

/// Matches cells whose angle is a multiple of [degrees] (e.g. 22.5).
final class MultipleOfMatch extends HighlightMatch {
  /// Throws [ArgumentError] if [degrees] is not finite or not positive.
  MultipleOfMatch(this.degrees) {
    if (!degrees.isFinite || degrees <= 0) {
      throw ArgumentError.value(
        degrees,
        'degrees',
        'must be finite and positive',
      );
    }
  }

  final double degrees;

  @override
  Map<String, Object?> toJson() => {'type': 'multipleOf', 'degrees': degrees};

  @override
  bool operator ==(Object other) =>
      other is MultipleOfMatch && other.degrees == degrees;

  @override
  int get hashCode => degrees.hashCode;

  @override
  String toString() => 'MultipleOfMatch($degrees)';
}
