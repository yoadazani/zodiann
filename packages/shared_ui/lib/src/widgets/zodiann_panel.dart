import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/zodiann_layout.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';

/// The panel shell every screen's content sections sit in (MASTER.md §1
/// "Hairlines over boxes", §4; kit.css `.panel`): a `surface` fill, a 1 px
/// `line-soft` border and a 12 radius.
///
/// A panel has **no shadow and takes no elevation**: depth comes from the
/// surface ladder, and only floating layers (drawer, dialog, toast) cast
/// shadows (`ZodiannElevation.floating`). It is a plain box that takes its
/// parent's width; the page owns the gutter and the gap between panels.
///
/// Measured as a CSS border-box: the body padding sits **inside** the 1 px
/// border, and the head's height includes its rule.
///
/// Not for intrinsic measurement (`IntrinsicHeight`) when it has a head: see
/// [ZodiannPanelHead].
///
/// **Focus rings.** By default the panel does not clip, so a button's
/// 4 px focus ring in the head or body is never cut off (ZOD-UI-004). Content
/// that runs edge to edge (a table with its own background) would paint over
/// the rounded corners: pass [Clip.antiAlias] for it, and keep 4 px of
/// clear space around buttons so keyboard focus stays visible.
class ZodiannPanel extends StatelessWidget {
  /// A panel around [child], with an optional [head].
  const ZodiannPanel({
    super.key,
    this.head,
    this.bodyPadding,
    this.clipBehavior = Clip.none,
    required this.child,
  });

  /// The head above the body, or null for none (no head, no rule).
  final ZodiannPanelHead? head;

  /// The body's padding. Null is the layout's panel padding (20; 16 on a
  /// phone). Pass [EdgeInsets.zero] for a table or list that runs edge to
  /// edge.
  final EdgeInsetsGeometry? bodyPadding;

  /// How the body and head are clipped to the panel's rounded inner edge.
  /// [Clip.none] (the default) matches the reference, which does not clip.
  final Clip clipBehavior;

  /// The body.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final layout = ZodiannLayout.of(context);
    final s = Theme.of(context).extension<ZodiannSurfaces>()!;
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?head,
        Padding(
          padding: bodyPadding ?? EdgeInsets.all(layout.panelPadding),
          child: child,
        ),
      ],
    );
    if (clipBehavior != Clip.none) {
      content = ClipRRect(
        // The inner edge: the outer radius less the border.
        borderRadius: BorderRadius.all(
          Radius.circular(ZodiannRadius.lg - ZodiannSize.hairline),
        ),
        clipBehavior: clipBehavior,
        child: content,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.surface,
        border: Border.all(color: s.lineSoft, width: ZodiannSize.hairline),
        borderRadius: ZodiannRadius.panel,
      ),
      child: Padding(
        // Border-box: the content sits inside the 1 px border.
        padding: const EdgeInsets.all(ZodiannSize.hairline),
        child: content,
      ),
    );
  }
}

/// The head of a [ZodiannPanel] (kit.css `.panel-head`): a title with an
/// optional meta line, or any [leading] widget, and an optional [end] widget
/// at the end edge, above a 1 px `line-soft` rule.
///
/// The head is at least 56 high (52 on a phone), **including its rule**, and
/// grows for taller content. Its vertical padding is 16 (12 on a phone), its
/// horizontal padding the layout's panel padding.
///
/// Placement: [end] sits at the end edge. When it does not fit beside the
/// start group, the start group wraps in the remaining width (above phone
/// width), or [end] drops to a second line below it (on a phone, as the wheel
/// panel's head does). Title and meta wrap; nothing is truncated.
///
/// Not for intrinsic measurement (`IntrinsicHeight`): its height depends on
/// its width, and a `leading` such as a `LayoutBuilder` has no intrinsics.
class ZodiannPanelHead extends StatelessWidget {
  /// A head with a [title], [meta], or a free [leading], and an optional [end].
  const ZodiannPanelHead({
    super.key,
    this.title,
    this.meta,
    this.leading,
    this.end,
  }) : assert(
         leading == null || (title == null && meta == null),
         'leading replaces title and meta',
       );

