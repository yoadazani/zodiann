/// Square of Nine highlight classification (spec "Gann spiral", SQ-11 …
/// SQ-15, Appendix B, Appendix C).
///
/// This is the spec's **fixed** classifier: exact integer tests on the
/// spiral's ring `k` and steps `i`, never on the floating-point angle.
/// Evaluating arbitrary user-defined `HighlightRule`s is ZOD-EXT-008.
library;

import '../model/highlight_rule.dart';
import '../spiral/spiral.dart';

/// The three highlight categories, in priority order (SQ-15).
enum HighlightCategory {
  /// Blue: the axes 0°, 90°, 180°, 270° (SQ-12) — `i mod 2k = 0`.
  axis('axes'),

  /// Yellow: the diagonals 45°, 135°, 225°, 315° (SQ-13) — `i mod k = 0`
  /// and not an axis.
  diagonal('diagonals'),

  /// Gray: the other multiples of 22.5° (SQ-14) — `2i mod k = 0` and not an
  /// axis or a diagonal.
  eighth('eighths');

  const HighlightCategory(this.defaultRuleId);

  /// The id of this category's rule in `defaultHighlightRules` (ZOD-FND-012).
  /// Colors come from that rule's `colorToken` via [highlightRuleFor].
  final String defaultRuleId;
}

/// The highlight category of the spiral cell [cell], or `null` if it has
/// none.
///
/// [cell] is a spiral **position** (`spiralCell(n)`, where `n` is the cell's
/// position index and 1 is the center), never the number or date displayed
/// in it. This follows the spec's working assumption that highlights stay
/// fixed to position when the numbers-mode anchor changes (EX-11; an open
/// decision, TASKS.md §6.2), and the spec's discrete ring angle.
///
/// Rules, in strict priority order (SQ-15): blue `i mod 2k = 0`, then yellow
/// `i mod k = 0`, then gray `2i mod k = 0`. A cell matching none is not
/// highlighted. The center has no angle and is never classified (it gets
/// its own amber marker elsewhere).
HighlightCategory? classifyHighlight(SpiralCell cell) {
  if (cell.isCenter) return null;
  final i = cell.stepsFromAxis!;
  final k = cell.ring;
  if (i % (2 * k) == 0) return HighlightCategory.axis;
  if (i % k == 0) return HighlightCategory.diagonal;
  if ((2 * i) % k == 0) return HighlightCategory.eighth;
  return null;
}

/// The rule in [rules] (a square's `highlights`) for [category], matched by
/// [HighlightCategory.defaultRuleId], or `null` if the square has none — in
/// which case that category is shown without a highlight. Rule ids are
/// unique within a square (enforced by `SquareConfig`).
HighlightRule? highlightRuleFor(
  HighlightCategory category,
  List<HighlightRule> rules,
) {
  for (final rule in rules) {
    if (rule.id == category.defaultRuleId) return rule;
  }
  return null;
}
