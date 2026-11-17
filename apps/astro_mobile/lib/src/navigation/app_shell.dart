import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../app_version.dart';
import 'active_route.dart';
import 'app_route.dart';
import 'warm_link.dart';

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
/// Its items navigate and close it, and the panel closes on an incoming warm
/// deep link (ZOD-NAV-003); see [_DrawerPanel].
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

  /// Opens the drawer. Its panel resolves the localizations and the active
  /// route inside itself, so a locale change or a screen change while it is
  /// open updates it; only the router is captured.
  void _openDrawer(BuildContext context) {
    final router = GoRouter.of(context);
    showZodiannDrawer(context, builder: (_) => _DrawerPanel(router: router));
  }
}

/// The drawer panel (ZOD-NAV-003). An item tap closes the drawer and then
/// navigates, unless the item is the screen already shown. The active mark
/// follows `activeRouteProvider`, never the route the drawer opened on.
///
/// The panel closes itself on every incoming warm platform link (valid,
/// same-screen or malformed: product-owner decision P4) through
/// `warmLinkProvider`, and on nothing internal: not `GoRouter.refresh()`, a
/// `refreshListenable`, a theme or a locale change. Both the close and the
/// tap are ignored once the drawer route is no longer active (it is already
/// leaving), so a second pop never removes the shell page.
class _DrawerPanel extends ConsumerStatefulWidget {
  const _DrawerPanel({required this.router});

  final GoRouter router;

  @override
  ConsumerState<_DrawerPanel> createState() => _DrawerPanelState();
}

class _DrawerPanelState extends ConsumerState<_DrawerPanel> {
  late final WarmLinkEvents _warmLinks;

  @override
  void initState() {
    super.initState();
    _warmLinks = ref.read(warmLinkProvider)..addListener(_closeOnWarmLink);
  }

  @override
  void dispose() {
    _warmLinks.removeListener(_closeOnWarmLink);
    super.dispose();
  }

  bool get _routeIsActive => ModalRoute.of(context)?.isActive == true;

  void _closeOnWarmLink() {
    if (_routeIsActive) Navigator.of(context).pop();
  }

  void _open(AppRoute target) {
    if (!_routeIsActive) return;
    final current = ref.read(activeRouteProvider);
    Navigator.of(context).pop();
    if (target != current) widget.router.go(target.path);
  }

  @override
  Widget build(BuildContext context) {
    final l = ZodiannLocalizations.of(context);
    final active = ref.watch(activeRouteProvider);
    ZodiannDrawerItem item(AppRoute r) => ZodiannDrawerItem(
      icon: r.drawerIcon,
      name: r.title(l),
      description: r.drawerDescription(l),
      selected: r == active,
      onTap: () => _open(r),
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
      onClose: () => Navigator.of(context).maybePop(),
      versionLabel: l.drawerVersion(appVersion),
      offlineLabel: l.drawerOffline,
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
