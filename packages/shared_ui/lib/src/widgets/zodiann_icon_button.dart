import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/zodiann_surfaces.dart';
import 'zodiann_pressable.dart';

/// The two icon-button styles (kit.css `.icon-btn`, `.icon-btn.boxed`).
enum ZodiannIconButtonVariant {
  /// No fill and no border: the hamburger and the drawer's close button.
  plain,

  /// A `surface` fill with a 1 px `line` border: the wheel's steppers.
  boxed,
}

/// A 46 × 46 icon-only button (MASTER §4 "hamburger and icon buttons",
/// NAV-1; ZOD-NAV-001).
///
/// It behaves exactly as `ZodiannButton` does (UI-004 hover, press, keyboard
/// focus ring, disabled at 42 % when [onPressed] is null) through the shared
/// `ZodiannPressable`. The [icon] is drawn 20 px in the theme's `text`
/// colour; pass a `ZodiannIcon`, or `iconBack()` / `iconFwd()` for
/// direction-following chevrons. [semanticLabel] is its accessible name.
///
/// Keep at least 4 px of unclipped space around it for the focus ring (see
/// `ZodiannButton`'s focus-ring contract).
class ZodiannIconButton extends StatelessWidget {
  const ZodiannIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = ZodiannIconButtonVariant.plain,
    this.focusNode,
    this.autofocus = false,
  });

  /// The icon, usually a `ZodiannIcon`.
  final Widget icon;

  /// The accessible name (the button has no visible label).
  final String semanticLabel;

  /// Called on activation. Null disables the button.
  final VoidCallback? onPressed;

  /// Plain or boxed.
  final ZodiannIconButtonVariant variant;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<ZodiannSurfaces>()!;
    final boxed = variant == ZodiannIconButtonVariant.boxed;
    return ZodiannPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      child: SizedBox.square(
        dimension: ZodiannSize.iconButton,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: boxed ? s.surface : null,
            border: boxed ? Border.all(color: s.line) : null,
            borderRadius: ZodiannRadius.control,
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(size: ZodiannSize.icon, color: s.text),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
