import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';
import 'zodiann_button_colors.dart';
import 'zodiann_pressable.dart';

export 'zodiann_pressable.dart' show ZodiannFocusRingPainter;

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
class ZodiannButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final colors = ZodiannButtonColors.resolve(s, variant);
    final small = size == ZodiannButtonSize.small;

    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: (small ? styles.small : styles.body).copyWith(
        color: colors.label,
        fontWeight: variant == ZodiannButtonVariant.primary
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
          if (icon case final icon?)
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
          Flexible(child: text),
        ],
      ),
    );

    return ZodiannPressable(
      onPressed: onPressed,
      semanticLabel: label,
      focusNode: focusNode,
      autofocus: autofocus,
      child: drawn,
    );
  }
}
