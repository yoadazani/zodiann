import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../app_version.dart';
import 'app_route.dart';

/// The shell every screen renders in (ZOD-NAV-001): the sticky top bar over
/// [child], with the body extending behind it so content scrolls beneath the
/// bar's blur. Scroll views pick up the bar's height from the inherited
/// `MediaQuery` top padding; one with its own `padding` must add
/// `MediaQuery.paddingOf(context).top` itself.
///
/// The shell maps [route] to its title, subtitle and actions; the bar itself
/// knows nothing about routes. The Square actions are disabled until their
/// tasks wire them (product-owner decision, Option B): Save in the
/// saved-squares task, Export in the Excel task.
///
/// The hamburger opens the navigation drawer (ZOD-NAV-002): an overlay route
/// on the root navigator (`showZodiannDrawer`), never part of this layout.
/// Its items only report a tap for now; ZOD-NAV-003 wires navigation and
/// closing.
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
          onMenuPressed: () => _openDrawer(context),
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

  /// Opens the drawer. The builder resolves the localizations inside itself,
  /// so a locale change while it is open updates its copy; only [route] is
  /// captured.
  void _openDrawer(BuildContext context) {
    showZodiannDrawer(
      context,
      builder: (drawerContext) {
        final l = ZodiannLocalizations.of(drawerContext);
        ZodiannDrawerItem item(AppRoute r) => ZodiannDrawerItem(
          icon: r.drawerIcon,
          name: r.title(l),
          description: r.drawerDescription(l),
          selected: r == route,
          // Inert until ZOD-NAV-003 wires navigation and closing.
          onTap: () {},
        );
        return ZodiannDrawer(
          wordmark: l.appTitle,
          groups: [
            ZodiannDrawerGroup(
              label: l.drawerGroupAnalysis,
              items: [
                for (final r in AppRoute.values)
                  if (r.drawerGroup == AppRouteDrawerGroup.analysis) item(r),
              ],
            ),
            ZodiannDrawerGroup(
              label: l.drawerGroupLibrary,
              items: [
                for (final r in AppRoute.values)
                  if (r.drawerGroup == AppRouteDrawerGroup.library) item(r),
              ],
            ),
          ],
          closeLabel: l.closeMenu,
          onClose: () => Navigator.of(drawerContext).maybePop(),
          versionLabel: l.drawerVersion(appVersion),
          offlineLabel: l.drawerOffline,
        );
      },
    );
  }
}

/// The drawer's two groups (D17).
enum AppRouteDrawerGroup { analysis, library }

/// Each screen's drawer presentation.
extension AppRouteDrawer on AppRoute {
  /// The group the item sits in: the two instruments, then the supporting
  /// screens.
  AppRouteDrawerGroup get drawerGroup => switch (this) {
    AppRoute.wheel || AppRoute.square => AppRouteDrawerGroup.analysis,
    AppRoute.saved ||
    AppRoute.settings ||
    AppRoute.about => AppRouteDrawerGroup.library,
  };

  /// The item's icon.
  ZodiannIconData get drawerIcon => switch (this) {
    AppRoute.wheel => ZodiannIcons.wheel,
    AppRoute.square => ZodiannIcons.grid,
    AppRoute.saved => ZodiannIcons.folder,
    AppRoute.settings => ZodiannIcons.sliders,
    AppRoute.about => ZodiannIcons.info,
  };

  /// The item's short description (NAV-3).
  String drawerDescription(ZodiannLocalizations l) => switch (this) {
    AppRoute.wheel => l.drawerDescWheel,
    AppRoute.square => l.drawerDescSquare,
    AppRoute.saved => l.drawerDescSaved,
    AppRoute.settings => l.drawerDescSettings,
    AppRoute.about => l.drawerDescAbout,
  };
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
