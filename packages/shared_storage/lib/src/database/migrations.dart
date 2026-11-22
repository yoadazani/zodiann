import 'package:drift/drift.dart';

import '../storage_exception.dart';

/// One schema step: moves the database from version `n - 1` to `n`.
typedef MigrationStep = Future<void> Function(Migrator migrator);

/// The shipped steps, keyed by the version each one produces. Schema v1 has
/// none. ZOD-DAT-012 owns the real migration process, the schema dumps and the
/// first real step; this is the template it extends (add `2: (m) async { ... }`
/// and raise `AppDatabase.currentSchemaVersion`).
const Map<int, MigrationStep> migrationSteps = {};

/// Brings a database at version [from] up to [to] by running the steps for
/// versions `from + 1` through `to`, in ascending order, inside one
/// transaction.
///
/// `from == to` does nothing. Throws `StorageException(unsupportedVersion)`
/// when `from > to` (the file was written by a newer app) or when a step in
/// the range is missing; both are decided before any step runs, so a refused
/// range opens no transaction and changes nothing. Drift calls this for
/// upgrades and downgrades alike and never when the versions are equal.
///
/// The transaction matters: drift runs `onUpgrade` without one and writes the
/// new `user_version` only after it returns, so a step that fails part-way
/// would otherwise leave its schema change in the file at the old version, and
/// the next launch would run the same step again and fail. Inside the
/// transaction a failure rolls every step of the range back. See
/// `docs/storage/schema-migrations.md`.
Future<void> applyMigrations(
  Migrator migrator,
  int from,
  int to, {
  Map<int, MigrationStep> steps = migrationSteps,
}) async {
  if (from == to) return;
  if (from > to) {
    throw StorageException(
      StorageFailureKind.unsupportedVersion,
      'The saved data has schema version $from but this app knows up to $to',
    );
  }
  for (var version = from + 1; version <= to; version++) {
    if (steps[version] == null) {
      throw StorageException(
        StorageFailureKind.unsupportedVersion,
        'No migration step to schema version $version',
      );
    }
  }
  await migrator.database.transaction(() async {
    for (var version = from + 1; version <= to; version++) {
      await steps[version]!(migrator);
    }
  });
}
