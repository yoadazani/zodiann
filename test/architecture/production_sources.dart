// Shared by the ZOD-FND-011 guards (node_bypass.dart, port_binding.dart):
// which files are production code, and one spelling for their paths.
import 'dart:io';

/// [path] relative to [root], with `/` separators and no leading `./`.
///
/// `File.path` uses backslashes on Windows and the root may be `.` or a
/// temporary directory, so every comparison (the allowlists, the binding
/// declaration file, the lib-directory pattern) goes through this one spelling.
String normalizeScanPath(String path, {String root = '.'}) {
  var p = path.replaceAll(r'\', '/');
  final r = root.replaceAll(r'\', '/');
  if (r.isNotEmpty && r != '.') {
    final prefix = r.endsWith('/') ? r : '$r/';
    if (p.startsWith(prefix)) p = p.substring(prefix.length);
  }
  while (p.startsWith('./')) {
    p = p.substring(2);
  }
  return p;
}

final _productionPath = RegExp(r'^(apps|packages)/[^/]+/lib/.+\.dart$');

/// Whether the normalised [path] is production code: a `.dart` file under
/// `apps/*/lib` or `packages/*/lib`. Tests, integration tests, tools and
/// build hooks are not production.
bool isProductionPath(String path) => _productionPath.hasMatch(path);

/// Every production `.dart` file under [root]: normalised path to its text.
Map<String, String> productionSources(Directory root) {
  final out = <String, String>{};
  for (final top in ['apps', 'packages']) {
    final dir = Directory('${root.path}${Platform.pathSeparator}$top');
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final path = normalizeScanPath(entity.path, root: root.path);
      if (isProductionPath(path)) out[path] = entity.readAsStringSync();
    }
  }
  return out;
}
