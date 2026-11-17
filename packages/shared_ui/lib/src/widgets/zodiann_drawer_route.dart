import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_surfaces.dart';
import 'zodiann_drawer.dart';

/// The open drawer of each root navigator: a second `showZodiannDrawer` is
/// ignored while one is open (active, not popping).
final Expando<_ZodiannDrawerRoute> _openDrawers = Expando<_ZodiannDrawerRoute>(
  'openZodiannDrawers',
);

/// Shows a navigation drawer (ZOD-NAV-002): [builder] returns the panel
/// (a [ZodiannDrawer]) whose close button should call
/// `Navigator.of(context).maybePop()`.
///
/// It is a modal route pushed on the **root** navigator, so it covers the top
/// bar and the whole screen; the guard assumes the caller's route lives on the
/// root navigator too (true in the app: go_router places its shell there). It
/// slides in from the start edge in 240 ms and out in 180 ms, both along
/// `easeOutCubic` (MASTER §12), with the scrim fading in step; both are
/// instant under reduced motion (read from [context] when shown). It closes by
/// a tap on the scrim, the panel's close button, a swipe toward the start edge
/// (mirrored in Hebrew) or the Android back button; each pops the route.
///
/// A call while a drawer is open does nothing; one made while the previous
/// drawer is still closing opens a new drawer.
Future<void> showZodiannDrawer(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final existing = _openDrawers[navigator];
  if (existing != null && existing.isActive) return Future<void>.value();
  final route = _ZodiannDrawerRoute(
    builder: builder,
    reduceMotion: MediaQuery.disableAnimationsOf(context),
    navigator: navigator,
  );
  _openDrawers[navigator] = route;
  return navigator.push<void>(route);
}

/// The route's progress: `easeOutCubic` opening and its flip closing (Flutter
/// applies a curve unflipped on the way back, which would close slowly then
/// fast), but the raw linear value while a swipe is in progress and through
/// the settle after it, so the panel follows the finger 1:1 and never jumps.
class _ProgressCurve extends Curve {
  const _ProgressCurve(this.route, {this.closing = false});

  final _ZodiannDrawerRoute route;
  final bool closing;

  @override
  double transformInternal(double t) {
    if (route._gestureActive) return t;
    return closing
        ? 1.0 - Curves.easeOutCubic.transform(1.0 - t)
        : Curves.easeOutCubic.transform(t);
  }
}

class _ZodiannDrawerRoute extends PopupRoute<void> {
  _ZodiannDrawerRoute({
    required this.builder,
    required this.reduceMotion,
    required this._navigator,
  });

  final WidgetBuilder builder;
  final bool reduceMotion;
  final NavigatorState _navigator;

  bool _gestureActive = false;
  CurvedAnimation? _progress;

  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : ZodiannStates.drawerOpenDuration;

  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? Duration.zero : ZodiannStates.drawerCloseDuration;

  @override
  bool get barrierDismissible => true;

  // The route builds its own scrim (buildModalBarrier).
  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  // The scrim adds no accessibility node of its own; the close button is the
  // accessible way to dismiss.
  @override
  bool get semanticsDismissible => false;

  /// One progress for the slide and the scrim.
  @override
  Animation<double> createAnimation() {
    return _progress = CurvedAnimation(
      parent: super.createAnimation(),
      curve: _ProgressCurve(this),
      reverseCurve: _ProgressCurve(this, closing: true),
    );
  }

  @override
  void dispose() {
    _progress?.dispose();
    if (identical(_openDrawers[_navigator], this)) {
      _openDrawers[_navigator] = null;
    }
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // The slide is relative to the panel, not the full-screen page: it is
    // inside the Align.
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SlideTransition(
          textDirection: Directionality.of(context),
          position: animation.drive(
            Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero),
          ),
          child: Builder(builder: builder),
        ),
      ),
    );
  }

  @override
  Widget buildModalBarrier() {
    // A Builder, so the scrim colour is read from the theme at the barrier's
    // own place in the tree and follows a theme change while open.
    return Builder(
      builder: (context) {
        final scrim = Theme.of(context).extension<ZodiannSurfaces>()!.scrim;
        return _swipeable(
          context,
          AnimatedModalBarrier(
            // The scrim colour at alpha 0 (not a blend up from black).
            color: animation!.drive(
              ColorTween(begin: scrim.withValues(alpha: 0), end: scrim),
            ),
            dismissible: barrierDismissible,
            barrierSemanticsDismissible: semanticsDismissible,
          ),
        );
      },
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // The detector sits outside the page's IgnorePointer (which ignores
    // pointers while the route reverses), around the whole page.
    return _swipeable(context, child);
  }

  Widget _swipeable(BuildContext context, Widget child) {
    final width = ZodiannDrawer.widthFor(MediaQuery.sizeOf(context).width);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onHorizontalDragStart: _dragStart,
      onHorizontalDragUpdate: (d) => _dragUpdate(d, width, rtl),
      onHorizontalDragEnd: (d) => _dragEnd(d.primaryVelocity ?? 0, rtl, d),
      onHorizontalDragCancel: () => _dragEnd(0, rtl, null),
      child: child,
    );
  }

  void _dragStart(DragStartDetails details) {
    final c = controller;
    if (c == null || !isCurrent || _gestureActive) return;
    // The panel shows the eased position; the gesture runs on the raw
    // controller value, so take the shown position over first (else grabbing
    // the panel mid-open would make it jump back).
    final shown = _progress?.value ?? c.value;
    _gestureActive = true;
    c.stop();
    c.value = shown;
    _navigator.didStartUserGesture();
  }

  void _dragUpdate(DragUpdateDetails details, double width, bool rtl) {
    final c = controller;
    if (c == null || !_gestureActive) return;
    // Toward the start edge closes: leftward in LTR, rightward in RTL.
    final delta = (rtl ? -1 : 1) * (details.primaryDelta ?? 0) / width;
    c.value = (c.value + delta).clamp(0.0, 1.0);
  }

  void _dragEnd(double velocity, bool rtl, DragEndDetails? details) {
    final c = controller;
    if (c == null || !_gestureActive) return;
    // Negative: toward the start edge.
    final toward = rtl ? -velocity : velocity;
    final bool settleOpen;
    if (c.value <= 0) {
      settleOpen = false; // reaching the closed edge always closes
    } else if (toward.abs() >= ZodiannStates.drawerFlingVelocity) {
      settleOpen = toward > 0;
    } else {
      settleOpen = c.value > 0.5;
    }
    if (settleOpen) {
      c.animateTo(
        1.0,
        duration: transitionDuration * (1.0 - c.value),
        curve: Curves.linear,
      );
    } else {
      // didPop starts the (linear, from here) reverse.
      _navigator.pop();
    }
    if (c.isAnimating) {
      // Stay linear through the settle: end the gesture when it finishes.
      late AnimationStatusListener listener;
      listener = (status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          c.removeStatusListener(listener);
          _endGesture();
        }
      };
      c.addStatusListener(listener);
    } else {
      _endGesture();
    }
  }

  void _endGesture() {
    if (!_gestureActive) return;
    _gestureActive = false;
    _navigator.didStopUserGesture();
  }
}
