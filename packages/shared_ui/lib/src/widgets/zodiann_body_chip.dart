import 'package:astro_core/astro_core.dart' show Body;
import 'package:material_ui/material_ui.dart';

import '../theme/body_colors.dart';
import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_glyphs.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';
import 'zodiann_pressable.dart';

/// A toggleable body chip (MASTER.md §10 "Others"; kit.css `.chk`), used for
/// "Visible bodies": a 34 high pill with a 1 px border, a 15 px body glyph in
/// the body's colour, then the body's name in 13 px `text`.
///
/// Off: no fill, `line` border. On: `accent-soft` fill and `accent-line`
/// border, crossfaded over 120 ms (linear; instant under reduced motion).
/// There is no check mark (the component sheet shows none; owner decision
/// 2026-11-24): the on state is carried by the fill and border (a change of
/// lightness, not hue), the node's `checked` state for a screen reader and
/// the keyboard focus ring (pill-shaped). Those differences are small by
/// design (border on vs off about 1.5 to 1 in contrast); ZOD-NFR-008 audits
/// colour independence.
///
/// The chip sits in `ZodiannPressable`'s 44 high slot (hover, press, Enter /
/// Space / tap). [onChanged] receives the new state; null disables it (42 %
/// opacity, inert). The glyph is decorative (`ExcludeSemantics`); [label] is
/// what a screen reader reads. In a narrow parent the label ellipsizes on one
/// line.
class ZodiannBodyChip extends StatelessWidget {
  /// A chip for [body] reading [label].
  const ZodiannBodyChip({
    super.key,
    required this.body,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.focusNode,
  });

  /// The body whose glyph and colour the chip shows.
  final Body body;

  /// The body's localized name.
  final String label;

  /// Whether the body is shown (the chip is on).
  final bool selected;

  /// Called with the new state; null disables the chip.
  final ValueChanged<bool>? onChanged;

  /// An optional focus node.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final colors = theme.extension<BodyColors>()!;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ZodiannStates.selectionDuration;
    final callback = onChanged;

    return ZodiannPressable(
      onPressed: callback == null ? null : () => callback(!selected),
      semanticLabel: label,
      checked: selected,
      focusRingRadius: ZodiannRadius.pill,
      focusNode: focusNode,
      child: AnimatedContainer(
        key: const ValueKey('zodiann-chip-box'),
        duration: duration,
        curve: Curves.linear,
        constraints: const BoxConstraints(
          minHeight: ZodiannSize.bodyChipHeight,
        ),
        // The container adds the 1 px border to this padding, so the glyph
        // sits 1 + 10 inside the outer edge and the label ends 1 + 12 before
        // it, as in the kit (border-box with padding inside the border).
        padding: const EdgeInsetsDirectional.only(
          start: ZodiannSize.bodyChipPaddingStart,
          end: ZodiannSize.bodyChipPaddingEnd,
        ),
        // Off is the same colour at alpha 0, never `Colors.transparent`
        // (which would fade through black).
        decoration: BoxDecoration(
          color: selected ? s.accentSoft : s.accentSoft.withAlpha(0),
          borderRadius: ZodiannRadius.chip,
          border: Border.all(
            color: selected ? s.accentLine : s.line,
            width: ZodiannSize.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Text(
                ZodiannGlyphs.body(body),
                key: const ValueKey('zodiann-chip-glyph'),
                style: styles.glyph.copyWith(
                  fontSize: ZodiannSize.bodyChipGlyph,
                  color: colors.of(body),
                ),
              ),
            ),
            const SizedBox(width: ZodiannSize.bodyChipGap),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: styles.small.copyWith(color: s.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
