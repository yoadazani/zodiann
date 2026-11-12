import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The app's theme mode: follow the device (default), or force dark or light.
///
/// Setting it re-themes the running app immediately, with no restart.
///
/// **App-level placeholder, not a public contract.** Feature packages must
/// never import the app layer, so this is not the provider a settings screen
/// can use directly. ZOD-SET-003 (the theme picker) and ZOD-SET-007 /
/// ZOD-FND-006 (persisting the choice) decide where the feature-accessible
/// contract lives. It is app-wide state, not screen state (ARCH-3).
final class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Switches the app to [mode].
  void set(ThemeMode mode) => state = mode;
}

/// See [ThemeModeController].
final NotifierProvider<ThemeModeController, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
