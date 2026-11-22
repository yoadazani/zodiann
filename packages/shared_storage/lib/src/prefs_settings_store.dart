import 'package:shared_preferences/shared_preferences.dart';

import 'settings_store.dart';
import 'storage_exception.dart';
import 'storage_failure_reporter.dart';

/// [SettingsStore] over `shared_preferences` (the async API). Every platform
/// failure is reported on [reporter] and rethrown as a [StorageException].
final class PrefsSettingsStore implements SettingsStore {
  PrefsSettingsStore(this._prefs, {StorageFailureReporter? reporter})
    : _reporter = reporter;

  final SharedPreferencesAsync _prefs;
  final StorageFailureReporter? _reporter;

  @override
  Future<T?> read<T>(SettingsKey<T> key) async {
    _checkSupported<T>();
    final Map<String, Object?> found;
    try {
      found = await _prefs.getAll(allowList: {key.name});
    } on Object catch (error) {
      throw _fail(classifyStorageError(error));
    }
    final stored = found[key.name];
    if (stored == null) return null;
    final value = _convert<T>(stored);
    if (value == null) {
      throw _fail(
        StorageException(
          StorageFailureKind.corrupt,
          'Setting "${key.name}" holds a ${stored.runtimeType}, expected $T',
        ),
      );
    }
    return value;
  }

  @override
  Future<void> write<T>(SettingsKey<T> key, T value) async {
    _checkSupported<T>();
    try {
      switch (value) {
        case final bool v:
          await _prefs.setBool(key.name, v);
        case final int v:
          await _prefs.setInt(key.name, v);
        case final double v:
          await _prefs.setDouble(key.name, v);
        case final String v:
          await _prefs.setString(key.name, v);
        case final List<String> v:
          await _prefs.setStringList(key.name, v);
        default:
          throw ArgumentError.value(value, 'value', 'unsupported type');
      }
    } on ArgumentError {
      rethrow;
    } on Object catch (error) {
      throw _fail(classifyStorageError(error));
    }
  }

  @override
  Future<void> remove<T>(SettingsKey<T> key) async {
    _checkSupported<T>();
    try {
      await _prefs.remove(key.name);
    } on Object catch (error) {
      throw _fail(classifyStorageError(error));
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _prefs.clear();
    } on Object catch (error) {
      throw _fail(classifyStorageError(error));
    }
  }

  StorageException _fail(StorageException failure) {
    _reporter?.report(failure);
    return failure;
  }

  static void _checkSupported<T>() {
    final supported =
        T == bool ||
        T == int ||
        T == double ||
        T == String ||
        _isStringList<T>();
    if (!supported) {
      throw ArgumentError.value(T, 'T', 'is not a supported setting type');
    }
  }

  static bool _isStringList<T>() => <String>[] is T && <Object?>[] is! T;

  /// The stored value as a [T], or `null` if it has a different type.
  static T? _convert<T>(Object stored) {
    if (T == bool || T == int || T == double || T == String) {
      return stored is T ? stored as T : null;
    }
    if (stored is List && stored.every((e) => e is String)) {
      return List<String>.from(stored) as T;
    }
    return null;
  }
}
