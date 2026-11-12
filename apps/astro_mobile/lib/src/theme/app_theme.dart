import 'package:material_ui/material_ui.dart';

/// Placeholder theme seam (ZOD-FND-005, product-owner decision 2).
///
/// ZOD-FND-013 replaces these with the token-based theme skeleton and
/// ZOD-UI-001 fills in the token values. Until then: plain light and dark
/// `ThemeData`, with no color literals (ARCH-7).
abstract final class AppTheme {
  static final ThemeData light = ThemeData(brightness: Brightness.light);
  static final ThemeData dark = ThemeData(brightness: Brightness.dark);
}
