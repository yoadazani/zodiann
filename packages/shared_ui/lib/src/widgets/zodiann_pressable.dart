import 'package:flutter/rendering.dart' show BoxParentData, RenderShiftedBox;
import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_surfaces.dart';

/// The interaction layer every Zodiann control shares (MASTER.md §10,
/// ZOD-UI-004), extracted unchanged from `ZodiannButton` in ZOD-NAV-001 so
/// `ZodiannIconButton` behaves exactly the same:
///
/// - hover lightens [child] by 12 % (`brightness(1.12)`), eased over 150 ms
///   and instant under reduced motion; pressed moves it 1 px down and
///   darkens it 6 %;
/// - a 2 px `focus` ring at offset 2, shown for keyboard focus only;
/// - disabled ([onPressed] null): 42 % opacity ([disabledOpacity] overrides),
///   not focusable, inert, `forbidden` cursor;
/// - activation by tap (including the hit margins), Enter, Space or a screen
///   reader; one semantics node labelled [semanticLabel];
/// - a layout and hit box of at least 44 × 44 with [child] centred.
///
/// [child] is the drawn control (its box, fill, border and content).
class ZodiannPressable extends StatefulWidget {
  const ZodiannPressable({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    required this.child,
    this.focusNode,
    this.autofocus = false,
    this.selected = false,
    this.semanticHint,
    this.inMutuallyExclusiveGroup = false,
    this.disabledOpacity,
    this.focusRing = true,
    this.toggled,
    this.checked,
    this.slotAlignment = Alignment.center,
    this.focusRingRadius = ZodiannRadius.md,
  });

  /// Called on activation. Null disables the control.
  final VoidCallback? onPressed;

  /// The control's accessible name.
  final String semanticLabel;

  /// Whether the control is the selected one of its set (the drawer's active
  /// item). When false the node carries no selected state at all, as before
  /// (in Flutter "not selected" is a state of its own).
  final bool selected;

  /// Whether the control is one of a mutually exclusive set (a segmented
  /// control). When false the node carries no group flag, as before.
  final bool inMutuallyExclusiveGroup;

  /// The opacity while disabled; null is [ZodiannStates.disabledOpacity]
  /// (42 %). A planned segmented-control option passes 40 %.
  final double? disabledOpacity;

  /// Whether to paint the keyboard focus ring itself. A parent that must draw
  /// it above neighbouring controls (the segmented control) turns this off.
  final bool focusRing;

  /// The on / off state of a switch; null (the default) adds no toggle state
  /// to the node.
  final bool? toggled;

  /// The checked state of a checkbox-like control (a body chip); null (the
  /// default) adds no check state to the node.
  final bool? checked;

  /// Where the drawn [child] sits inside the 44 x 44 slot (centre by default).
  /// A control whose drawn box must sit against one edge of its parent (an
  /// orb stepper button) aligns its child to that edge.
  final AlignmentGeometry slotAlignment;

  /// The corner radius of the keyboard focus ring around [child] (8 by
  /// default; a switch or a pill chip passes its own).
  final double focusRingRadius;

  /// An optional accessible hint (the drawer item's description).
  final String? semanticHint;

  /// The drawn control.
  final Widget child;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  State<ZodiannPressable> createState() => _ZodiannPressableState();
}

