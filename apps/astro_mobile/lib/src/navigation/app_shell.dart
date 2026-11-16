import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import 'app_route.dart';

/// The shell every screen renders in (ZOD-NAV-001): the sticky top bar over
/// [child], with the body extending behind it so content scrolls beneath the
/// bar's blur. Scroll views pick up the bar's height from the inherited
/// `MediaQuery` top padding; one with its own `padding` must add
/// `MediaQuery.paddingOf(context).top` itself.
///
/// The shell maps [route] to its title, subtitle and actions; the bar itself
/// knows nothing about routes. The hamburger and the Square actions are
/// disabled until their tasks wire them (product-owner decision, Option B):
/// the hamburger in ZOD-NAV-002, Save in the saved-squares task, Export in
/// the Excel task. ZOD-NAV-002/003 add the drawer here.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.route, required this.child});

  /// The active screen.
  final AppRoute route;

  /// The screen.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = ZodiannLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ZodiannTopBar.heightFor(width)),
        child: ZodiannTopBar(
          title: route.title(l),
          subtitle: route.subtitle(l),
          menuLabel: l.openMenu,
          onMenuPressed: null,
          actions: switch (route) {
            AppRoute.square => [
              ZodiannTopBarAction(
                icon: ZodiannIcons.save,
                label: l.actionSave,
                onPressed: null,
              ),
              ZodiannTopBarAction(
                icon: ZodiannIcons.download,
                label: l.actionExportXlsx,
                variant: ZodiannButtonVariant.primary,
                onPressed: null,
              ),
            ],
            AppRoute.wheel ||
            AppRoute.saved ||
            AppRoute.settings ||
            AppRoute.about => const [],
          },
        ),
      ),
      body: child,
    );
  }
}

/// Each screen's top-bar copy.
extension AppRouteCopy on AppRoute {
  /// The top-bar title.
  String title(ZodiannLocalizations l) => switch (this) {
    AppRoute.wheel => l.screenWheelTitle,
    AppRoute.square => l.screenSquareTitle,
    AppRoute.saved => l.screenSavedTitle,
    AppRoute.settings => l.screenSettingsTitle,
    AppRoute.about => l.screenAboutTitle,
  };

  /// The top-bar subtitle.
  String subtitle(ZodiannLocalizations l) => switch (this) {
    AppRoute.wheel => l.screenWheelSubtitle,
    AppRoute.square => l.screenSquareSubtitle,
    AppRoute.saved => l.screenSavedSubtitle,
    AppRoute.settings => l.screenSettingsSubtitle,
    AppRoute.about => l.screenAboutSubtitle,
  };
}
