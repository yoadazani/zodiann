import 'highlight_match.dart';
import 'json_read.dart';

/// A highlight rule on the Square of Nine: which angles, in which color, and
/// with what priority (a lower number wins).
final class HighlightRule {
  /// Throws [ArgumentError] if [id], [label] or [colorToken] is empty.
  HighlightRule({
    required this.id,
    required this.label,
    required this.match,
    required this.colorToken,
    required this.priority,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    if (label.isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
    if (colorToken.isEmpty) {
      throw ArgumentError.value(colorToken, 'colorToken', 'must not be empty');
    }
  }

  /// Throws [FormatException] for any malformed or invalid input.
  static HighlightRule fromJson(Object? json) {
    final map = asJsonObject(json, 'HighlightRule');
    final id = readField<String>(map, 'id');
    final label = readField<String>(map, 'label');
    final match = HighlightMatch.fromJson(readField<Object?>(map, 'match'));
    final colorToken = readField<String>(map, 'colorToken');
    final priority = readField<int>(map, 'priority');
    return buildOrFormatError(
      'HighlightRule',
      () => HighlightRule(
        id: id,
        label: label,
        match: match,
        colorToken: colorToken,
        priority: priority,
      ),
    );
  }

  /// Stable identifier.
  final String id;

  /// Display label. For the default rules this is a stable key that the UI
  /// translates (L-9); user-defined rules may carry free text.
  final String label;

  final HighlightMatch match;

  /// A **color-role family key** from the design system (MASTER.md §2.2),
  /// never a hex value. The UI resolves it to the family's tokens:
  /// `<family>-fill` for the cell background and `<family>-ink` for its text,
  /// plus the bare `<family>` token as the saturated accent where the design
  /// defines one (`axis` and `diag` do; `eighth` has only `-fill`/`-ink`).
  /// Defaults: `axis` (blue), `diag` (yellow), `eighth` (gray).
  final String colorToken;

  /// Lower number wins when several rules match a cell.
  final int priority;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'match': match.toJson(),
    'colorToken': colorToken,
    'priority': priority,
  };

  @override
  bool operator ==(Object other) =>
      other is HighlightRule &&
      other.id == id &&
      other.label == label &&
      other.match == match &&
      other.colorToken == colorToken &&
      other.priority == priority;

  @override
  int get hashCode => Object.hash(id, label, match, colorToken, priority);

  @override
  String toString() =>
      'HighlightRule($id, $label, $match, $colorToken, priority $priority)';
}

/// The default highlight rules a new square gets (spec "Default highlight
/// rules"), in priority order. Colors are role-family keys from the design
/// reference (MASTER.md §2.2): `axis` (blue), `diag` (yellow), `eighth`
/// (gray); see [HighlightRule.colorToken] for how they resolve.
final List<HighlightRule> defaultHighlightRules = List.unmodifiable([
  HighlightRule(
    id: 'axes',
    label: 'axes',
    match: AnglesMatch([0, 90, 180, 270]),
    colorToken: 'axis',
    priority: 1,
  ),
  HighlightRule(
    id: 'diagonals',
    label: 'diagonals',
    match: AnglesMatch([45, 135, 225, 315]),
    colorToken: 'diag',
    priority: 2,
  ),
  HighlightRule(
    id: 'eighths',
    label: 'eighths',
    match: MultipleOfMatch(22.5),
    colorToken: 'eighth',
    priority: 3,
  ),
]);
