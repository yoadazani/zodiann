import 'dart:io';

/// The repository root: the nearest ancestor of the working directory that
/// holds `packages/`, so file-reading tests pass from the repo root and under
/// `melos run test` (which runs from the package directory).
Directory repoRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (Directory('${dir.path}/packages/feature_wheel').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('No repository root above ${Directory.current.path}');
    }
    dir = parent;
  }
}
