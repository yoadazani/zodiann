import 'package:flutter/rendering.dart' show BoxParentData, RenderShiftedBox;
import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';
import 'zodiann_button_colors.dart';

/// Button heights (MASTER.md §4): 40, or 32 for the small variant.
enum ZodiannButtonSize {
  /// 40 high, 16 px inline padding, 14 px label.
  regular,

  /// 32 high, 12 px inline padding, 13 px label.
  small,
}

/// A Zodiann button (MASTER.md §10, ZOD-UI-004): five variants
/// ([ZodiannButtonVariant]), two sizes, and the states default, hover
/// (+12 %, animated over 150 ms), keyboard focus (2 px `focus` ring at
/// offset 2), pressed (1 px down, −6 %) and disabled (42 % opacity,
/// [onPressed] null).
///
/// - **At most one primary per screen region** (a usage convention).
/// - **Touch target (D3):** the button is drawn 40 / 32 high at its content
///   width, inside a layout and hit box of at least 44 × 44 (MASTER §14).
///   The transparent margins also take taps. Stack buttons 8 apart
///   vertically for the design's 12 px visual gap.
/// - **Focus-ring contract:** the button paints the complete focus ring,
///   4 px beyond its drawn box, whenever no ancestor clips it; it cannot
///   override an ancestor's clip. Keep at least 4 px of clear, unclipped
///   space around the button wherever the ring can appear. A layout that
///   must clip adjusts its own padding so keyboard focus stays visible.
class ZodiannButton extends StatefulWidget {
  /// A button labelled [label]; disabled when [onPressed] is null.
  const ZodiannButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ZodiannButtonVariant.secondary,
    this.size = ZodiannButtonSize.regular,
    this.icon,
    this.focusNode,
    this.autofocus = false,
  });

  /// The label, in sentence case; shown on one line, ellipsized if needed.
  final String label;

  /// Called on tap, Enter, Space or a screen-reader activation. Null
  /// disables the button.
  final VoidCallback? onPressed;

  /// The visual variant.
  final ZodiannButtonVariant variant;

  /// The height variant.
  final ZodiannButtonSize size;

  /// An optional leading icon, laid out in a 16 × 16 slot on the start side
  /// (8 px before the label) and tinted with the label colour.
  final Widget? icon;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  State<ZodiannButton> createState() => _ZodiannButtonState();
}

class _ZodiannButtonState extends State<ZodiannButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focusHighlight = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void didUpdateWidget(ZodiannButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _pressed = false;
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final colors = ZodiannButtonColors.resolve(s, widget.variant);
    final small = widget.size == ZodiannButtonSize.small;
    final enabled = _enabled;
    final onPressed = widget.onPressed;

    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: (small ? styles.small : styles.body).copyWith(
        color: colors.label,
        fontWeight: widget.variant == ZodiannButtonVariant.primary
            ? FontWeight.w600
            : FontWeight.w500,
      ),
    );

    // Border-box, as in CSS: Container adds the 1 px border to the padding,
    // so the content sits 17 (13 small) in from the outer edge. The min
    // height reaches the Row, which centres its children vertically.
    final drawn = Container(
      constraints: BoxConstraints(
        minHeight: small ? ZodiannSize.controlSmall : ZodiannSize.control,
      ),
      decoration: BoxDecoration(
        color: colors.fill,
        border: Border.all(color: colors.border),
        borderRadius: ZodiannRadius.control,
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: small ? ZodiannSpace.s3 : ZodiannSpace.s4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // A stretched (tight-width) box centres its content, as CSS's
        // `justify-content: center`.
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: ZodiannSpace.s2,
        children: [
          if (widget.icon case final icon?)
            IconTheme(
              data: IconThemeData(
                color: colors.label,
                size: ZodiannSize.iconSmall,
              ),
              child: SizedBox.square(
                dimension: ZodiannSize.iconSmall,
                child: icon,
              ),
            ),
          Flexible(child: label),
        ],
      ),
    );

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
      child: drawn,
    );

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.label,
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
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: enabled ? 1.0 : ZodiannStates.disabledOpacity,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      _pressed ? ZodiannStates.pressedOffset : 0,
                    ),
                    child: CustomPaint(
                      foregroundPainter: ZodiannFocusRingPainter(
                        show: _focusHighlight,
                        color: s.focus,
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

/// The button's layout and hit box (D3): at least 44 × 44, with the drawn
/// box centred inside it.
///
/// The drawn box keeps its own height (40 / 32, loose), but takes the
/// incoming width constraint as is: in a tight-width slot (full-width
/// controls, MASTER §6) it stretches to the slot, otherwise it is
/// content-wide, and narrower than 44 only for very short labels.
class _TouchTarget extends SingleChildRenderObjectWidget {
  const _TouchTarget({required super.child});

  @override
  _RenderTouchTarget createRenderObject(BuildContext context) =>
      _RenderTouchTarget();
}

class _RenderTouchTarget extends RenderShiftedBox {
  _RenderTouchTarget() : super(null);

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
    (child.parentData! as BoxParentData).offset = Offset(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
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
/// [color] ring at a 2 px gap, following the 8 px corner radius.
@visibleForTesting
final class ZodiannFocusRingPainter extends CustomPainter {
  /// A ring in [color], painted only when [show].
  const ZodiannFocusRingPainter({required this.show, required this.color});

  /// Whether the ring is visible (keyboard focus highlight only).
  final bool show;

  /// The `focus` token.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    final outset =
        ZodiannStates.focusRingGap + ZodiannStates.focusRingWidth / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).inflate(outset),
        Radius.circular(ZodiannRadius.md + outset),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ZodiannStates.focusRingWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(ZodiannFocusRingPainter oldDelegate) =>
      oldDelegate.show != show || oldDelegate.color != color;
}
