import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:gann_core/gann_core.dart';

import 'database/app_database.dart';
import 'square_store.dart';
import 'storage_exception.dart';
import 'storage_failure_reporter.dart';

/// [SquareStore] over drift. Every failure is reported on [reporter] and
/// thrown as a [StorageException].
final class DriftSquareStore implements SquareStore {
  DriftSquareStore(this._db, {this.reporter});

  final AppDatabase _db;

  /// Where failures are announced before they are thrown; may be `null`.
  final StorageFailureReporter? reporter;

  final Set<String> _reportedCorrupt = {};

  @override
  Future<List<SquareConfig>> list() => _guard(() async {
    final rows =
        await (_db.select(_db.savedSquares)..orderBy([
              (t) => OrderingTerm.desc(t.updatedAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
            .get();
    final squares = <SquareConfig>[];
    for (final row in rows) {
      try {
        squares.add(_decode(row));
      } on StorageException catch (failure) {
        if (_reportedCorrupt.add(row.id)) reporter?.report(failure);
      }
    }
    return squares;
  });

  @override
  Future<SquareConfig?> get(String id) => _guard(() async {
    final row = await (_db.select(
      _db.savedSquares,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _decode(row);
  });

  @override
  Future<void> save(SquareConfig config) => _guard(() async {
    await _db
        .into(_db.savedSquares)
        .insertOnConflictUpdate(
          SavedSquaresCompanion.insert(
            id: config.id,
            name: config.name,
            configJson: jsonEncode(config.toJson()),
            createdAt: config.createdAt.millisecondsSinceEpoch,
            updatedAt: config.updatedAt.millisecondsSinceEpoch,
          ),
        );
  });

  @override
  Future<void> delete(String id) => _guard(() async {
    await (_db.delete(_db.savedSquares)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<void> deleteAll() => _guard(() async {
    await _db.delete(_db.savedSquares).go();
  });

  @override
  Future<void> close() => _db.close();

  SquareConfig _decode(SavedSquare row) {
    try {
      return SquareConfig.fromJson(jsonDecode(row.configJson));
    } on FormatException catch (error) {
      throw StorageException(
        StorageFailureKind.corrupt,
        'Saved square "${row.id}" cannot be read: ${error.message}',
        cause: error,
      );
    }
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error) {
      final failure = classifyStorageError(error);
      reporter?.report(failure);
      throw failure;
    }
  }
}

/// Opens (creating if needed) the saved-squares database at [file] on a
/// background isolate. The first statement runs here, so a file that cannot be
/// opened, is not a database, or was written by a newer schema fails **now**
/// with a [StorageException] (and is reported), not on a later call.
///
/// One writer per file is supported; `busy_timeout` makes an accidental
/// overlap wait instead of failing at once.
Future<SquareStore> openSquareStore(
  File file, {
  StorageFailureReporter? reporter,
}) async {
  final db = AppDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (raw) => raw.execute('PRAGMA busy_timeout = 5000;'),
    ),
  );
  try {
    await db.customSelect('SELECT 1').get();
  } on Object catch (error) {
    final failure = classifyStorageError(error);
    reporter?.report(failure);
    try {
      await db.close();
    } on Object {
      // The original failure is the one to surface.
    }
    throw failure;
  }
  return DriftSquareStore(db, reporter: reporter);
}
