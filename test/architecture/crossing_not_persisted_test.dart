// ZOD-FND-012 AC: `Crossing` has no storage/persistence code path. Crossings
// are derived from the computation and recomputed, never saved (spec "Data
// model": Crossing — Saved? No; DATA-2). This guard fails if a storage layer
// starts referring to `Crossing`. Add new persistence packages to the list.
import 'dart:io';

import 'package:test/test.dart';

/// Persistence code lives behind `packages/shared_storage` (FND-006). Add any
/// future persistence package here.
const storageLayers = ['packages/shared_storage/lib'];

final _crossingIdentifier = RegExp(r'\bCrossing\b');

/// `.dart` files under [dirPath] that refer to the `Crossing` type. A
/// directory that does not exist yet has none.
List<String> filesReferencingCrossing(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return const [];
  return [
    for (final entity in dir.listSync(recursive: true))
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          _crossingIdentifier.hasMatch(entity.readAsStringSync()))
        entity.path,
  ];
}

void main() {
  test('scans exactly the persistence package, which must exist', () {
    // The app shell (apps/astro_mobile) is the composition root, not a
    // storage layer: it may legitimately route to or compute crossings.
    expect(storageLayers, ['packages/shared_storage/lib']);
    for (final layer in storageLayers) {
      expect(Directory(layer).existsSync(), isTrue, reason: layer);
    }
  });

  test('storage layers never reference Crossing', () {
    for (final layer in storageLayers) {
      expect(filesReferencingCrossing(layer), isEmpty, reason: layer);
    }
  });
}
