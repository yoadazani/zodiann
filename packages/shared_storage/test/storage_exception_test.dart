import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_storage/src/storage_exception.dart';
import 'package:shared_storage/src/storage_failure_reporter.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

SqliteException _sqlite(int code) =>
    SqliteException(extendedResultCode: code, message: 'code $code');

StorageFailureKind _kind(Object error) => classifyStorageError(error).kind;

void main() {
  group('classifyStorageError', () {
    test('classifies SQLITE_FULL as full', () {
      expect(_kind(_sqlite(13)), StorageFailureKind.full);
    });

    for (final (name, code) in [
      ('SQLITE_READONLY', 8),
      ('SQLITE_CANTOPEN', 14),
      ('SQLITE_IOERR', 10),
      ('SQLITE_PERM', 3),
      ('SQLITE_BUSY', 5),
      ('SQLITE_LOCKED', 6),
    ]) {
      test('classifies $name as unavailable', () {
        expect(_kind(_sqlite(code)), StorageFailureKind.unavailable);
      });
    }

    for (final (name, code) in [
      ('SQLITE_CORRUPT', 11),
      ('SQLITE_NOTADB', 26),
    ]) {
      test('classifies $name as corrupt', () {
        expect(_kind(_sqlite(code)), StorageFailureKind.corrupt);
      });
    }

    test('SQLITE_IOERR_WRITE (778) is unavailable, by its primary code', () {
      expect(_kind(_sqlite(778)), StorageFailureKind.unavailable);
    });

    test('SQLITE_CORRUPT_INDEX (779) is corrupt, by its primary code', () {
      expect(_kind(_sqlite(779)), StorageFailureKind.corrupt);
    });

    test('a wrapped SqliteException is unwrapped before classifying', () {
      final wrapped = DriftWrappedException(message: 'm', cause: _sqlite(13));
      expect(_kind(wrapped), StorageFailureKind.full);
    });

    test('an unknown error is unavailable', () {
      expect(_kind(StateError('x')), StorageFailureKind.unavailable);
      expect(_kind(_sqlite(1)), StorageFailureKind.unavailable);
    });

    test('keeps the original error as the cause', () {
      final error = _sqlite(13);
      expect(classifyStorageError(error).cause, same(error));
    });

    test('an existing StorageException passes through unchanged', () {
      final existing = StorageException(StorageFailureKind.corrupt, 'bad');
      expect(classifyStorageError(existing), same(existing));
    });
  });

  group('StorageFailureReporter', () {
    test('delivers to every listener', () async {
      final reporter = StorageFailureReporter();
      final a = <StorageException>[];
      final b = <StorageException>[];
      reporter.failures.listen(a.add);
      reporter.failures.listen(b.add);
      final failure = StorageException(StorageFailureKind.full, 'disk full');
      reporter.report(failure);
      await Future<void>.delayed(Duration.zero);
      expect(a, [failure]);
      expect(b, [failure]);
      reporter.dispose();
    });

    test('report after dispose does nothing', () {
      final reporter = StorageFailureReporter()..dispose();
      expect(
        () => reporter.report(StorageException(StorageFailureKind.full, 'x')),
        returnsNormally,
      );
    });

    test('dispose can be called twice', () {
      final reporter = StorageFailureReporter()..dispose();
      expect(reporter.dispose, returnsNormally);
    });
  });

  test('toString names the kind and the message', () {
    final text = StorageException(
      StorageFailureKind.full,
      'disk full',
    ).toString();
    expect(text, contains('full'));
    expect(text, contains('disk full'));
  });
}
