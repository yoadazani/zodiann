import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_storage/src/database/app_database.dart';
import 'package:shared_storage/src/database/migrations.dart';
import 'package:shared_storage/src/drift_square_store.dart';
import 'package:shared_storage/src/storage_exception.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v1.dart' show DatabaseAtV1;
import 'support/simulated_v2_database.dart';

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
      'unsupportedVersion and is left untouched', () async {
    final dir = Directory.systemTemp.createTempSync('zod_fnd006_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/future.sqlite');
    sqlite.sqlite3.open(file.path)
      ..execute('PRAGMA user_version = 2')
      ..close();
    final bytesBefore = file.readAsBytesSync();
    final listingBefore = _listing(dir);

    await expectLater(openSquareStore(file), _unsupported());

    expect(_userVersion(file), 2);
    expect(file.readAsBytesSync(), equals(bytesBefore));
    expect(_listing(dir), equals(listingBefore));
  });

  group('v1 to simulated v2 (ZOD-DAT-012)', () {
    final verifier = SchemaVerifier(GeneratedHelper());

    test('rows written at v1 survive the upgrade unchanged', () async {
      final schema = await verifier.schemaAt(1);
      for (final row in _v1Rows) {
        schema.rawDatabase.execute(_insertSql, row);
      }
      // rawDatabase backs newConnection: it must not be closed here.
      final upgraded = SimulatedV2Database(schema.newConnection());
      addTearDown(upgraded.close);

      await verifier.migrateAndValidate(upgraded, 2);

      expect(await _rowsOf(upgraded), [
        for (final row in _v1Rows)
          {
            'id': row[0],
            'name': row[1],
            'config_json': row[2],
            'created_at': row[3],
            'updated_at': row[4],
            'note': null,
          },
      ]);
    });

    test('the migrated schema has the nullable note column', () async {
      final schema = await verifier.schemaAt(1);
      final upgraded = SimulatedV2Database(schema.newConnection());
      addTearDown(upgraded.close);
      await verifier.migrateAndValidate(upgraded, 2);

      final info = await upgraded
          .customSelect("PRAGMA table_info('saved_squares')")
          .get();
      final note = info.singleWhere((r) => r.read<String>('name') == 'note');
      expect(note.read<int>('notnull'), 0);
      expect(note.read<String>('type'), 'TEXT');
    });

    test('an empty v1 database migrates', () async {
      final schema = await verifier.schemaAt(1);
      final upgraded = SimulatedV2Database(schema.newConnection());
      addTearDown(upgraded.close);

      await verifier.migrateAndValidate(upgraded, 2);

      expect(await _rowsOf(upgraded), isEmpty);
    });

    test(
      'a chain of steps runs every step once, in order, and keeps data',
      () async {
        final schema = await verifier.schemaAt(1);
        for (final row in _v1Rows) {
          schema.rawDatabase.execute(_insertSql, row);
        }
        final database = DatabaseAtV1(schema.newConnection());
        addTearDown(database.close);
        final ran = <int>[];

        await applyMigrations(
          database.createMigrator(),
          1,
          3,
          steps: {
            2: (m) async {
              ran.add(2);
              await m.database.customStatement(
                'ALTER TABLE saved_squares ADD COLUMN note TEXT',
              );
            },
            3: (m) async => ran.add(3),
          },
        );

        expect(ran, [2, 3]);
        final info = await database
            .customSelect("PRAGMA table_info('saved_squares')")
            .get();
        expect(info.map((r) => r.read<String>('name')), contains('note'));
        final kept = await _rowsOf(database);
        expect(kept.map((r) => r["id"]), _v1Rows.map((r) => r[0]));
        expect(kept.map((r) => r["config_json"]), _v1Rows.map((r) => r[2]));
      },
    );

    group('on a file', () {
      late Directory dir;
      late File file;
      setUp(() {
        dir = Directory.systemTemp.createTempSync('zod_dat012_');
        file = File('${dir.path}/squares.sqlite');
        _createV1File(file);
      });
      tearDown(() => dir.deleteSync(recursive: true));

      Map<int, MigrationStep> throwingAfter(MigrationStep step) => {
        2: (m) async {
          await step(m);
          throw StateError('boom');
        },
      };

      Future<void> openFails(Map<int, MigrationStep> steps) async {
        final db = SimulatedV2Database(NativeDatabase(file), steps: steps);
        await expectLater(
          db.customSelect('SELECT 1').get(),
          throwsA(isA<StateError>()),
        );
        try {
          await db.close();
        } on Object {
          // The database never finished opening; nothing more to release.
        }
      }

      void expectStillV1() {
        expect(_userVersion(file), 1);
        expect(_columns(file), isNot(contains('note')));
        expect(_rawRows(file).length, _v1Rows.length);
      }

      test('a step that throws leaves the file at v1 with its rows', () async {
        await openFails(throwingAfter(simulatedSteps[2]!));

        expectStillV1();
      });

      test('a failed upgrade can be retried with a corrected step', () async {
        await openFails(throwingAfter(simulatedSteps[2]!));

        final db = SimulatedV2Database(NativeDatabase(file));
        addTearDown(db.close);
        final rows = await _rowsOf(db);

        expect(rows.length, _v1Rows.length);
        expect(rows.first['note'], isNull);
        expect(_userVersion(file), 2);
      });

      MigrationStep alterTableStep() => (m) {
        final db = m.database as SimulatedV2Database;
        return m.alterTable(
          TableMigration(
            db.savedSquaresV2,
            newColumns: [db.savedSquaresV2.note],
          ),
        );
      };

      test(
        'Migrator.alterTable works inside the atomic range and keeps rows',
        () async {
          final db = SimulatedV2Database(
            NativeDatabase(file),
            steps: {2: alterTableStep()},
          );
          addTearDown(db.close);
          final rows = await _rowsOf(db);

          expect(rows.length, _v1Rows.length);
          expect(rows.first['note'], isNull);
          expect(rows.first['name'], _v1Rows.first[1]);
          expect(_columns(file), contains('note'));
          expect(_userVersion(file), 2);
        },
      );

      test(
        'a throw after Migrator.alterTable leaves the original table',
        () async {
          await openFails(throwingAfter(alterTableStep()));

          expectStillV1();
        },
      );
    });
  });
}

