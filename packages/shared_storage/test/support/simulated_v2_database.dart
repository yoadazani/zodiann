// Test-only database that simulates the shipped `AppDatabase` after one
// additive schema change (ZOD-DAT-012): the same `saved_squares` table plus a
// nullable `note` column, schema version 2. It exists to prove the migration
// framework without shipping a column nothing uses. The shipped schema stays at
// version 1.
import 'package:drift/drift.dart';
import 'package:shared_storage/src/database/migrations.dart';

part 'simulated_v2_database.g.dart';

/// `SavedSquares` (version 1) plus [note].
class SavedSquaresV2 extends Table {
  @override
  String get tableName => 'saved_squares';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get configJson => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The step that takes the schema from version 1 to the simulated version 2.
final Map<int, MigrationStep> simulatedSteps = {
  2: (m) {
    final db = m.database as SimulatedV2Database;
    return m.addColumn(db.savedSquaresV2, db.savedSquaresV2.note);
  },
};

@DriftDatabase(tables: [SavedSquaresV2])
class SimulatedV2Database extends _$SimulatedV2Database {
  /// [steps] defaults to [simulatedSteps]; tests inject a throwing or a
  /// corrected map.
  SimulatedV2Database(super.e, {Map<int, MigrationStep>? steps})
    : steps = steps ?? simulatedSteps;

  final Map<int, MigrationStep> steps;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) => applyMigrations(m, from, to, steps: steps),
  );
}