class _ZodiannPressableState extends State<ZodiannPressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focusHighlight = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void didUpdateWidget(ZodiannPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _pressed = false;
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<ZodiannSurfaces>()!;
    final enabled = _enabled;
    final onPressed = widget.onPressed;

    // The filter stays in the tree (identity at 1) so the subtree's shape
    // never changes. Hover eases over 150 ms (instant under reduced
    // motion, MASTER §12); press is instant.
    final filtered = TweenAnimationBuilder<double>(
      tween: Tween<double>(
        end: enabled && _hovered ? ZodiannStates.hoverBrightness : 1.0,
      ),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : ZodiannStates.hoverDuration,
      curve: Curves.ease,
      builder: (context, hover, child) => ColorFiltered(
        colorFilter: _brightness(
          _pressed ? ZodiannStates.pressedBrightness : hover,
        ),
        child: child,
      ),
      child: widget.child,
    );

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      selected: widget.selected ? true : null,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup ? true : null,
      toggled: widget.toggled,
      checked: widget.checked,
      onTap: onPressed,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onShowFocusHighlight: (value) {
          if (_focusHighlight != value) {
            setState(() => _focusHighlight = value);
          }
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onPressed?.call();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            onTap: onPressed,
            child: _TouchTarget(
              alignment: widget.slotAlignment,
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: enabled
                      ? 1.0
                      : widget.disabledOpacity ?? ZodiannStates.disabledOpacity,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      _pressed ? ZodiannStates.pressedOffset : 0,
                    ),
                    child: CustomPaint(
                      foregroundPainter: ZodiannFocusRingPainter(
                        show: _focusHighlight && widget.focusRing,
                        color: s.focus,
                        radius: widget.focusRingRadius,
                      ),
                      child: filtered,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The control's layout and hit box (UI-004 D3): at least 44 × 44, with the
/// drawn box placed inside it by [ZodiannPressable.slotAlignment] (centred by
/// default).
///
/// The drawn box keeps its own height (loose), but takes the incoming width
/// constraint as is: in a tight-width slot (full-width controls, MASTER §6)
/// it stretches to the slot, otherwise it is content-wide, and narrower than
/// 44 only for very short content.
class _TouchTarget extends SingleChildRenderObjectWidget {
  const _TouchTarget({required super.child, required this.alignment});

  final AlignmentGeometry alignment;

  @override
  _RenderTouchTarget createRenderObject(BuildContext context) =>
      _RenderTouchTarget(alignment, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTouchTarget renderObject,
  ) {
    renderObject
      ..alignment = alignment
      ..textDirection = Directionality.of(context);
  }
}

class _RenderTouchTarget extends RenderShiftedBox {
  _RenderTouchTarget(this._alignment, this._textDirection) : super(null);

  AlignmentGeometry _alignment;
  TextDirection _textDirection;

  set alignment(AlignmentGeometry value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  static const double _min = ZodiannSize.minTouchTarget;

  BoxConstraints _childConstraints(BoxConstraints c) => BoxConstraints(
    minWidth: c.minWidth,
    maxWidth: c.maxWidth,
  ).copyWith(maxHeight: c.maxHeight);

  Size _sizeFor(BoxConstraints c, Size child) => c.constrain(
    Size(
      child.width < _min ? _min : child.width,
      child.height < _min ? _min : child.height,
    ),
  );

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.constrain(const Size(_min, _min));
    return _sizeFor(
      constraints,
      child.getDryLayout(_childConstraints(constraints)),
    );
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = _sizeFor(constraints, child.size);
    (child.parentData! as BoxParentData).offset = _alignment
        .resolve(_textDirection)
        .alongOffset((size - child.size) as Offset);
  }

  double _atLeastMin(double v) => v < _min ? _min : v;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _atLeastMin(child?.getMinIntrinsicWidth(height) ?? 0);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _atLeastMin(child?.getMaxIntrinsicWidth(height) ?? 0);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _atLeastMin(child?.getMinIntrinsicHeight(width) ?? 0);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _atLeastMin(child?.getMaxIntrinsicHeight(width) ?? 0);
}

/// A CSS `brightness(k)` filter: RGB scaled by [k], alpha unchanged.
ColorFilter _brightness(double k) => ColorFilter.matrix(<double>[
  k, 0, 0, 0, 0, //
  0, k, 0, 0, 0, //
  0, 0, k, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Paints the keyboard focus ring outside its child's bounds: a 2 px
/// [color] ring at a 2 px gap, following the corner [radius] (8 px unless a
/// control passes its own).
@visibleForTesting
final class ZodiannFocusRingPainter extends CustomPainter {
  /// A ring in [color], painted only when [show].
  const ZodiannFocusRingPainter({
    required this.show,
    required this.color,
    this.radius = ZodiannRadius.md,
  });

  /// Whether the ring is visible (keyboard focus highlight only).
  final bool show;

  /// The `focus` token.
  final Color color;

  /// The corner radius of the ring's inner edge.
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    final outset =
        ZodiannStates.focusRingGap + ZodiannStates.focusRingWidth / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).inflate(outset),
        Radius.circular(radius + outset),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ZodiannStates.focusRingWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(ZodiannFocusRingPainter oldDelegate) =>
      oldDelegate.show != show ||
      oldDelegate.color != color ||
      oldDelegate.radius != radius;
}
