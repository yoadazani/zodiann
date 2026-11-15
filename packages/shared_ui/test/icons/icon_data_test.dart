// ZOD-FND-009: the runtime icon model's value semantics and the generated
// icon table.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/src/icons/zodiann_icon_data.dart';
import 'package:shared_ui/src/icons/zodiann_icons.g.dart';

const _stroke = ZodiannIconPaint(
  stroke: ZodiannIconStroke(1.6, StrokeCap.round, StrokeJoin.round),
);

void _expectEqual(Object a, Object b) {
  expect(a, b);
  expect(a.hashCode, b.hashCode);
}

void main() {
  group('value equality', () {
    test('commands', () {
      _expectEqual(const IconMoveTo(1, 2), const IconMoveTo(1, 2));
      _expectEqual(const IconLineTo(1, 2), const IconLineTo(1, 2));
      _expectEqual(
        const IconCubicTo(1, 2, 3, 4, 5, 6),
        const IconCubicTo(1, 2, 3, 4, 5, 6),
      );
      _expectEqual(
        const IconArcTo(1, 2, 3, 4, 0, true, false),
        const IconArcTo(1, 2, 3, 4, 0, true, false),
      );
      _expectEqual(const IconClose(), const IconClose());
      expect(const IconMoveTo(1, 2), isNot(const IconMoveTo(1, 3)));
      expect(const IconMoveTo(1, 2), isNot(const IconLineTo(1, 2)));
      expect(
        const IconCubicTo(1, 2, 3, 4, 5, 6),
        isNot(const IconCubicTo(1, 2, 3, 4, 5, 7)),
      );
      expect(
        const IconArcTo(1, 2, 3, 4, 0, true, false),
        isNot(const IconArcTo(1, 2, 3, 4, 0, false, false)),
      );
      expect(
        const IconArcTo(1, 2, 3, 4, 0, true, false),
        isNot(const IconArcTo(1, 2, 3, 4, 0, true, true)),
      );
    });

    test('paint and stroke', () {
      _expectEqual(
        _stroke,
        const ZodiannIconPaint(
          stroke: ZodiannIconStroke(1.6, StrokeCap.round, StrokeJoin.round),
        ),
      );
      expect(_stroke, isNot(const ZodiannIconPaint(fill: true)));
      expect(
        const ZodiannIconStroke(1.6, StrokeCap.round, StrokeJoin.round),
        isNot(const ZodiannIconStroke(1.6, StrokeCap.butt, StrokeJoin.round)),
      );
      expect(
        const ZodiannIconStroke(1.6, StrokeCap.round, StrokeJoin.round),
        isNot(const ZodiannIconStroke(1.6, StrokeCap.round, StrokeJoin.miter)),
      );
      expect(const ZodiannIconPaint().fill, isFalse);
      expect(const ZodiannIconPaint().stroke, isNull);
    });

    test('shapes', () {
      _expectEqual(
        const ZodiannIconPath([IconMoveTo(1, 2)], _stroke),
        const ZodiannIconPath([IconMoveTo(1, 2)], _stroke),
      );
      _expectEqual(
        const ZodiannIconCircle(1, 2, 3, _stroke),
        const ZodiannIconCircle(1, 2, 3, _stroke),
      );
      _expectEqual(
        const ZodiannIconRect(1, 2, 3, 4, 5, 6, _stroke),
        const ZodiannIconRect(1, 2, 3, 4, 5, 6, _stroke),
      );
      expect(
        const ZodiannIconPath([IconMoveTo(1, 2)], _stroke),
        isNot(const ZodiannIconPath([IconMoveTo(1, 2), IconClose()], _stroke)),
      );
      expect(
        const ZodiannIconCircle(1, 2, 3, _stroke),
        isNot(const ZodiannIconCircle(1, 2, 3, ZodiannIconPaint(fill: true))),
      );
      expect(
        const ZodiannIconRect(1, 2, 3, 4, 5, 6, _stroke),
        isNot(const ZodiannIconRect(1, 2, 3, 4, 5, 7, _stroke)),
      );
    });

    test('icon data', () {
      _expectEqual(
        const ZodiannIconData(
          name: 'a',
          viewBoxWidth: 24,
          viewBoxHeight: 24,
          shapes: [ZodiannIconCircle(1, 2, 3, _stroke)],
        ),
        const ZodiannIconData(
          name: 'a',
          viewBoxWidth: 24,
          viewBoxHeight: 24,
          shapes: [ZodiannIconCircle(1, 2, 3, _stroke)],
        ),
      );
      expect(
        const ZodiannIconData(
          name: 'a',
          viewBoxWidth: 24,
          viewBoxHeight: 24,
          shapes: [],
        ),
        isNot(
          const ZodiannIconData(
            name: 'b',
            viewBoxWidth: 24,
            viewBoxHeight: 24,
            shapes: [],
          ),
        ),
      );
    });
  });

  test('ZodiannIcons.values: 33 distinct icons in name order', () {
    final names = [for (final icon in ZodiannIcons.values) icon.name];
    expect(names, hasLength(33));
    expect(names.toSet(), hasLength(33));
    final sorted = [...names]..sort();
    expect(names, sorted);
    expect(ZodiannIcons.values.first, same(ZodiannIcons.alert));
    expect(ZodiannIcons.chevL.name, 'chevL');
    expect(ZodiannIcons.values.toSet(), hasLength(33));
  });
}
