import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import 'theme/theme_mode_provider.dart';

/// The root widget: theme, localization and the screen tree that navigation
/// and screens plug into later (ZOD-FND-014, ZOD-NAV-*).
class ZodiannApp extends ConsumerWidget {
  const ZodiannApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
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
      home: const ShellHome(),
    );
  }
}

/// The blank shell screen. It must not read `ephemerisPortProvider`: no
/// source is bound yet.
class ShellHome extends StatelessWidget {
  const ShellHome({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold();
}
