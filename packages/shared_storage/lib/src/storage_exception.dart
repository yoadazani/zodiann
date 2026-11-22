import 'package:drift/drift.dart' show DriftWrappedException;
// The only public home of DriftRemoteException, which carries errors out of
// drift's background isolate (see classifyStorageError).
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// Why a storage operation failed (NFR-R1).
enum StorageFailureKind {
  /// The storage cannot be opened, read or written: blocked, read-only, no
  /// permission, an I/O error or a lock that did not clear.
  unavailable,

  /// The device is out of space.
  full,

  /// Stored data is unreadable: a damaged file or a value of the wrong type.
  corrupt,

  /// The database file was written by a newer schema than this app knows.
  unsupportedVersion,
}

/// The one error type the storage stores throw. It is typed so a caller (and
/// the banner, ZOD-NFR-014) can tell the failures apart without catching
/// platform exceptions.
final class StorageException implements Exception {
  /// Creates a failure of [kind]. [cause] is the original error, if any.
  StorageException(this.kind, this.message, {this.cause});

  final StorageFailureKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'StorageException(${kind.name}): $message';
}

// SQLite primary result codes (https://sqlite.org/rescode.html).
const _sqlitePerm = 3;
const _sqliteBusy = 5;
const _sqliteLocked = 6;
const _sqliteReadonly = 8;
const _sqliteIoerr = 10;
const _sqliteCorrupt = 11;
const _sqliteFull = 13;
const _sqliteCantopen = 14;
const _sqliteNotadb = 26;

/// Translates any error from the storage layer to a [StorageException].
///
/// Drift's background isolate delivers the real error wrapped in a
/// [DriftRemoteException] (and drift itself wraps some in a
/// [DriftWrappedException]); both are unwrapped first. A [SqliteException] is
/// classified by its **primary** result code, so extended codes such as
/// `SQLITE_IOERR_WRITE` (778) map like their primary code. Anything unknown is
/// [StorageFailureKind.unavailable]. An existing [StorageException] is
/// returned as is.
StorageException classifyStorageError(Object error) {
  var inner = error;
  for (var depth = 0; depth < 8; depth++) {
    if (inner is DriftRemoteException) {
      inner = inner.remoteCause;
    } else if (inner is DriftWrappedException && inner.cause != null) {
      inner = inner.cause!;
    } else {
      break;
    }
  }
  if (inner is StorageException) return inner;
  if (inner is SqliteException) {
    final kind = switch (inner.resultCode) {
      _sqliteFull => StorageFailureKind.full,
      _sqliteCorrupt || _sqliteNotadb => StorageFailureKind.corrupt,
      _sqliteReadonly ||
      _sqliteCantopen ||
      _sqliteIoerr ||
      _sqlitePerm ||
      _sqliteBusy ||
      _sqliteLocked => StorageFailureKind.unavailable,
      _ => StorageFailureKind.unavailable,
    };
    return StorageException(kind, inner.message, cause: error);
  }
  return StorageException(
    StorageFailureKind.unavailable,
    inner.toString(),
    cause: error,
  );
}
