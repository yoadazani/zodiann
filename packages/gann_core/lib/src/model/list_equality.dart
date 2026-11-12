/// Internal element-wise list equality and hashing for the data model's
/// value types (avoids a dependency on package:collection).
library;

bool listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int listHash<T>(List<T> list) => Object.hashAll(list);
