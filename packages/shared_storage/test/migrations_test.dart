import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_storage/src/database/app_database.dart';
import 'package:shared_storage/src/database/migrations.dart';
import 'package:shared_storage/src/drift_square_store.dart';
import 'package:shared_storage/src/storage_exception.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<void> _noStep(Migrator m) async {}

Matcher _unsupported() => throwsA(
  isA<StorageException>().having(
    (e) => e.kind,
    'kind',
    StorageFailureKind.unsupportedVersion,
  ),
);

void main() {
  // The store test below opens a second database on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('schemaVersion is 1', () {
    expect(db.schemaVersion, 1);
    expect(AppDatabase.currentSchemaVersion, 1);
  });

  test('from equal to to applies nothing', () async {
    var ran = false;
    await applyMigrations(
      db.createMigrator(),
      1,
      1,
      steps: {1: (m) async => ran = true, 2: (m) async => ran = true},
    );
    expect(ran, isFalse);
  });

  test('the shipped step table is empty at schema 1', () {
    expect(migrationSteps, isEmpty);
  });

  test('a missing step throws unsupportedVersion', () async {
    await expectLater(
      applyMigrations(db.createMigrator(), 1, 2, steps: const {}),
      _unsupported(),
    );
  });

  test('from greater than to throws unsupportedVersion', () async {
    await expectLater(
      applyMigrations(db.createMigrator(), 2, 1, steps: const {}),
      _unsupported(),
    );
  });

  test('steps run in ascending order and only those after from', () async {
    final ran = <int>[];
    await applyMigrations(
      db.createMigrator(),
      2,
      4,
      steps: {
        4: (m) async => ran.add(4),
        2: (m) async => ran.add(2),
        3: (m) async => ran.add(3),
        1: _noStep,
      },
    );
    expect(ran, [3, 4]);
  });

  test('a file at user_version 2 reopened through the store throws '
      'unsupportedVersion', () async {
    final dir = Directory.systemTemp.createTempSync('zod_fnd006_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/future.sqlite');
    sqlite.sqlite3.open(file.path)
      ..execute('PRAGMA user_version = 2')
      ..close();

    await expectLater(openSquareStore(file), _unsupported());
  });
}
