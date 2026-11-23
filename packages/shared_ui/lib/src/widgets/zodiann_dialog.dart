import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/zodiann_elevation.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';

/// A regular button's layout box is 44 high around its 40 high drawn box: 2 px
/// of invisible margin that the kit's `.actions` (a flex row of 40 high
/// buttons) does not have. The dialog takes it out of the gap above the
/// actions and out of the bottom padding, so the drawn buttons sit exactly
/// where the reference has them (ZOD-UI-004's note on tap targets).
const double _tapMargin =
    (ZodiannSize.minTouchTarget - ZodiannSize.control) / 2;

/// The dialog box (MASTER.md §10 "Dialog", kit.css `.dialog`): a `surface`
/// card 420 wide (never wider than what it is given), 16 radius, 24 padding,
/// on the floating-layer shadow with its 1 px outline outside the box.
///
/// A [title] (20 / 600), an optional [message] (`text-2`), an optional free
/// [content] (a text field, say) and the [actions], buttons aligned to the
/// **end** edge, 8 apart, wrapping when they do not fit. The caller localizes
/// every string and builds the buttons.
///
/// Show it with `showZodiannDialog`, whose route centres it, scrolls it when
/// it does not fit and keeps it above the keyboard. The box names the route
/// for assistive technology (its [title]) and marks the title as a header; a
/// builder that returns anything else gets no route name.
///
/// Do not clip it: the buttons' keyboard focus ring reaches 4 px beyond their
/// box, inside the 24 px padding.
class ZodiannDialog extends StatelessWidget {
  /// A dialog titled [title] with [actions].
  ZodiannDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.actions,
  }) : assert(actions.isNotEmpty, 'a dialog needs at least one action');

  /// The title, sentence case, localized by the caller.
  final String title;

  /// A line or paragraph under the title, in `text-2`.
  final String? message;

  /// Any widget between the message and the actions.
  final Widget? content;

  /// The buttons, first nearest the start edge, aligned to the end edge.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final elevation = theme.extension<ZodiannElevation>()!;
    final outline = elevation.floatingOutline;

    // kit.css: the title's 8 margin collapses into the actions' 24 when
    // nothing sits between them.
    final afterTitle = message != null || content != null
        ? ZodiannSpace.s2
        : ZodiannSpace.s6 - _tapMargin;
    return Semantics(
      namesRoute: true,
      label: title,
      explicitChildNodes: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ZodiannSize.dialogWidth),
        // Infinite width clamps to the incoming maximum: the box fills what
        // it is given, up to 420.
        child: SizedBox(
          width: double.infinity,
          // Two layers, so the paint order does not depend on how a shadow
          // list is ordered: the outline ring outside the box underneath (a
          // BorderSide would sit inside), then the box with the floating
          // shadow over the ring. The kit's `box-shadow: <float>, 0 0 0 1px
          // var(--line)` paints the first shadow on top, so the ring darkens
          // under the shadow (measured in ZOD-UI-013: 242429 above the box,
          // 161619 below it).
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: ZodiannRadius.dialog,
              boxShadow: [
                BoxShadow(color: outline.color, spreadRadius: outline.width),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: ZodiannRadius.dialog,
                boxShadow: elevation.floating,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ZodiannSpace.s6,
                  ZodiannSpace.s6,
                  ZodiannSpace.s6,
                  ZodiannSpace.s6 - _tapMargin,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: styles.dialogTitle.copyWith(color: s.text),
                      ),
                    ),
                    SizedBox(height: afterTitle),
                    if (message != null)
                      Text(
                        message!,
                        style: styles.body.copyWith(color: s.text2),
                      ),
                    if (content != null) ...[
                      if (message != null)
                        const SizedBox(height: ZodiannSpace.s4),
                      content!,
                      const SizedBox(height: ZodiannSpace.s6 - _tapMargin),
                    ] else if (message != null)
                      const SizedBox(height: ZodiannSpace.s6 - _tapMargin),
                    Wrap(
                      alignment: WrapAlignment.end,
                      runAlignment: WrapAlignment.end,
                      spacing: ZodiannSpace.s2,
                      runSpacing: ZodiannSpace.s2,
                      textDirection: Directionality.of(context),
                      children: actions,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
