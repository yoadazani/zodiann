// ZOD-FND-006 Task 1: proves the sqlite3 build hook loads under `flutter test`
// before any storage code exists. Deleted once Task 4's tests cover it.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('the bundled SQLite opens an in-memory database', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    expect(db.select('SELECT 1 AS one').single['one'], 1);
  });
}
