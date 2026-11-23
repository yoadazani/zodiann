import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/zodiann_surfaces.dart';

/// Shows a modal dialog (ZOD-UI-013): [builder] returns the box, normally a
/// `ZodiannDialog`, whose buttons close it with
/// `Navigator.of(context).pop(value)`.
///
/// It is pushed on the **root** navigator, so the scrim (`ZodiannSurfaces.scrim`)
/// covers the top bar and the whole screen, and it appears and disappears at
/// once (MASTER §12: no entrance animations). The box is centred, at least
/// 16 from every screen edge (more beside a notch), scrolls when it does not
/// fit, and rises above the keyboard.
///
/// The future completes with the value the dialog pops with, or with `null`
/// when it was **dismissed**: Escape, a tap on the scrim (when
/// [barrierDismissible]) and the Android back button all close it without a
/// result. A caller must therefore treat only an explicit value (say `true`
/// from the confirm button) as consent, so a dismissal can never take a
/// destructive action.
///
/// Focus stays inside while it is open (Tab and Shift+Tab loop over the
/// dialog's controls, also under an enclosing focus scope) and returns to the
/// control that held it when the dialog opened: a trigger opened from the
/// keyboard gets it back; a trigger tapped with a pointer held none (buttons
/// do not take focus on a tap), so nothing is restored.
///
/// There is no re-entry guard (a confirmation may be opened from a dialog), so
/// a caller disables its trigger while the future is pending: a second tap on
/// the same trigger would stack a second dialog.
Future<T?> showZodiannDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final scrim = Theme.of(context).extension<ZodiannSurfaces>()!.scrim;
  return Navigator.of(context, rootNavigator: true).push<T>(
    _ZodiannDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierColor: scrim,
      pageBuilder: (routeContext, _, _) => _DialogLayout(builder: builder),
    ),
  );
}

/// The dialog's route: a raw dialog route with no animation, a closed focus
/// loop and no semantics node for the scrim.
class _ZodiannDialogRoute<T> extends RawDialogRoute<T> {
  _ZodiannDialogRoute({
    required super.pageBuilder,
    required super.barrierDismissible,
    required super.barrierColor,
  }) : super(
         transitionDuration: Duration.zero,
         requestFocus: true,
         // The Navigator's default (`parentScope`) lets Tab at the last
         // control escape into an enclosing non-root focus scope, so a
         // dialog's focus trap would depend on the host app's tree.
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );

  // The scrim adds no accessibility node of its own: the dialog's buttons are
  // the labelled way out for a screen reader (as the drawer's route does).
  @override
  bool get semanticsDismissible => false;
}

/// Centres the box, scrolls it, and keeps it clear of the keyboard and the
/// screen edges.
///
/// The scroll view is **full-viewport and translucent**, so a tap in the
/// empty area falls through to the barrier below it (an opaque scroll view
/// would swallow scrim taps), and the box's shadow and outline are not clipped
/// to the box.
class _DialogLayout extends StatelessWidget {
  const _DialogLayout({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      // The keyboard: the visible area shrinks and the box re-centres in it.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          hitTestBehavior: HitTestBehavior.translucent,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                // 16 from every edge (kit.css max-width calc(100vw - 32px)),
                // plus whatever a notch or a system bar already takes.
                padding: EdgeInsets.all(ZodiannSpace.s4) + media.viewPadding,
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
