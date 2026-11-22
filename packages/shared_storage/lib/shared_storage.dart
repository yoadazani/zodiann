/// On-device storage: wrapper over shared_preferences and SQLite, plus schema migrations.
library;

export 'src/storage_exception.dart' show StorageException, StorageFailureKind;
export 'src/storage_failure_reporter.dart' show StorageFailureReporter;
export 'src/prefs_settings_store.dart' show PrefsSettingsStore;
export 'src/settings_store.dart' show SettingsKey, SettingsStore;
