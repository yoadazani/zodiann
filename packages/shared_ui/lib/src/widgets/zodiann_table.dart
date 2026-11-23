import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';
import 'zodiann_table_column.dart';

/// The shared table shell (MASTER.md §10 "Tables", kit.css `.tbl`): a header
/// of column labels above rows that line up through **declared columns**.
///
/// `ZodiannTable` is the eager form, for a short table such as the 11-row
/// positions table: it builds its header from [columns], gives its rows the
/// same [columns] and [density] through a private scope, and marks the last
/// row so it draws no divider. A long list composes [ZodiannTableHeader] and
/// lazy [ZodiannTableRow]s itself (a `ListView.builder`), giving each row the
/// same `columns`.
///
/// It needs a **bounded width** (flex columns share it): in a horizontal
/// scroll view, give it a `SizedBox(width: …)`.
///
/// A panel that holds a table passes `clipBehavior: Clip.antiAlias` so a
/// hovered or selected last row does not square off the panel's corner; the
/// table itself never clips.
class ZodiannTable extends StatelessWidget {
  /// A table of [columns] and [rows].
  const ZodiannTable({
    super.key,
    required this.columns,
    required this.rows,
    this.density = ZodiannTableDensity.regular,
  });

  /// The columns, in reading order (the first is at the start edge).
  final List<ZodiannTableColumn> columns;

  /// The rows. They must not pass their own `columns` or `density`.
  final List<ZodiannTableRow> rows;

  /// How tightly the cells are padded.
  final ZodiannTableDensity density;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'ZodiannTable needs a bounded width: give it a SizedBox(width: …) '
          'inside a horizontal scroll view.',
        );
        return _TableScope(
          columns: columns,
          density: density,
          child: Semantics(
            container: true,
            role: SemanticsRole.table,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ZodiannTableHeader(columns: columns, density: density),
                for (var i = 0; i < rows.length; i++)
                  i == rows.length - 1 ? _LastRow(child: rows[i]) : rows[i],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The header row of a table: the columns' labels (12 / 500, `text-3`,
/// sentence case, one line) above a `line-soft` rule.
///
/// Public so a lazy list can place it above a `ListView`; inside a
/// [ZodiannTable] the table builds it.
class ZodiannTableHeader extends StatelessWidget {
  /// A header for [columns].
  const ZodiannTableHeader({
    super.key,
    required this.columns,
    this.density = ZodiannTableDensity.regular,
  });

  /// The columns whose labels it shows.
  final List<ZodiannTableColumn> columns;

  /// How tightly the labels are padded.
  final ZodiannTableDensity density;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final pad = _inlinePadding(density);
    final inTable = _TableScope.maybeOf(context) != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'ZodiannTableHeader needs a bounded width.',
        );
        final widths = resolveTableColumnWidths(columns, constraints.maxWidth);
        return Semantics(
          container: true,
          role: inTable ? SemanticsRole.row : SemanticsRole.none,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: ZodiannSize.tableHeaderPadding,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < columns.length; i++)
                      SizedBox(
                        width: widths[i],
                        child: _Slot(
                          padding: pad,
                          alignment: columns[i].alignment,
                          role: inTable
                              ? SemanticsRole.columnHeader
                              : SemanticsRole.none,
                          child: Text(
                            columns[i].label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: styles.label.copyWith(color: s.text3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _Rule(color: s.lineSoft),
            ],
          ),
        );
      },
    );
  }
}

/// One row of a table: a cell per column, 44 high including its divider.
///
/// Inside a [ZodiannTable] it reads the table's columns and density (pass
/// neither). Standalone, in a lazy list, pass [columns] (the same list the
/// header has) and set [isLast] on the last item.
class ZodiannTableRow extends StatefulWidget {
  /// A row of [cells], one per column.
  const ZodiannTableRow({
    super.key,
    this.columns,
    required this.cells,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
    this.isLast = false,
    this.density,
  }) : assert(
         columns == null || columns.length == cells.length,
         'a row needs one cell per column',
       ),
       assert(
         onTap == null || semanticLabel != null,
         'a tappable row needs a semanticLabel (its spoken name)',
       );

  /// The columns, or null inside a [ZodiannTable] (read from its scope).
  final List<ZodiannTableColumn>? columns;

  /// The cells, one per column. Each is any widget; it is laid out within its
  /// column's width and clipped to it.
  final List<Widget> cells;

  /// Whether this is the selected row (the one under the pointer, the open
  /// item): an `accent-soft` fill and a 3 px `accent` bar on the start edge.
  /// Selected wins over hover.
  final bool selected;

  /// Called when the row is activated, or null for a read-only row, which
  /// has no hover fill.
  final VoidCallback? onTap;

  /// The row's spoken name (a screen reader announces it with "button");
  /// required when [onTap] is set. The caller localizes it.
  final String? semanticLabel;

  /// Whether this is the last row: it draws no divider and is 1 px shorter
  /// (kit.css `tr:last-child td { border-bottom: 0 }`). [ZodiannTable] sets
  /// it for its last row.
  final bool isLast;

  /// How tightly the cells are padded, or null inside a [ZodiannTable].
  final ZodiannTableDensity? density;

  @override
  State<ZodiannTableRow> createState() => _ZodiannTableRowState();
}

