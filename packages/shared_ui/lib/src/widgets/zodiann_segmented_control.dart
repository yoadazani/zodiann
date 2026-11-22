import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../icons/zodiann_icon.dart';
import '../icons/zodiann_icon_data.dart';
import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_layout.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';
import 'zodiann_pressable.dart';

/// One option of a [ZodiannSegmentedControl].
final class ZodiannSegment<T> {
  /// An option with its [value] and localized [label].
  const ZodiannSegment({
    required this.value,
    required this.label,
    this.icon,
    this.planned = false,
  });

  /// What [ZodiannSegmentedControl.onChanged] reports.
  final T value;

  /// The localized text, including any "(planned)" wording.
  final String label;

  /// An optional 16 px icon before the label.
  final ZodiannIconData? icon;

  /// A planned-but-unavailable option: 40 % opacity, not focusable, not
  /// selectable by tap, mouse, keyboard or screen reader (MASTER §10, D19).
  final bool planned;
}

/// The segmented control (MASTER.md §10; kit.css `.seg`): a `bg-raised`
/// track with a 3 px inset and a `surface-3` thumb, with an inset 1 px
/// `accent-line` ring, on the selected segment.
///
/// - **Size:** the drawn track is 40 high (3 inset + 32 thumb + 3, inside a
///   1 px border) in a 44 high layout box, so each segment's hit slot is 44
///   high (MASTER §14), like a 40 px button. Thumbs grow beyond 32 with the
///   text scale.
/// - **Stretch:** on a phone ([expand] null) the control fills its row with
///   equal segments (MASTER §6); above phone width it is content-wide. In a
///   narrower parent labels ellipsize on one line. With an unbounded width it
///   falls back to content width.
/// - **Selection:** tap, mouse, Enter or Space on an enabled, unselected
///   segment calls [onChanged]. Each enabled segment is a tab stop; Left and
///   Right (what is on screen, so mirrored in RTL) move focus to the
///   neighbouring enabled segment without selecting, and stop at the ends.
/// - **Selected look:** the label is `text`; the icon is `accent-strong`
///   (kit.css and the component sheet; MASTER §10 says `text`).
/// - **Motion:** fill, ring and ink crossfade linearly over 120 ms, instantly
///   under reduced motion.
///
/// The focus ring of a segment paints 4 px beyond its thumb, over the
/// track; the control never clips. Not for intrinsic measurement (it reads
/// its constraints).
class ZodiannSegmentedControl<T> extends StatefulWidget {
  /// A control over [segments] showing [value] as selected.
  ZodiannSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.expand,
    this.semanticLabel,
  }) : assert(segments.isNotEmpty, 'a segmented control needs a segment'),
       assert(
         segments.map((s) => s.value).toSet().length == segments.length,
         'segment values must be unique',
       ),
       assert(
         segments.any((s) => s.value == value && !s.planned),
         'value must name an existing, non-planned segment',
       );

  /// The options, in logical order.
  final List<ZodiannSegment<T>> segments;

  /// The selected segment's value.
  final T value;

  /// Called with the value of a newly chosen segment. Null disables the whole
  /// control.
  final ValueChanged<T>? onChanged;

  /// Whether to fill the available width with equal segments. Null is
  /// automatic: true on a phone, false above.
  final bool? expand;

  /// Names the group for screen readers.
  final String? semanticLabel;

  @override
  State<ZodiannSegmentedControl<T>> createState() =>
      _ZodiannSegmentedControlState<T>();
}

