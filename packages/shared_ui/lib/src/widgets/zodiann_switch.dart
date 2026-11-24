import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_surfaces.dart';
import 'zodiann_pressable.dart';

/// A switch (MASTER.md §10 "Others"; kit.css `.switch`): a 40 × 24 pill track
/// with a 16 px thumb, 4 px from the track's outer edge on the start side when
/// off and on the end side when on.
///
/// Off: `surface-3` fill, `line` border, `text-3` thumb. On: `accent` fill and
/// border, `on-accent` thumb. The thumb and colours move over 120 ms
/// (MASTER §12 "selection changes"; linear), instantly under reduced motion.
/// The thumb follows the reading direction: it starts on the right in Hebrew.
///
/// The control has no text; [semanticLabel] names it for a screen reader, and
/// the node carries the toggled state. It sits in `ZodiannPressable`'s 44 × 44
/// slot (hover, press, keyboard focus ring with the track's 12 px corner,
/// Enter / Space / tap). [onChanged] null disables it (42 % opacity, inert).
class ZodiannSwitch extends StatelessWidget {
  /// A switch showing [value].
  const ZodiannSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the new state; null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// The accessible name, localized by the caller.
  final String semanticLabel;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<ZodiannSurfaces>()!;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ZodiannStates.selectionDuration;
    final callback = onChanged;
    final accent = value ? s.accent : s.surface3;
    final border = value ? s.accent : s.line;

    return ZodiannPressable(
      onPressed: callback == null ? null : () => callback(!value),
      semanticLabel: semanticLabel,
      toggled: value,
      focusRingRadius: ZodiannRadius.lg,
      focusNode: focusNode,
      autofocus: autofocus,
      child: AnimatedContainer(
        key: const ValueKey('zodiann-switch-track'),
        duration: duration,
        curve: Curves.linear,
        width: ZodiannSize.switchWidth,
        height: ZodiannSize.switchHeight,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(ZodiannRadius.lg),
          border: Border.all(color: border, width: ZodiannSize.hairline),
        ),
        // The decoration's border is inside the box, so this stack starts at
        // the border's inner edge, as the kit's absolutely positioned thumb.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositionedDirectional(
              duration: duration,
              curve: Curves.linear,
              top: ZodiannSize.switchThumbInset,
              start: value
                  ? ZodiannSize.switchWidth -
                        2 * ZodiannSize.hairline -
                        ZodiannSize.switchThumbInset -
                        ZodiannSize.switchThumb
                  : ZodiannSize.switchThumbInset,
              width: ZodiannSize.switchThumb,
              height: ZodiannSize.switchThumb,
              child: AnimatedContainer(
                key: const ValueKey('zodiann-switch-thumb'),
                duration: duration,
                curve: Curves.linear,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? s.onAccent : s.text3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