const _insertSql =
    'INSERT INTO saved_squares '
    '(id, name, config_json, created_at, updated_at) VALUES (?, ?, ?, ?, ?)';

const _v1Rows = <List<Object?>>[
  ['a1', 'Alpha', '{"id":"a1","name":"Alpha"}', 1000, 2000],
  ['b2', '׳‘׳“׳™׳§׳”', '{"id":"b2","name":"׳‘׳“׳™׳§׳”","size":9}', 1100, 2100],
  ['c3', 'Gamma "q"', '{"id":"c3","highlights":[{"n":3}]}', 1200, 2200],
];

Future<List<Map<String, Object?>>> _rowsOf(GeneratedDatabase db) async {
  final rows = await db
      .customSelect('SELECT * FROM saved_squares ORDER BY id')
      .get();
  return [for (final r in rows) Map<String, Object?>.of(r.data)];
}

/// Makes a schema version 1 database file with plain SQLite, using the DDL
/// from the committed v1 dump, independent of drift's own migration code.
void _createV1File(File file) {
  final raw = sqlite.sqlite3.open(file.path)
    ..execute(
      'CREATE TABLE "saved_squares" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, '
      '"config_json" TEXT NOT NULL, "created_at" INTEGER NOT NULL, '
      '"updated_at" INTEGER NOT NULL, PRIMARY KEY ("id"))',
    );
  for (final row in _v1Rows) {
    raw.execute(_insertSql, row);
  }
  raw
    ..execute('PRAGMA user_version = 1')
    ..close();
}

T _withRaw<T>(File file, T Function(sqlite.Database db) body) {
  final raw = sqlite.sqlite3.open(file.path);
  try {
    return body(raw);
  } finally {
    raw.close();
  }
}

int _userVersion(File file) => _withRaw(
  file,
  (db) => db.select('PRAGMA user_version').single.values.single! as int,
);

List<String> _columns(File file) => _withRaw(
  file,
  (db) => [
    for (final r in db.select("PRAGMA table_info('saved_squares')"))
      r['name'] as String,
  ],
);

List<Object?> _rawRows(File file) =>
    _withRaw(file, (db) => db.select('SELECT * FROM saved_squares').toList());

List<String> _listing(Directory dir) =>
    dir.listSync().map((e) => e.path).toList()..sort();
