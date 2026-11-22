import 'dart:async';

import 'storage_exception.dart';

/// Announces every storage failure on one broadcast stream, so the app layer
/// (ZOD-NFR-014's banner) hears about a failed save without each call site
/// catching it. A store reports a failure and then throws it.
final class StorageFailureReporter {
  final StreamController<StorageException> _controller =
      StreamController<StorageException>.broadcast();

  /// The failures, in the order they were reported.
  Stream<StorageException> get failures => _controller.stream;

  /// Announces [failure]. Does nothing after [dispose].
  void report(StorageException failure) {
    if (!_controller.isClosed) _controller.add(failure);
  }

  /// Closes the stream. Safe to call twice.
  void dispose() {
    if (!_controller.isClosed) unawaited(_controller.close());
  }
}
