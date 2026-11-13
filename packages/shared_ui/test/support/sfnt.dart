// ZOD-FND-007 test support: just enough of the OpenType (sfnt) format to
// check the bundled fonts: the sfnt version, the cmap coverage, the OS/2
// weight class and the family name.
import 'dart:typed_data';

/// A parsed sfnt font file (TrueType outlines expected).
final class Sfnt {
  Sfnt(Uint8List bytes) : _data = ByteData.sublistView(bytes) {
    final tables = _data.getUint16(4);
    for (var i = 0; i < tables; i++) {
      final record = 12 + i * 16;
      final tag = String.fromCharCodes(
        Uint8List.sublistView(bytes, record, record + 4),
      );
      _tables[tag] = _data.getUint32(record + 8);
    }
  }

  final ByteData _data;
  final Map<String, int> _tables = {};

  int _table(String tag) =>
      _tables[tag] ?? (throw StateError('no $tag table in font'));

  /// Whether the sfnt version is 0x00010000 (TrueType outlines).
  bool get isTrueType => _data.getUint32(0) == 0x00010000;

  /// `OS/2.usWeightClass`.
  int get weightClass => _data.getUint16(_table('OS/2') + 4);

  /// The typographic family name (nameID 16), else the family name
  /// (nameID 1), from the Windows Unicode (3/1) records.
  String get familyName {
    final name = _table('name');
    final count = _data.getUint16(name + 2);
    final strings = name + _data.getUint16(name + 4);
    final found = <int, String>{};
    for (var i = 0; i < count; i++) {
      final r = name + 6 + i * 12;
      final platform = _data.getUint16(r);
      final encoding = _data.getUint16(r + 2);
      final id = _data.getUint16(r + 6);
      if (platform != 3 || encoding != 1 || (id != 1 && id != 16)) continue;
      final length = _data.getUint16(r + 8);
      final offset = strings + _data.getUint16(r + 10);
      found[id] = String.fromCharCodes([
        for (var j = 0; j < length; j += 2) _data.getUint16(offset + j),
      ]);
    }
    return found[16] ?? found[1] ?? (throw StateError('no family name'));
  }

  /// Code points that map to a non-zero glyph id in the platform 3 (or 0)
  /// cmap subtables of format 4 or 12.
  late final Set<int> codePoints = _codePoints();

  Set<int> _codePoints() {
    final cmap = _table('cmap');
    final result = <int>{};
    final count = _data.getUint16(cmap + 2);
    for (var i = 0; i < count; i++) {
      final r = cmap + 4 + i * 8;
      final platform = _data.getUint16(r);
      if (platform != 3 && platform != 0) continue;
      final sub = cmap + _data.getUint32(r + 4);
      switch (_data.getUint16(sub)) {
        case 4:
          _format4(sub, result);
        case 12:
          _format12(sub, result);
      }
    }
    return result;
  }

  void _format4(int sub, Set<int> out) {
    final segments = _data.getUint16(sub + 6) ~/ 2;
    final ends = sub + 14;
    final starts = ends + segments * 2 + 2;
    final deltas = starts + segments * 2;
    final rangeOffsets = deltas + segments * 2;
    for (var s = 0; s < segments; s++) {
      final end = _data.getUint16(ends + s * 2);
      final start = _data.getUint16(starts + s * 2);
      final delta = _data.getInt16(deltas + s * 2);
      final rangeOffsetAt = rangeOffsets + s * 2;
      final rangeOffset = _data.getUint16(rangeOffsetAt);
      for (var c = start; c <= end; c++) {
        if (c == 0xFFFF) break;
        int glyph;
        if (rangeOffset == 0) {
          glyph = (c + delta) & 0xFFFF;
        } else {
          glyph = _data.getUint16(
            rangeOffsetAt + rangeOffset + (c - start) * 2,
          );
          if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
        }
        if (glyph != 0) out.add(c);
      }
    }
  }

  void _format12(int sub, Set<int> out) {
    final groups = _data.getUint32(sub + 12);
    for (var g = 0; g < groups; g++) {
      final p = sub + 16 + g * 12;
      final start = _data.getUint32(p);
      final end = _data.getUint32(p + 4);
      final firstGlyph = _data.getUint32(p + 8);
      for (var c = start; c <= end; c++) {
        if (firstGlyph + (c - start) != 0) out.add(c);
      }
    }
  }
}
