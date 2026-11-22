import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gann_core/gann_core.dart';
import 'package:shared_storage/src/database/app_database.dart';
import 'package:shared_storage/src/drift_square_store.dart';
import 'package:shared_storage/src/storage_exception.dart';
import 'package:shared_storage/src/storage_failure_reporter.dart';

DateTime _utc(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

SquareConfig _config(
  String id, {
  String name = 'Square',
  SquareMode mode = SquareMode.dates,
  int updated = 2000,
  int created = 1000,
  int size = 9,
  int stepHours = 4,
  List<HighlightRule>? highlights,
}) {
  return SquareConfig(
    id: id,
    name: name,
    mode: mode,
    anchor: mode == SquareMode.numbers
        ? null
        : OffsetDateTime(DateTime.utc(2026, 3, 29, 1, 30), 120),
    stepHours: stepHours,
    size: size,
    spiralStart: SpiralStart.up,
    spiralRotation: SpiralRotation.ccw,
    highlights: highlights,
    createdAt: _utc(created),
    updatedAt: _utc(updated),
  );
}

/// Fails chosen operations with a SQLite error.
class _Failing extends QueryInterceptor {
  int? writeCode;
  int? openCode;

  void _write() {
    final code = writeCode;
    if (code != null) {
      throw SqliteException(extendedResultCode: code, message: 'injected');
    }
  }

  @override
  Future<bool> ensureOpen(QueryExecutor executor, QueryExecutorUser user) {
    final code = openCode;
    if (code != null) {
      throw SqliteException(extendedResultCode: code, message: 'injected');
    }
    return super.ensureOpen(executor, user);
  }

  @override
  Future<int> runInsert(QueryExecutor e, String s, List<Object?> a) {
    _write();
    return super.runInsert(e, s, a);
  }

  @override
  Future<int> runUpdate(QueryExecutor e, String s, List<Object?> a) {
    _write();
    return super.runUpdate(e, s, a);
  }

  @override
  Future<int> runDelete(QueryExecutor e, String s, List<Object?> a) {
    _write();
    return super.runDelete(e, s, a);
  }
}

Matcher _kind(StorageFailureKind kind) =>
    throwsA(isA<StorageException>().having((e) => e.kind, 'kind', kind));

void main() {
  // Several short-lived databases per file is deliberate in these tests.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftSquareStore store;
  late StorageFailureReporter reporter;
  late List<StorageException> reported;

  setUp(() {
    reporter = StorageFailureReporter();
    reported = [];
    reporter.failures.listen(reported.add);
    db = AppDatabase(NativeDatabase.memory());
    store = DriftSquareStore(db, reporter: reporter);
  });
  tearDown(() async {
    await store.close();
    reporter.dispose();
  });

  group('round trip', () {
    test('round-trips a SquareConfig with all fields', () async {
      for (final mode in SquareMode.values) {
        final config = _config(
          'id-${mode.name}',
          mode: mode,
          stepHours: 6,
          size: 15,
          highlights: [
            HighlightRule(
              id: 'a',
              label: 'Angles',
              match: AnglesMatch([10.5, 90]),
              colorToken: 'axis',
              priority: 4,
            ),
            HighlightRule(
              id: 'm',
              label: 'שלום',
              match: MultipleOfMatch(7.5),
              colorToken: 'eighth',
              priority: 1,
            ),
          ],
        );
        await store.save(config);
        final read = await store.get(config.id);
        expect(read, config);
        expect(read!.anchor?.offsetMinutes, config.anchor?.offsetMinutes);
      }
    });

    test('the default highlight rules round-trip', () async {
      await store.save(_config('d'));
      expect((await store.get('d'))!.highlights, defaultHighlightRules);
    });

    test('a negative offset survives', () async {
      final config = SquareConfig(
        id: 'neg',
        name: 'West',
        mode: SquareMode.datetime,
        anchor: OffsetDateTime(DateTime.utc(2026, 11, 1, 5), -300),
        size: 9,
        createdAt: _utc(1),
        updatedAt: _utc(2),
      );
      await store.save(config);
      expect((await store.get('neg'))!.anchor!.offsetMinutes, -300);
    });

    test('table columns agree with the JSON', () async {
      final config = _config('c', name: 'Named', created: 1234, updated: 5678);
      await store.save(config);
      final row = await db.select(db.savedSquares).getSingle();
      expect(row.id, 'c');
      expect(row.name, 'Named');
      expect(row.createdAt, 1234);
      expect(row.updatedAt, 5678);
    });
  });

  group('list, get, save, delete', () {
    test('save with an existing id replaces the row', () async {
      await store.save(_config('x', name: 'One'));
      await store.save(_config('x', name: 'Two', updated: 3000));
      final all = await store.list();
      expect(all, hasLength(1));
      expect(all.single.name, 'Two');
    });

    test('list is ordered by updatedAt descending, then id', () async {
      await store.save(_config('b', updated: 2000));
      await store.save(_config('a', updated: 2000));
      await store.save(_config('c', updated: 9000));
      expect([for (final s in await store.list()) s.id], ['c', 'a', 'b']);
    });

    test('two squares updated one millisecond apart order correctly', () async {
      await store.save(_config('early', updated: 5000));
      await store.save(_config('late', updated: 5001));
      expect([for (final s in await store.list()) s.id], ['late', 'early']);
    });

    test('get of an unknown id is null', () async {
      expect(await store.get('nope'), isNull);
    });

    test('delete removes only that row', () async {
      await store.save(_config('a'));
      await store.save(_config('b'));
      await store.delete('a');
      expect([for (final s in await store.list()) s.id], ['b']);
    });

    test('deleteAll removes every row', () async {
      await store.save(_config('a'));
      await store.save(_config('b'));
      await store.deleteAll();
      expect(await store.list(), isEmpty);
    });
  });

  group('corrupt rows', () {
    Future<void> insertBad(String id) => db
        .into(db.savedSquares)
        .insert(
          SavedSquaresCompanion.insert(
            id: id,
            name: 'bad',
            configJson: '{not json',
            createdAt: 1,
            updatedAt: 99999,
          ),
        );

    test('a corrupt config_json is skipped by list and reported', () async {
      await store.save(_config('good'));
      await insertBad('bad');
      final all = await store.list();
      expect([for (final s in all) s.id], ['good']);
      await Future<void>.delayed(Duration.zero);
      expect(reported.single.kind, StorageFailureKind.corrupt);
    });

    test('get of a corrupt row throws corrupt', () async {
      await insertBad('bad');
      await expectLater(store.get('bad'), _kind(StorageFailureKind.corrupt));
    });

    test('a corrupt id is reported once per store lifetime', () async {
      await insertBad('bad');
      await store.list();
      await store.list();
      await Future<void>.delayed(Duration.zero);
      expect(reported, hasLength(1));
    });
  });

  group('failures', () {
    late _Failing failing;
    setUp(() async {
      await store.close();
      failing = _Failing();
      db = AppDatabase(NativeDatabase.memory().interceptWith(failing));
      store = DriftSquareStore(db, reporter: reporter);
    });

    test(
      'a full disk throws full, reports it and keeps the old rows',
      () async {
        await store.save(_config('keep', name: 'Old'));
        failing.writeCode = 13;
        await expectLater(
          store.save(_config('keep', name: 'New', updated: 7000)),
          _kind(StorageFailureKind.full),
        );
        await expectLater(
          store.save(_config('other')),
          _kind(StorageFailureKind.full),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          reported.map((e) => e.kind),
          everyElement(StorageFailureKind.full),
        );
        expect(reported, hasLength(2));
        failing.writeCode = null;
        final all = await store.list();
        expect(all, hasLength(1));
        expect(all.single.name, 'Old');
      },
    );

    test('a failing delete keeps the row', () async {
      await store.save(_config('keep'));
      failing.writeCode = 8;
      await expectLater(
        store.delete('keep'),
        _kind(StorageFailureKind.unavailable),
      );
      failing.writeCode = null;
      expect(await store.get('keep'), isNotNull);
    });

    test('blocked storage on open throws unavailable', () async {
      await store.close();
      failing.openCode = 14;
      db = AppDatabase(NativeDatabase.memory().interceptWith(failing));
      store = DriftSquareStore(db, reporter: reporter);
      await expectLater(store.list(), _kind(StorageFailureKind.unavailable));
    });
  });

  group('files', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('zod_fnd006_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('a reopened file returns the saved rows', () async {
      final file = File('${dir.path}/squares.sqlite');
      final first = await openSquareStore(file);
      await first.save(_config('kept', name: 'Persisted'));
      await first.close();

      final second = await openSquareStore(file);
      addTearDown(second.close);
      final all = await second.list();
      expect(all.single.name, 'Persisted');
      // Saving again after a reopen still works (no second creation).
      await second.save(_config('more'));
      expect(await second.list(), hasLength(2));
    });

    test('a file of garbage bytes throws StorageException corrupt', () async {
      final file = File('${dir.path}/garbage.sqlite')
        ..writeAsBytesSync(List<int>.generate(4096, (i) => (i * 37) & 0xFF));
      await expectLater(
        openSquareStore(file, reporter: reporter),
        _kind(StorageFailureKind.corrupt),
      );
      await Future<void>.delayed(Duration.zero);
      expect(reported.last.kind, StorageFailureKind.corrupt);
    });

    test('a path that cannot be opened throws unavailable', () async {
      // The directory itself is not a database file.
      await expectLater(
        openSquareStore(File(dir.path)),
        _kind(StorageFailureKind.unavailable),
      );
    });
  });
}
