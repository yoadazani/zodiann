/// Helpers for the ARCH-2 architecture tests: find Flutter SDK packages in a
/// package's dependency closure (from `dart pub deps --json`) and forbidden
/// imports in its sources.
library;

import 'dart:collection';
import 'dart:io';

/// Packages that only exist in the Flutter SDK. Reaching any of them means a
/// package (transitively) depends on Flutter.
const Set<String> flutterSdkPackages = {
  'flutter',
  'flutter_test',
  'sky_engine',
};

/// Returns each [forbidden] package reachable from [package], mapped to one
/// dependency path `[package, …, forbiddenName]`. Empty means clean.
///
/// Closure rule for pub-workspace output: [package]'s own node contributes its
/// `directDependencies` and `devDependencies` (only `directDependencies` when
/// [includeDevDependencies] is false: its runtime closure); every node
/// reached after that
/// contributes `directDependencies` only. A workspace member's `dependencies`
/// list also contains its dev dependencies, which are not part of a
/// dependent's closure, so it must not be followed. `pubDepsJson['root']` is
/// the workspace root, not necessarily [package], and is ignored.
///
/// Throws [ArgumentError] if [package] is not in `pubDepsJson['packages']`.
Map<String, List<String>> findForbiddenDependencies(
  Map<String, Object?> pubDepsJson,
  String package, {
  Set<String> forbidden = flutterSdkPackages,
  bool includeDevDependencies = true,
}) {
  final nodes = {
    for (final node
        in (pubDepsJson['packages'] as List<Object?>? ?? const [])
            .cast<Map<String, Object?>>())
      node['name'] as String: node,
  };
  final start = nodes[package];
  if (start == null) {
    throw ArgumentError.value(
      package,
      'package',
      'not found in `dart pub deps --json` output',
    );
  }

  List<String> listOf(Map<String, Object?>? node, String key) =>
      (node?[key] as List<Object?>? ?? const []).cast<String>();

  final hits = <String, List<String>>{};
  final visited = <String>{package};
  final queue = Queue<List<String>>.of([
    for (final dep in {
      ...listOf(start, 'directDependencies'),
      if (includeDevDependencies) ...listOf(start, 'devDependencies'),
    })
      [package, dep],
  ]);

  while (queue.isNotEmpty) {
    final path = queue.removeFirst();
    final name = path.last;
    if (!visited.add(name)) continue;
    if (forbidden.contains(name)) hits[name] = path;
    for (final dep in listOf(nodes[name], 'directDependencies')) {
      queue.add([...path, dep]);
    }
  }
  return hits;
}

/// An import/export statement (up to its `;`, possibly spanning lines) that
/// names `dart:ui` or a `package:flutter/` library anywhere — as its main URI
/// or as a conditional alternative (`if (dart.library.ui) 'dart:ui'`).
final _forbiddenImport = RegExp(
  r'''^\s*(import|export)\s[^;]*['"](dart:ui|package:flutter/)''',
  multiLine: true,
);

/// Returns the paths of `.dart` files under [libDir] (recursive) that import
/// or export `dart:ui` or any `package:flutter/` library, including as a
/// conditional-import alternative.
List<String> findForbiddenImports(Directory libDir) => [
  for (final entity in libDir.listSync(recursive: true))
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        _forbiddenImport.hasMatch(entity.readAsStringSync()))
      entity.path,
];
