// ZOD-L10-002 Task 2: the saved language wins; otherwise detect once, save
// it, and never fail the app because storage failed (L-2, D3 to D5).
import 'package:astro_mobile/src/localization/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_storage/shared_storage.dart';

import 'support/memory_settings_store.dart';

Future<Locale> _load(MemorySettingsStore store, List<Locale> device) =>
    loadOrDetectLanguage(store: store, deviceLocales: device);

StorageException _failure(StorageFailureKind kind) =>
    StorageException(kind, 'test failure');

void main() {
  test('first launch detects and saves', () async {
    final store = MemorySettingsStore();
    final got = await _load(store, const [Locale('he', 'IL')]);
    expect(got, const Locale('he'));
    expect(store.values[languageKey.name], 'he');
    expect(store.writes, 1);
  });

  test('the second launch reads the saved value and writes nothing, '
      'whatever the device says', () async {
    final he = MemorySettingsStore({languageKey.name: 'he'});
    expect(await _load(he, const [Locale('en')]), const Locale('he'));
    expect(he.writes, 0);
    final en = MemorySettingsStore({languageKey.name: 'en'});
    expect(await _load(en, const [Locale('he')]), const Locale('en'));
    expect(en.writes, 0);
  });

  test('an unsupported saved value is re-detected and overwritten', () async {
    for (final bad in ['fr', '']) {
      final store = MemorySettingsStore({languageKey.name: bad});
      expect(await _load(store, const [Locale('he')]), const Locale('he'));
      expect(store.values[languageKey.name], 'he', reason: 'saved "$bad"');
      expect(store.writes, 1);
    }
  });

  test('a wrong-typed saved value is re-detected and overwritten', () async {
    final store = MemorySettingsStore({languageKey.name: 7});
    expect(await _load(store, const [Locale('he')]), const Locale('he'));
    expect(store.values[languageKey.name], 'he');
  });

  test('a corrupt read is treated as unset and overwritten', () async {
    final store = MemorySettingsStore()
      ..readError = _failure(StorageFailureKind.corrupt);
    expect(await _load(store, const [Locale('he')]), const Locale('he'));
    expect(store.writes, 1);
  });

  test(
    'an unavailable read resolves from the device and does not write',
    () async {
      for (final kind in [
        StorageFailureKind.unavailable,
        StorageFailureKind.full,
      ]) {
        final store = MemorySettingsStore()..readError = _failure(kind);
        expect(await _load(store, const [Locale('he')]), const Locale('he'));
        expect(store.writes, 0, reason: kind.name);
      }
    },
  );

  test('a failed write still returns the detected language', () async {
    final store = MemorySettingsStore()
      ..writeError = _failure(StorageFailureKind.full);
    expect(await _load(store, const [Locale('he')]), const Locale('he'));
    expect(store.writes, 1);
  });

  test('errors other than StorageException propagate', () async {
    final store = MemorySettingsStore()..readError = StateError('bug');
    expect(_load(store, const [Locale('he')]), throwsStateError);
  });
}
