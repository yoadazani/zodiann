import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_storage/src/prefs_settings_store.dart';
import 'package:shared_storage/src/settings_store.dart';
import 'package:shared_storage/src/storage_exception.dart';
import 'package:shared_storage/src/storage_failure_reporter.dart';

/// A backing store whose writes can be made to fail.
base class _FlakyPrefs extends InMemorySharedPreferencesAsync {
  _FlakyPrefs.withData(super.data) : super.withData();

  bool failWrites = false;

  void _maybeFail() {
    if (failWrites) throw PlatformException(code: 'disk', message: 'no space');
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    _maybeFail();
    return super.setString(key, value, options);
  }

  @override
  Future<bool> setInt(
    String key,
    int value,
    SharedPreferencesOptions options,
  ) async {
    _maybeFail();
    return super.setInt(key, value, options);
  }
}

PrefsSettingsStore _store(
  SharedPreferencesAsyncPlatform backing, {
  StorageFailureReporter? reporter,
}) {
  SharedPreferencesAsyncPlatform.instance = backing;
  return PrefsSettingsStore(SharedPreferencesAsync(), reporter: reporter);
}

const _flag = SettingsKey<bool>('test.flag');
const _count = SettingsKey<int>('test.count');
const _ratio = SettingsKey<double>('test.ratio');
const _label = SettingsKey<String>('test.label');
const _tags = SettingsKey<List<String>>('test.tags');

void main() {
  test('round-trips each supported type', () async {
    final store = _store(InMemorySharedPreferencesAsync.empty());
    await store.write(_flag, true);
    await store.write(_count, 7);
    await store.write(_ratio, 2.5);
    await store.write(_label, 'שלום');
    await store.write(_tags, ['a', 'b']);
    expect(await store.read(_flag), isTrue);
    expect(await store.read(_count), 7);
    expect(await store.read(_ratio), 2.5);
    expect(await store.read(_label), 'שלום');
    expect(await store.read(_tags), ['a', 'b']);
  });

  test('a second store over the same backing sees the written value', () async {
    final backing = InMemorySharedPreferencesAsync.empty();
    await _store(backing).write(_label, 'kept');
    expect(await _store(backing).read(_label), 'kept');
  });

  test('read of an unset key is null', () async {
    final store = _store(InMemorySharedPreferencesAsync.empty());
    expect(await store.read(_label), isNull);
  });

  test('write replaces the previous value', () async {
    final store = _store(InMemorySharedPreferencesAsync.empty());
    await store.write(_count, 1);
    await store.write(_count, 2);
    expect(await store.read(_count), 2);
  });

  test('remove deletes only that key', () async {
    final store = _store(InMemorySharedPreferencesAsync.empty());
    await store.write(_count, 1);
    await store.write(_label, 'x');
    await store.remove(_count);
    expect(await store.read(_count), isNull);
    expect(await store.read(_label), 'x');
  });

  test('clear removes every key', () async {
    final store = _store(InMemorySharedPreferencesAsync.empty());
    await store.write(_count, 1);
    await store.write(_label, 'x');
    await store.clear();
    expect(await store.read(_count), isNull);
    expect(await store.read(_label), isNull);
  });

  test(
    'a stored value of the wrong type is reported and read throws corrupt',
    () async {
      final reporter = StorageFailureReporter();
      addTearDown(reporter.dispose);
      final seen = <StorageException>[];
      reporter.failures.listen(seen.add);
      final store = _store(
        InMemorySharedPreferencesAsync.withData({'test.count': 'not a number'}),
        reporter: reporter,
      );
      await expectLater(
        store.read(_count),
        throwsA(
          isA<StorageException>().having(
            (e) => e.kind,
            'kind',
            StorageFailureKind.corrupt,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(seen.single.kind, StorageFailureKind.corrupt);
    },
  );

  test('a failing write throws unavailable, reports it, and keeps the old '
      'value', () async {
    final backing = _FlakyPrefs.withData({'test.label': 'old'});
    final reporter = StorageFailureReporter();
    addTearDown(reporter.dispose);
    final seen = <StorageException>[];
    reporter.failures.listen(seen.add);
    final store = _store(backing, reporter: reporter);

    backing.failWrites = true;
    await expectLater(
      store.write(_label, 'new'),
      throwsA(
        isA<StorageException>().having(
          (e) => e.kind,
          'kind',
          StorageFailureKind.unavailable,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(seen.single.kind, StorageFailureKind.unavailable);

    backing.failWrites = false;
    expect(await _store(backing).read(_label), 'old');
  });

  test(
    'read and write with an unsupported key type throw ArgumentError',
    () async {
      final store = _store(InMemorySharedPreferencesAsync.empty());
      const bad = SettingsKey<DateTime>('test.bad');
      await expectLater(store.read(bad), throwsArgumentError);
      await expectLater(store.write(bad, DateTime(2000)), throwsArgumentError);
      await expectLater(store.remove(bad), throwsArgumentError);
    },
  );
}
