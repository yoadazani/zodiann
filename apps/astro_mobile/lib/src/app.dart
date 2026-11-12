import 'package:material_ui/material_ui.dart';

import 'theme/app_theme.dart';

/// The root widget: theme, localization and the screen tree that navigation
/// and screens plug into later (ZOD-FND-014, ZOD-NAV-*).
class ZodiannApp extends StatelessWidget {
  const ZodiannApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Placeholder until ZOD-L10-001's generated supportedLocales. English is
      // first, so Flutter's default resolution falls back to it (L-2).
      supportedLocales: const [Locale('en'), Locale('he')],
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
