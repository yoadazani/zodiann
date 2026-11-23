import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The language the app was started in (ZOD-L10-002), set by `main()` through
/// `bootstrapOverrides`. `null` follows the device with English as the
/// fallback, which is what tests that pump `ZodiannApp` without overrides see.
///
/// A plain provider for now: ZOD-L10-003 (the in-app override) turns it into a
/// notifier with a setter and persists the choice under `languageKey`.
///
/// **App-level, not a feature contract** (feature packages never import the
/// app layer); where a settings screen reaches it from is decided with
/// ZOD-SET-002 / ZOD-L10-003.
final Provider<Locale?> appLocaleProvider = Provider<Locale?>((ref) => null);
