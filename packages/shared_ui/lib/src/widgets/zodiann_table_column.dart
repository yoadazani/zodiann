/// Which edge a table column's cells sit against (kit.css `.tbl th` is
/// `text-align: start`, `.end` is `text-align: end`). Logical, so it flips
/// under RTL.
enum ZodiannTableAlign {
  /// Against the start edge (left in LTR, right in RTL).
  start,

  /// Against the end edge.
  end,
}

/// How tightly a table's cells are padded (kit.css `.tbl` and wheel.html's
/// override below 1100 px).
///
/// The **caller** chooses it per breakpoint: only the screen knows it is in
/// its compact layout. The kit's compact range is `max-width: 1100px`
/// (inclusive), while `ZodiannBreakpoint` treats 1100 as desktop.
enum ZodiannTableDensity {
  /// Inline padding 16, cell text 14.
  regular,

  /// Inline padding 10, cell text 13. The header label keeps its 12.
  compact,
}

/// One column of a [ZodiannTable]: its header [label], the edge its cells
/// align to, and its width, declared rather than measured from content.
///
/// A column is either **flex** (a share of the width left after the fixed
/// columns, 1 by default) or **fixed** (a [width] in logical pixels), never
/// both. Declared widths let a row be an independent widget that lines up
/// with every other row, so a long list can build rows lazily.
class ZodiannTableColumn {
  /// A column with a header [label].
  const ZodiannTableColumn({
    required this.label,
    this.alignment = ZodiannTableAlign.start,
    this.flex,
    this.width,
  }) : assert(
         flex == null || width == null,
         'a column is flex or fixed width, never both',
       ),
       assert(flex == null || flex > 0, 'flex must be positive'),
       assert(width == null || width >= 0, 'width must not be negative');

  /// The header text, localized by the caller, in sentence case.
  final String label;

  /// The edge the header label and the cells align to.
  final ZodiannTableAlign alignment;

  /// The share of the free width, or null for 1 (ignored when [width] is
  /// set).
  final double? flex;

  /// A fixed width, or null for a flex column.
  final double? width;
}

/// The width of each of [columns] in [maxWidth]: fixed columns first, the
/// rest split by flex. Never negative; when the fixed columns alone exceed
/// [maxWidth] the flex columns get 0.
List<double> resolveTableColumnWidths(
  List<ZodiannTableColumn> columns,
  double maxWidth,
) {
  var fixed = 0.0;
  var flexTotal = 0.0;
  for (final c in columns) {
    if (c.width != null) {
      fixed += c.width!;
    } else {
      flexTotal += c.flex ?? 1;
    }
  }
  final free = (maxWidth - fixed).clamp(0.0, double.infinity);
  return [
    for (final c in columns)
      c.width ?? (flexTotal == 0 ? 0.0 : free * (c.flex ?? 1) / flexTotal),
  ];
}
