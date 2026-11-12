import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'src/app.dart';
import 'src/di/app_overrides.dart';

void main() =>
    runApp(ProviderScope(overrides: appOverrides, child: const ZodiannApp()));
