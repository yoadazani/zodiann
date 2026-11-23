import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/shared_storage.dart';

import 'src/app.dart';
import 'src/bootstrap.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Built here, never at import time: SharedPreferencesAsync needs the
  // platform plugin registered.
  final overrides = await bootstrapOverrides(
    store: PrefsSettingsStore(SharedPreferencesAsync()),
    deviceLocales: binding.platformDispatcher.locales,
  );
  runApp(ProviderScope(overrides: overrides, child: const ZodiannApp()));
}
