// Test only: an in-memory SettingsStore that counts reads and writes and can
// be told to fail, so the language bootstrap is tested without a platform.
import 'package:shared_storage/shared_storage.dart';

final class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, Object>? initial]) : values = {...?initial};

  final Map<String, Object> values;
  int reads = 0;
  int writes = 0;

  /// Thrown by [read] when set (a `StorageException` or any other error).
  Object? readError;

  /// Thrown by [write] when set.
  Object? writeError;

  @override
  Future<T?> read<T>(SettingsKey<T> key) async {
    reads++;
    if (readError != null) throw readError!;
    final v = values[key.name];
    if (v == null) return null;
    if (v is! T) {
      throw StorageException(
        StorageFailureKind.corrupt,
        'Setting "${key.name}" holds a ${v.runtimeType}, expected $T',
      );
    }
    return v as T;
  }

  @override
  Future<void> write<T>(SettingsKey<T> key, T value) async {
    writes++;
    if (writeError != null) throw writeError!;
    values[key.name] = value as Object;
  }

  @override
  Future<void> remove<T>(SettingsKey<T> key) async => values.remove(key.name);

  @override
  Future<void> clear() async => values.clear();
}
