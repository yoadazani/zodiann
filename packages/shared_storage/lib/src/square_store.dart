import 'package:gann_core/gann_core.dart';

/// Storage for saved squares (DATA-1, DATA-2). Feature code depends on this
/// interface, never on drift.
///
/// Every method throws a `StorageException` when storage fails. The 100-square
/// limit (DATA-2) is the save flow's rule (ZOD-DAT-002), not this store's.
abstract interface class SquareStore {
  /// Every readable saved square, newest `updatedAt` first, then by id. A row
  /// that cannot be read is skipped and reported, so one bad row never hides
  /// the others.
  Future<List<SquareConfig>> list();

  /// The square with [id], `null` if none, or `StorageException(corrupt)` if
  /// its row cannot be read.
  Future<SquareConfig?> get(String id);

  /// Inserts [config], or replaces the square with the same id. Nothing is
  /// changed if the write fails.
  Future<void> save(SquareConfig config);

  /// Deletes the square with [id]; does nothing if there is none.
  Future<void> delete(String id);

  /// Deletes every saved square.
  Future<void> deleteAll();

  /// Releases the database. The store is unusable afterwards.
  Future<void> close();
}
