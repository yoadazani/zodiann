import 'highlight_rule.dart';
import 'json_read.dart';
import 'list_equality.dart';
import 'offset_date_time.dart';
import 'square_enums.dart';

/// A saved Square of Nine configuration (spec "Data model and user
/// settings"): name, mode, anchor, size, spiral direction and highlight
/// rules. Saved on the device (DATA-1/2) and exported in backups (DATA-3).
final class SquareConfig {
  /// Creates a validated configuration.
  ///
  /// Defaults: [highlights] = [defaultHighlightRules] when `null`;
  /// spiral [SpiralStart.left] + [SpiralRotation.cw] (SQ-8); [stepHours] 4.
  ///
  /// Throws [ArgumentError] if:
  /// * [id] or [name] is empty;
  /// * [size] is not odd or not in 3…61;
  /// * [anchor] is set in [SquareMode.numbers] mode, or missing in a date
  ///   mode;
  /// * [stepHours] is less than 1;
  /// * [createdAt] or [updatedAt] is not UTC, or [updatedAt] is before
  ///   [createdAt];
  /// * two highlight rules share an id.
  SquareConfig({
    required this.id,
    required this.name,
    required this.mode,
    this.anchor,
    this.stepHours = 4,
    required this.size,
    this.spiralStart = SpiralStart.left,
    this.spiralRotation = SpiralRotation.cw,
    List<HighlightRule>? highlights,
    required this.createdAt,
    required this.updatedAt,
  }) : highlights = List.unmodifiable(highlights ?? defaultHighlightRules) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (size < minSize || size > maxSize || size.isEven) {
      throw ArgumentError.value(
        size,
        'size',
        'must be odd and between $minSize and $maxSize',
      );
    }
    if (mode == SquareMode.numbers && anchor != null) {
      throw ArgumentError.value(
        anchor,
        'anchor',
        'must be null in numbers mode',
      );
    }
    if (mode != SquareMode.numbers && anchor == null) {
      throw ArgumentError.value(
        anchor,
        'anchor',
        'is required in ${mode.name} mode',
      );
    }
    if (stepHours < 1) {
      throw ArgumentError.value(stepHours, 'stepHours', 'must be at least 1');
    }
    if (!createdAt.isUtc) {
      throw ArgumentError.value(createdAt, 'createdAt', 'must be UTC');
    }
    if (!updatedAt.isUtc) {
      throw ArgumentError.value(updatedAt, 'updatedAt', 'must be UTC');
    }
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'must not be before createdAt',
      );
    }
    final ids = <String>{};
    for (final rule in this.highlights) {
      if (!ids.add(rule.id)) {
        throw ArgumentError.value(
          rule.id,
          'highlights',
          'contains duplicate rule id',
        );
      }
    }
  }

  /// Throws [FormatException] for any malformed or invalid input.
  static SquareConfig fromJson(Object? json) {
    final map = asJsonObject(json, 'SquareConfig');
    final anchorJson = map['anchor'];
    final OffsetDateTime? anchor = switch (anchorJson) {
      null => null,
      final String text => OffsetDateTime.parse(text),
      _ => throw FormatException(
        'Field "anchor" must be a string or null',
        anchorJson,
      ),
    };
    final id = readField<String>(map, 'id');
    final name = readField<String>(map, 'name');
    final mode = readEnum(map, 'mode', SquareMode.values);
    final stepHours = readField<int>(map, 'stepHours');
    final size = readField<int>(map, 'size');
    final spiralStart = readEnum(map, 'spiralStart', SpiralStart.values);
    final spiralRotation = readEnum(
      map,
      'spiralRotation',
      SpiralRotation.values,
    );
    final highlights = [
      for (final rule in readField<List<Object?>>(map, 'highlights'))
        HighlightRule.fromJson(rule),
    ];
    final createdAt = readUtc(map, 'createdAt');
    final updatedAt = readUtc(map, 'updatedAt');
    return buildOrFormatError(
      'SquareConfig',
      () => SquareConfig(
        id: id,
        name: name,
        mode: mode,
        anchor: anchor,
        stepHours: stepHours,
        size: size,
        spiralStart: spiralStart,
        spiralRotation: spiralRotation,
        highlights: highlights,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  static const minSize = 3;
  static const maxSize = 61;

  final String id;
  final String name;
  final SquareMode mode;

  /// The anchor moment with its time-zone offset (DATA-4); `null` in numbers
  /// mode.
  final OffsetDateTime? anchor;

  /// Hours per cell in date-and-time mode (default 4; editable per SET-004).
  final int stepHours;

  /// Side length of the square: odd, between 3 and 61.
  final int size;

  final SpiralStart spiralStart;
  final SpiralRotation spiralRotation;

  /// Highlight rules (unmodifiable).
  final List<HighlightRule> highlights;

  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'mode': mode.name,
    'anchor': anchor?.toIso8601String(),
    'stepHours': stepHours,
    'size': size,
    'spiralStart': spiralStart.name,
    'spiralRotation': spiralRotation.name,
    'highlights': [for (final rule in highlights) rule.toJson()],
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is SquareConfig &&
      other.id == id &&
      other.name == name &&
      other.mode == mode &&
      other.anchor == anchor &&
      other.stepHours == stepHours &&
      other.size == size &&
      other.spiralStart == spiralStart &&
      other.spiralRotation == spiralRotation &&
      listEquals(other.highlights, highlights) &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    mode,
    anchor,
    stepHours,
    size,
    spiralStart,
    spiralRotation,
    listHash(highlights),
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'SquareConfig($id, "$name", ${mode.name}, size $size, anchor $anchor)';
}