  /// The panel title (16 / 600). A semantics header.
  final String? title;

  /// A quieter line after the title (13, `text-2`).
  final String? meta;

  /// Any widget in place of [title] and [meta].
  final Widget? leading;

  /// Any widget pushed to the end edge.
  final Widget? end;

  @override
  Widget build(BuildContext context) {
    final layout = ZodiannLayout.of(context);
    final phone = layout == ZodiannLayout.phone;
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final textDirection = Directionality.of(context);

    final Widget? start =
        leading ??
        (title == null && meta == null
            ? null
            : Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: ZodiannSpace.s3,
                runSpacing: ZodiannSpace.s1,
                children: [
                  if (title != null)
                    Semantics(
                      header: true,
                      child: Text(
                        title!,
                        style: styles.panelTitle.copyWith(color: s.text),
                      ),
                    ),
                  if (meta != null)
                    Text(meta!, style: styles.small.copyWith(color: s.text2)),
                ],
              ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          // The rule below is inside the 56 / 52.
          constraints: BoxConstraints(
            minHeight: layout.panelHeadHeight - ZodiannSize.hairline,
          ),
          child: Align(
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: layout.panelPadding,
                vertical: phone ? ZodiannSpace.s3 : ZodiannSpace.s4,
              ),
              child: _HeadLayout(
                gap: ZodiannSpace.s3,
                lineGap: ZodiannSpace.s2,
                stackEnd: phone,
                textDirection: textDirection,
                start: start,
                end: end,
              ),
            ),
          ),
        ),
        ColoredBox(
          color: s.lineSoft,
          child: const SizedBox(height: ZodiannSize.hairline),
        ),
      ],
    );
  }
}

enum _HeadSlot { start, end }

class _HeadLayout
    extends SlottedMultiChildRenderObjectWidget<_HeadSlot, RenderBox> {
  const _HeadLayout({
    required this.gap,
    required this.lineGap,
    required this.stackEnd,
    required this.textDirection,
    required this.start,
    required this.end,
  });

  final double gap;
  final double lineGap;
  final bool stackEnd;
  final TextDirection textDirection;
  final Widget? start;
  final Widget? end;

  @override
  Iterable<_HeadSlot> get slots => _HeadSlot.values;

  @override
  Widget? childForSlot(_HeadSlot slot) => switch (slot) {
    _HeadSlot.start => start,
    _HeadSlot.end => end,
  };

  @override
  _RenderHeadLayout createRenderObject(BuildContext context) =>
      _RenderHeadLayout(
        gap: gap,
        lineGap: lineGap,
        stackEnd: stackEnd,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderHeadLayout renderObject,
  ) {
    renderObject
      ..gap = gap
      ..lineGap = lineGap
      ..stackEnd = stackEnd
      ..textDirection = textDirection;
  }
}

/// Places the start group and the end widget (see [ZodiannPanelHead]).
///
/// 1. If start + gap + end fit, one line (children are laid out at their
///    natural width, never through intrinsics, so a `LayoutBuilder` works).
/// 2. Otherwise, above phone width, the end widget keeps at least half of the
///    row (or what the start group leaves) and the start group wraps in what
///    it leaves, still one row.
/// 3. Otherwise (phone), the end widget goes on a second line.
///
/// The layout fills the available width, so the end widget reaches the end
/// edge.
class _RenderHeadLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_HeadSlot, RenderBox> {
  _RenderHeadLayout({
    required this._gap,
    required this._lineGap,
    required this._stackEnd,
    required this._textDirection,
  });