class _ZodiannSegmentedControlState<T>
    extends State<ZodiannSegmentedControl<T>> {
  // One node per enabled segment, keyed by value; stale ones are disposed
  // after the frame, never while the old detector still holds them.
  final Map<T, FocusNode> _nodes = {};

  bool get _interactive => widget.onChanged != null;

  FocusNode? _nodeFor(ZodiannSegment<T> segment) {
    if (!_interactive || segment.planned) return null;
    return _nodes.putIfAbsent(
      segment.value,
      () => FocusNode(debugLabel: 'segment ${segment.label}'),
    );
  }

  void _pruneAfterFrame() {
    final live = {
      for (final s in widget.segments)
        if (_interactive && !s.planned) s.value,
    };
    final stale = [
      for (final key in _nodes.keys)
        if (!live.contains(key)) key,
    ];
    if (stale.isEmpty) return;
    final nodes = [for (final key in stale) _nodes.remove(key)!];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final node in nodes) {
        node.dispose();
      }
    });
  }

  @override
  void didUpdateWidget(ZodiannSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pruneAfterFrame();
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  List<FocusNode> _enabledNodesInOrder() => [
    for (final s in widget.segments)
      if (_nodes[s.value] != null) _nodes[s.value]!,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final expand =
        widget.expand ?? ZodiannLayout.of(context) == ZodiannLayout.phone;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ZodiannStates.selectionDuration;
    final labelStyle = styles.small.copyWith(fontWeight: FontWeight.w500);
    final scaler = MediaQuery.textScalerOf(context);

    double textWidth(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    // The thumb is 32 high, taller once the text scale needs it. One height
    // for every segment keeps the track hugging them.
    final linePainter = TextPainter(
      text: TextSpan(text: 'Ag', style: labelStyle),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout();
    final thumbHeight = math.max(
      ZodiannSize.segmentThumb,
      linePainter.height + 2 * ZodiannSize.hairline,
    );
    linePainter.dispose();
    const ring = ZodiannSize.hairline;
    const frame = ZodiannSize.segmentTrackInset + ring;
    final trackHeight = thumbHeight + 2 * frame;
    final layoutHeight = math.max(ZodiannSize.minTouchTarget, trackHeight);
    final trackInset = (layoutHeight - trackHeight) / 2;

    Widget segment(ZodiannSegment<T> segment, bool stretch) {
      final selected = segment.value == widget.value;
      final unselectedFill = s.surface3.withAlpha(0);
      final unselectedRing = s.accentLine.withAlpha(0);
      final ink = selected ? s.text : s.text2;
      final iconInk = selected ? s.accentStrong : s.text2;
      final onChanged = widget.onChanged;
      final enabled = onChanged != null && !segment.planned;
      final thumb = AnimatedContainer(
        duration: duration,
        curve: Curves.linear,
        height: thumbHeight,
        // The 1 px ring is part of the box, so the padding is the sheet's
        // 12 less that pixel and the content box never moves.
        padding: const EdgeInsets.symmetric(
          horizontal: ZodiannSpace.s3 - ZodiannSize.hairline,
        ),
        decoration: BoxDecoration(
          color: selected ? s.surface3 : unselectedFill,
          borderRadius: ZodiannRadius.segmentThumb,
          border: Border.all(
            color: selected ? s.accentLine : unselectedRing,
            width: ring,
          ),
        ),
        child: Center(
          widthFactor: stretch ? null : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: ZodiannSize.segmentIconGap,
            children: [
              if (segment.icon != null)
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: iconInk),
                  duration: duration,
                  curve: Curves.linear,
                  builder: (context, color, _) => ZodiannIcon(
                    segment.icon!,
                    size: ZodiannSize.iconSmall,
                    color: color,
                  ),
                ),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  style: labelStyle.copyWith(color: ink),
                  duration: duration,
                  curve: Curves.linear,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  child: Text(segment.label),
                ),
              ),
            ],
          ),
        ),
      );
      return ZodiannPressable(
        onPressed: !enabled
            ? null
            : selected
            ? () {}
            : () => onChanged(segment.value),
        semanticLabel: segment.label,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        disabledOpacity: segment.planned ? ZodiannStates.plannedOpacity : null,
        focusNode: _nodeFor(segment),
        child: thumb,
      );
    }

    double natural(ZodiannSegment<T> segment) =>
        2 * ZodiannSpace.s3 +
        (segment.icon == null
            ? 0
            : ZodiannSize.iconSmall + ZodiannSize.segmentIconGap) +
        textWidth(segment.label);

    Widget row(bool bounded) => Row(
      mainAxisSize: expand && bounded ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: ZodiannSize.segmentGap,
      children: [
        for (final item in widget.segments)
          if (!bounded)
            segment(item, false)
          else if (expand)
            Expanded(child: segment(item, true))
          else
            // Natural widths when they fit, shrinking in proportion when the
            // parent is narrower.
            Flexible(flex: natural(item).ceil(), child: segment(item, false)),
      ],
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: Actions(
        actions: {
          DirectionalFocusIntent: _SideAction(
            nodes: _enabledNodesInOrder,
            rtl: rtl,
            outer: context,
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: layoutHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  top: trackInset,
                  bottom: trackInset,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: s.bgRaised,
                      borderRadius: ZodiannRadius.control,
                      border: Border.all(color: s.lineSoft, width: ring),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: frame),
                  child: row(constraints.hasBoundedWidth),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Left and Right move focus to the neighbouring enabled segment and stop at
/// the ends. Up and Down are handed to the next enclosing handler (the
/// default focus traversal, or an outer `Actions`): in Flutter 3.50 the
/// nearest action of a type answers a key even when it reports itself
/// disabled, so this action cannot simply decline them.
class _SideAction extends Action<DirectionalFocusIntent> {
  _SideAction({required this.nodes, required this.rtl, required this.outer});

  final List<FocusNode> Function() nodes;
  final bool rtl;

  /// A context above this control's `Actions`, to find the outer handler.
  final BuildContext outer;

  @override
  Object? invoke(DirectionalFocusIntent intent) {
    final direction = intent.direction;
    if (direction != TraversalDirection.left &&
        direction != TraversalDirection.right) {
      final next = Actions.maybeFind<DirectionalFocusIntent>(
        outer,
        intent: intent,
      );
      if (next == null) return null;
      return Actions.of(outer).invokeActionIfEnabled(next, intent).$2;
    }
    final list = nodes();
    final at = list.indexWhere((n) => n.hasPrimaryFocus);
    if (at < 0) return null;
    // On screen, left is the previous segment in LTR and the next in RTL.
    final towardStart = (direction == TraversalDirection.left) != rtl;
    final to = at + (towardStart ? -1 : 1);
    if (to >= 0 && to < list.length) list[to].requestFocus();
    return null;
  }
}
