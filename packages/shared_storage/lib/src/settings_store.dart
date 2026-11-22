/// A named setting of type [T]. [T] must be `bool`, `int`, `double`, `String`
/// or `List<String>`; the store throws [ArgumentError] for any other type
/// (a type parameter cannot be checked in a constant constructor).
///
/// The feature that owns a setting declares its key; this package declares
/// none (the settings model is ZOD-SET-007's).
final class SettingsKey<T> {
  const SettingsKey(this.name);

  /// The storage key.
  final String name;

  @override
  String toString() => 'SettingsKey<$T>($name)';
}

/// Typed key-value storage for user settings (DATA-1). Feature code depends on
/// this interface, never on `shared_preferences`.
///
/// Every method throws a `StorageException` when storage fails; an unset key
/// reads as `null`, and a stored value of the wrong type throws `corrupt`.
abstract interface class SettingsStore {
  /// The value stored for [key], or `null` when it was never written.
  Future<T?> read<T>(SettingsKey<T> key);

  /// Stores [value] for [key], replacing any previous value.
  Future<void> write<T>(SettingsKey<T> key, T value);

  /// Deletes [key]; does nothing if it was never written.
  Future<void> remove<T>(SettingsKey<T> key);

  /// Deletes every setting.
  Future<void> clear();
}
