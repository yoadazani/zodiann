import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import 'navigation/app_router.dart';
import 'theme/theme_mode_provider.dart';

/// The root widget: theme, localization and the router whose routes the
/// screens plug into (ZOD-FND-014). Every screen renders inside the app
/// shell with its top bar (ZOD-NAV-001); the drawer comes in ZOD-NAV-002.
class ZodiannApp extends ConsumerWidget {
  const ZodiannApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
      theme: ZodiannTheme.porcelain,
      darkTheme: ZodiannTheme.graphite,
      themeMode: ref.watch(themeModeProvider),
      // Not the generated ZodiannLocalizations.localizationsDelegates: it
      // lists flutter_localizations' deprecated delegates, which register a
      // different MaterialLocalizations type than material_ui's widgets read.
      localizationsDelegates: const [
        ZodiannLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      // Generated from the ARB files with English first, so Flutter's default
      // resolution falls back to it (L-2).
      supportedLocales: ZodiannLocalizations.supportedLocales,
      onGenerateTitle: (context) => ZodiannLocalizations.of(context).appTitle,
      // The typography follows the resolved locale (ZOD-UI-002): Plex Sans
      // for Latin, Plex Sans Hebrew for Hebrew. The builder sits below the
      // theme animation, so the swap also applies mid-animation.
      builder: (context, child) => Theme(
        data: withZodiannScript(
          Theme.of(context),
          ZodiannScript.forLocale(Localizations.localeOf(context)),
        ),
        child: child!,
      ),
    );
  }
}
