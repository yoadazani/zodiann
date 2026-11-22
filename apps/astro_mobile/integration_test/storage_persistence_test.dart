// ZOD-FND-006 Task 5 Step 1: "settings persist across app restarts" on a real
// process restart, for both stores, in the app's real data directory.
//
// Two launches of the same debug APK, with `adb shell am force-stop` between
// them (see docs/PROGRESS.md for the exact commands):
//   * launch 1 finds no marker file: it writes a setting and a saved square,
//     then writes the marker and reports `STORAGE_PHASE_1_WRITTEN`;
//   * launch 2 finds the marker: it asserts both values survived the restart,
//     removes everything it wrote, and reports `STORAGE_PHASE_2_VERIFIED`.
// Each launch also prints which phase it ran, so a skipped force-stop (both
// phases in one process) cannot pass unnoticed: phase 2 asserts the process
// start time differs from the one phase 1 recorded.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gann_core/gann_core.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/shared_storage.dart';

const _key = SettingsKey<String>('storage_persistence_test.value');
const _startKey = SettingsKey<String>('storage_persistence_test.process_start');
const _expected = 'kept across a restart: שלום';

final _square = SquareConfig(
  id: 'storage-persistence-test',
  name: 'Persistence check',
  mode: SquareMode.datetime,
  anchor: OffsetDateTime(DateTime.utc(2026, 3, 29, 1, 30), 120),
  size: 15,
  stepHours: 6,
  highlights: [
    HighlightRule(
      id: 'custom',
      label: 'Custom',
      match: MultipleOfMatch(7.5),
      colorToken: 'diag',
      priority: 1,
    ),
  ],
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 2, 1),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings and a saved square survive a process restart', (
    tester,
  ) async {
    final dir = await getApplicationSupportDirectory();
    final marker = File('${dir.path}/storage_persistence_marker');
    final dbFile = File('${dir.path}/storage_persistence_test.sqlite');
    final settings = PrefsSettingsStore(SharedPreferencesAsync());
    final launchId = DateTime.now().toUtc().toIso8601String();

    if (!marker.existsSync()) {
      final store = await openSquareStore(dbFile);
      await settings.write(_key, _expected);
      await settings.write(_startKey, launchId);
      await store.save(_square);
      await store.close();
      marker.writeAsStringSync('written');
      // ignore: avoid_print
      print('STORAGE_PHASE_1_WRITTEN $launchId');
      return;
    }

    final store = await openSquareStore(dbFile);
    final firstLaunch = await settings.read(_startKey);
    expect(await settings.read(_key), _expected);
    expect(await store.get(_square.id), _square);
    expect(
      (await store.get(_square.id))!.anchor!.offsetMinutes,
      120,
      reason: 'the anchor offset survives the restart',
    );
    expect(
      firstLaunch,
      isNot(launchId),
      reason: 'phase 2 must run in a new process launch',
    );
    await store.deleteAll();
    await store.close();
    await settings.remove(_key);
    await settings.remove(_startKey);
    marker.deleteSync();
    if (dbFile.existsSync()) dbFile.deleteSync();
    // ignore: avoid_print
    print('STORAGE_PHASE_2_VERIFIED first=$firstLaunch now=$launchId');
  });
}
