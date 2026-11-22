import 'package:drift/drift.dart';

import 'migrations.dart';

part 'app_database.g.dart';

/// Saved squares (DATA-1, DATA-2). `config_json` holds the whole
/// `SquareConfig.toJson()` (its `HighlightRule`s are the nested JSON) and is
/// authoritative on read; the other columns duplicate fields from it so
/// listing and ordering need no JSON parsing. Timestamps are UTC
/// milliseconds in `int` columns (drift's `dateTime()` would store seconds).
class SavedSquares extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get configJson => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The on-device SQLite database, schema version [currentSchemaVersion].
@DriftDatabase(tables: [SavedSquares])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The schema version (DATA-1). Raise it with a step in `migrationSteps`;
  /// the full procedure is in `docs/storage/schema-migrations.md`.
  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) => applyMigrations(m, from, to),
  );
}