  double _gap;
  double get gap => _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double _lineGap;
  double get lineGap => _lineGap;
  set lineGap(double v) {
    if (v == _lineGap) return;
    _lineGap = v;
    markNeedsLayout();
  }

  bool _stackEnd;
  bool get stackEnd => _stackEnd;
  set stackEnd(bool v) {
    if (v == _stackEnd) return;
    _stackEnd = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  RenderBox? get _start => childForSlot(_HeadSlot.start);
  RenderBox? get _end => childForSlot(_HeadSlot.end);

  /// Lays the children out with [layoutChild] and returns the size and the
  /// two offsets. Shared by [performLayout] and [computeDryLayout].
  ({Size size, Offset startAt, Offset endAt}) _arrange(
    BoxConstraints constraints,
    Size Function(RenderBox child, BoxConstraints c) layoutChild,
  ) {
    final start = _start;
    final end = _end;
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    final maxW = constraints.maxWidth;
    final width = maxW.isFinite ? maxW : null;
    final rtl = _textDirection == TextDirection.rtl;

    Size startSize = Size.zero;
    Size endSize = Size.zero;
    var stacked = false;
    if (start != null) startSize = layoutChild(start, loose);
    if (end != null) endSize = layoutChild(end, loose);
    if (start != null &&
        end != null &&
        startSize.width + _gap + endSize.width > maxW) {
      if (_stackEnd) {
        stacked = true;
      } else {
        // One row: the end widget keeps at least half of the row, or what
        // the start group leaves; the start group wraps in the rest.
        final endCap = math.max(
          (maxW - _gap) / 2,
          maxW - _gap - startSize.width,
        );
        if (endSize.width > endCap) {
          endSize = layoutChild(end, BoxConstraints(maxWidth: endCap));
        }
        startSize = layoutChild(
          start,
          BoxConstraints(maxWidth: math.max(0, maxW - _gap - endSize.width)),
        );
      }
    }

    final both = start != null && end != null;
    final double contentWidth =
        width ?? startSize.width + (both ? _gap : 0) + endSize.width;
    final double height;
    double startY;
    double endY;
    if (stacked) {
      startY = 0;
      endY = startSize.height + _lineGap;
      height = endY + endSize.height;
    } else {
      height = math.max(startSize.height, endSize.height);
      startY = (height - startSize.height) / 2;
      endY = (height - endSize.height) / 2;
    }
    final startX = rtl ? contentWidth - startSize.width : 0.0;
    final endX = rtl ? 0.0 : contentWidth - endSize.width;
    return (
      size: constraints.constrain(Size(contentWidth, height)),
      startAt: Offset(startX, startY),
      endAt: Offset(endX, endY),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _arrange(constraints, (child, c) => child.getDryLayout(c)).size;

  @override
  void performLayout() {
    final r = _arrange(constraints, (child, c) {
      child.layout(c, parentUsesSize: true);
      return child.size;
    });
    size = r.size;
    (_start?.parentData as BoxParentData?)?.offset = r.startAt;
    (_end?.parentData as BoxParentData?)?.offset = r.endAt;
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _start?.getMinIntrinsicWidth(height) ?? 0,
    _end?.getMinIntrinsicWidth(height) ?? 0,
  );

  @override
  double computeMaxIntrinsicWidth(double height) {
    final s = _start?.getMaxIntrinsicWidth(height) ?? 0;
    final e = _end?.getMaxIntrinsicWidth(height) ?? 0;
    return s > 0 && e > 0 ? s + _gap + e : s + e;
  }

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    _start?.getMinIntrinsicHeight(width) ?? 0,
    _end?.getMinIntrinsicHeight(width) ?? 0,
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    _start?.getMaxIntrinsicHeight(width) ?? 0,
    _end?.getMaxIntrinsicHeight(width) ?? 0,
  );

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(
        child,
        (child.parentData as BoxParentData).offset + offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children.toList().reversed) {
      final data = child.parentData as BoxParentData;
      final hit = result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