class _ZodiannTableRowState extends State<ZodiannTableRow> {
  bool _hover = false;
  bool _focusRing = false;

  @override
  Widget build(BuildContext context) {
    final columns = widget.columns;
    final cells = widget.cells;
    final density = widget.density;
    final scope = _TableScope.maybeOf(context);
    assert(
      scope == null || (columns == null && density == null),
      'a ZodiannTableRow inside a ZodiannTable must not pass its own '
      'columns or density',
    );
    final cols = columns ?? scope?.columns;
    assert(
      cols != null,
      'a ZodiannTableRow outside a ZodiannTable needs columns',
    );
    assert(
      cols!.length == cells.length,
      'a row needs one cell per column: ${cells.length} cells for '
      '${cols.length} columns',
    );
    final d = density ?? scope?.density ?? ZodiannTableDensity.regular;
    final inTable = scope != null;
    final last = widget.isLast || _LastRow.isIn(context);
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final pad = _inlinePadding(d);
    final textStyle =
        (d == ZodiannTableDensity.compact ? styles.small : styles.body)
            .copyWith(color: s.text);
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'ZodiannTableRow needs a bounded width.',
        );
        final widths = resolveTableColumnWidths(cols!, constraints.maxWidth);
        // Fill order: hover (surface-2) under selected (accent-soft); the
        // fill and the bar stop above the divider, as the kit draws them.
        final fill = widget.selected
            ? s.accentSoft
            : (_hover && widget.onTap != null ? s.surface2 : null);
        Widget body = Stack(
          children: [
            if (fill != null) Positioned.fill(child: ColoredBox(color: fill)),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ZodiannSize.tableRow - ZodiannSize.hairline,
              ),
              child: DefaultTextStyle(
                style: textStyle,
                child: Row(
                  children: [
                    for (var i = 0; i < cols.length; i++)
                      SizedBox(
                        width: widths[i],
                        child: _Slot(
                          padding: pad,
                          alignment: cols[i].alignment,
                          role: inTable
                              ? SemanticsRole.cell
                              : SemanticsRole.none,
                          child: cells[i],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.selected)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: ZodiannSize.tableSelectedBar,
                child: ColoredBox(color: s.accent),
              ),
            // The keyboard ring sits inside the row's edge, so no clipping
            // ancestor (a panel with Clip.antiAlias) can hide it.
            if (_focusRing)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: s.focus,
                        width: ZodiannStates.focusRingWidth,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
        final onTap = widget.onTap;
        if (onTap != null) {
          body = FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            onShowFocusHighlight: (v) {
              if (_focusRing != v) setState(() => _focusRing = v);
            },
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  onTap();
                  return null;
                },
              ),
            },
            child: MouseRegion(
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: onTap,
                child: body,
              ),
            ),
          );
        }
        // Outermost, so the focus semantics merge into this node and, inside
        // a table, the table's children are all rows.
        body = Semantics(
          container: true,
          role: inTable ? SemanticsRole.row : SemanticsRole.none,
          button: onTap != null,
          label: widget.semanticLabel,
          selected: widget.selected ? true : null,
          onTap: onTap,
          child: body,
        );
        return last
            ? body
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  body,
                  _Rule(color: s.lineSoft),
                ],
              );
      },
    );
  }
}

/// A 1 px `line-soft` rule across the full width (a divider or the header's
/// bottom edge).
class _Rule extends StatelessWidget {
  const _Rule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: const SizedBox(width: double.infinity, height: ZodiannSize.hairline),
  );
}

double _inlinePadding(ZodiannTableDensity density) =>
    density == ZodiannTableDensity.compact
    ? ZodiannSize.tableCompactPadding
    : ZodiannSpace.s4;

/// A cell's slot: the inline padding, then a clip to the column's inner
/// width, then the cell aligned to the column's edge. A plain widget wider
/// than the slot is clamped by the loose constraints and never moves another
/// column; one that cannot shrink (a `Row` of fixed-width children) overflows
/// by its own contract.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.padding,
    required this.alignment,
    required this.role,
    required this.child,
  });

  final double padding;
  final ZodiannTableAlign alignment;

  /// `cell` or `columnHeader` inside a table, `none` standalone (table roles
  /// need a table parent; Flutter 3.50 asserts otherwise).
  final SemanticsRole role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: padding),
      child: ClipRect(
        child: Align(
          alignment: alignment == ZodiannTableAlign.end
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Semantics(container: true, role: role, child: child),
        ),
      ),
    );
  }
}

/// What a [ZodiannTable] tells its header and rows: the columns and density
/// they share.
class _TableScope extends InheritedWidget {
  const _TableScope({
    required this.columns,
    required this.density,
    required super.child,
  });

  final List<ZodiannTableColumn> columns;
  final ZodiannTableDensity density;

  static _TableScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TableScope>();

  @override
  bool updateShouldNotify(_TableScope old) =>
      old.columns != columns || old.density != density;
}

/// Marks the last row of a [ZodiannTable] (rows are already-built widgets, so
/// the table cannot set their `isLast`).
class _LastRow extends InheritedWidget {
  const _LastRow({required super.child});

  static bool isIn(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LastRow>() != null;

  @override
  bool updateShouldNotify(_LastRow old) => false;
}
