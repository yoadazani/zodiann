import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_storage/src/database/app_database.dart';
import 'package:shared_storage/src/database/migrations.dart';

/// Guards that keep the committed schema dumps and the step table in step with
/// `AppDatabase.currentSchemaVersion` (ZOD-DAT-012). The process they protect
/// is in `docs/storage/schema-migrations.md`.

const _dumpDir = 'drift_schemas';
const _testDumpDir = 'test/schemas';

String _normalise(String sql) => sql
    .replaceAll(' IF NOT EXISTS', '')
    .replaceAll(';', '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

void main() {
  test(
    'the committed dump of the current version matches the live schema',
    () async {
      final version = AppDatabase.currentSchemaVersion;
      final dump = jsonDecode(
        File('$_dumpDir/drift_schema_v$version.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final dumped = <String, String>{
        for (final entry in dump['fixed_sql'] as List<dynamic>)
          (entry as Map<String, dynamic>)['name'] as String: _normalise(
            ((entry['sql'] as List<dynamic>).single
                    as Map<String, dynamic>)['sql']
                as String,
          ),
      };

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final rows = await db
          .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE type IN ('table', 'index') "
            "AND name NOT LIKE 'sqlite_%' AND sql IS NOT NULL",
          )
          .get();
      final live = <String, String>{
        for (final row in rows)
          row.read<String>('name'): _normalise(row.read<String>('sql')),
      };

      expect(live, equals(dumped));
    },
  );

  test('the dump versions are exactly 1 to currentSchemaVersion', () {
    final found = <int>{
      for (final file in Directory(_dumpDir).listSync().whereType<File>())
        if (RegExp(r'drift_schema_v(\d+)\.json$').firstMatch(file.path)
            case final match?)
          int.parse(match.group(1)!),
    };
    expect(
      found,
      equals(<int>{
        for (var v = 1; v <= AppDatabase.currentSchemaVersion; v++) v,
      }),
    );
  });

  test('migrationSteps has exactly the keys 2..currentSchemaVersion', () {
    expect(
      migrationSteps.keys.toSet(),
      equals(<int>{
        for (var v = 2; v <= AppDatabase.currentSchemaVersion; v++) v,
      }),
    );
  });

  test('the test copy of the v1 dump equals the real one', () {
    expect(
      File('$_testDumpDir/drift_schema_v1.json').readAsBytesSync(),
      equals(File('$_dumpDir/drift_schema_v1.json').readAsBytesSync()),
    );
  });
}
