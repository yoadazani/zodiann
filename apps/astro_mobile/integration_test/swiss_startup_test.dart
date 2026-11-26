// ZOD-EPH-002: the real startup on a device: the real library probes, the real
// data-file installer and the real bindings. Run on an Android device or
// emulator:
//   flutter test integration_test/swiss_startup_test.dart -d <device>
import 'dart:io';
import 'dart:ui';

import 'package:astro_core/astro_core.dart';
import 'package:astro_mobile/src/bootstrap.dart';
import 'package:astro_mobile/src/di/ephemeris_providers.dart';
import 'package:astro_mobile/src/di/ephemeris_wiring.dart';
import 'package:astro_mobile/src/ephemeris/ephemeris_status.dart';
import 'package:astro_mobile/src/ephemeris/swiss_data_installer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/shared_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final utc = DateTime.utc(2026, 11, 26);

  /// Every body, the node included, has a position from the bound port.
  void expectPositions(ProviderContainer container) {
    final port = container.read(ephemerisPortProvider);
    for (final body in Body.values) {
      expect(
        port.position(body, utc),
        isA<EphemerisSuccess>(),
        reason: body.name,
      );
    }
  }

  test('a first start installs the data and binds the primary source; a second '
      'start does not rewrite it', () async {
    final support = await getApplicationSupportDirectory();
    final data = Directory('${support.path}/ephe');
    if (data.existsSync()) data.deleteSync(recursive: true);

    Future<ProviderContainer> start() async => ProviderContainer.test(
      overrides: await bootstrapOverrides(
        store: PrefsSettingsStore(SharedPreferencesAsync()),
        deviceLocales: const [Locale('en')],
        ephemeris: productionEphemerisDependencies(),
      ),
    );

    final first = await start();

    expect(
      first.read(ephemerisStatusProvider).source,
      ActiveEphemerisSource.primary,
    );
    expectPositions(first);

    final old = DateTime(2001, 2, 3);
    final files = [
      for (final name in swissDataFileNames) File('${data.path}/$name'),
    ];
    for (final file in files) {
      file.setLastModifiedSync(old);
    }

    final second = await start();

    expect(
      second.read(ephemerisStatusProvider).source,
      ActiveEphemerisSource.primary,
    );
    expectPositions(second);
    for (final file in files) {
      expect(file.lastModifiedSync(), old, reason: file.path);
    }
  });

  test('if the Swiss library did not load, the real backup is bound', () async {
    final production = productionEphemerisDependencies();
    var preparations = 0;

    final container = ProviderContainer.test(
      overrides: await ephemerisOverrides(
        EphemerisDependencies(
          swissLoads: () => false,
          prepareSwissData: () async {
            preparations++;
            return null;
          },
          openSwissSource: production.openSwissSource,
          backupLoads: production.backupLoads,
          openBackupSource: production.openBackupSource,
        ),
      ),
    );

    expect(
      container.read(ephemerisStatusProvider).source,
      ActiveEphemerisSource.backup,
    );
    expect(preparations, 0);
    expectPositions(container);
  });
}
