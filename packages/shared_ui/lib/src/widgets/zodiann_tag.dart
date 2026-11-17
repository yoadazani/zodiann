import 'package:material_ui/material_ui.dart';

import '../theme/square_colors.dart';
import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';
import 'zodiann_tag_style.dart';

/// A static tag (MASTER.md §10 "Tags"; kit.css `.tag`): 24 high, 6 radius,
/// 8 start and end padding, 12 / 600 text (neutral 500).
///
/// [label] is a localized string from the caller. The `+` / `×` mark of the
/// axis and diagonal variants is bound to [variant] ([ZodiannTagVariant.mark]),
/// so a highlight is never conveyed by colour alone (NFR-X4).
///
/// The tag grows with the text scale (its 24 is a minimum) and ellipsizes its
/// label in a narrow parent; the mark keeps its full width.
class ZodiannTag extends StatelessWidget {
  /// A tag of [variant] showing [label].
  const ZodiannTag({super.key, required this.variant, required this.label});

  /// Which tag.
  final ZodiannTagVariant variant;

  /// The localized text.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = ZodiannTagStyle.of(
      variant,
      theme.extension<SquareColors>()!,
      theme.extension<ZodiannSurfaces>()!,
    );
    final styles = theme.extension<ZodiannTextStyles>()!;
    final mark = variant.mark;
    final outline = style.outline;

    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ZodiannSize.tag),
        // A DecoratedBox, not a Container: kit's outline is an inset shadow
        // that leaves the content where it is.
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.fill,
            borderRadius: ZodiannRadius.tag,
            border: outline == null
                ? null
                : Border.all(
                    color: outline,
                    width: ZodiannSize.tagOutline,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ZodiannSpace.s2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (mark != null) ...[
                  Text(
                    mark,
                    style: styles.small.copyWith(
                      fontWeight: FontWeight.w500,
                      color: style.ink.withValues(
                        alpha: ZodiannStates.tagMarkOpacity,
                      ),
                    ),
                  ),
                  const SizedBox(width: ZodiannSize.tagGap),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: styles.label.copyWith(
                      fontWeight: style.weight,
                      color: style.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
