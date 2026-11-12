// ZOD-UI-001 test harness: the MASTER.md §2 colour tokens as a swatch grid,
// laid out like the design reference's "Colour tokens" section
// (design-reference/zodiann/_source/components.html, lines 13–21, 49, 64–73),
// plus the tokens that section does not show. Test-only: the component
// gallery is ZOD-UI-015. Labels are literal English (not app UI, so L-8 does
// not apply).
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// The swatch grid for the ambient theme's tokens.
class TokenSwatchGrid extends StatelessWidget {
  const TokenSwatchGrid({super.key});

  static const _sections = <(String, int, List<String>)>[
    (
      'Surfaces and text',
      8,
      [
        'bg',
        'bg-raised',
        'surface',
        'surface-2',
        'surface-3',
        'line',
        'text',
        'text-2',
      ],
    ),
    (
      'Brand and state',
      8,
      [
        'accent',
        'accent-line',
        'text-3',
        'focus',
        'danger',
        'ok',
        'line-soft',
        'on-accent',
      ],
    ),
    (
      'Square of Nine roles',
      8,
      [
        'axis-fill',
        'axis',
        'diag-fill',
        'diag',
        'eighth-fill',
        'today',
        'center',
        'sel-outer',
      ],
    ),
    (
      'Elements and aspects',
      8,
      [
        'fire',
        'earth',
        'air',
        'water',
        'asp-conj',
        'asp-soft',
        'asp-hard',
        'cell-fill',
      ],
    ),
    (
      'Bodies',
      11,
      [
        'sun',
        'moon',
        'mercury',
        'venus',
        'mars',
        'jupiter',
        'saturn',
        'uranus',
        'neptune',
        'pluto',
        'node',
      ],
    ),
    (
      'Not in the reference grid',
      8,
      [
        'accent-strong',
        'accent-soft',
        'scrim',
        'axis-ink',
        'diag-ink',
        'eighth-ink',
        'cell-ink',
        'cell-line',
        'sel-inner',
      ],
    ),
  ];

  static const _bodyLabels = {
    'sun': 'Sun',
    'moon': 'Moon',
    'mercury': 'Mercury',
    'venus': 'Venus',
    'mars': 'Mars',
    'jupiter': 'Jupiter',
    'saturn': 'Saturn',
    'uranus': 'Uranus',
    'neptune': 'Neptune',
    'pluto': 'Pluto',
    'node': 'Mean node',
  };

  static const _gap = 12.0;

  /// `#RRGGBB` for opaque colours, `rgba(r, g, b, .aa)` otherwise — the
  /// reference's own value text.
  static String valueText(Color c) {
    int ch(double v) => (v * 255).round();
    if (c.a == 1) {
      final rgb = c.toARGB32() & 0xFFFFFF;
      return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
    }
    final alpha = c.a.toStringAsFixed(2).replaceFirst(RegExp('^0'), '');
    return 'rgba(${ch(c.r)}, ${ch(c.g)}, ${ch(c.b)}, $alpha)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final colors = <String, Color>{
      ...s.tokens,
      ...theme.extension<SquareColors>()!.tokens,
      ...theme.extension<ZodiacColors>()!.tokens,
      ...theme.extension<AspectColors>()!.tokens,
      ...theme.extension<BodyColors>()!.tokens,
    };

    return RepaintBoundary(
      key: const Key('swatch-grid'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: s.surface,
          border: Border.all(color: s.lineSoft),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (title, columns, tokens) in _sections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        key: const Key('swatch-section-title'),
                        style: TextStyle(color: s.text2, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width =
                              (constraints.maxWidth - _gap * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: _gap,
                            runSpacing: _gap,
                            children: [
                              for (final token in tokens)
                                _tile(token, colors[token]!, width, s),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String token, Color color, double width, ZodiannSurfaces s) {
    return Container(
      key: Key('swatch-$token'),
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: s.lineSoft),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ColoredBox(color: color),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bodyLabels[token] ?? token,
                  style: TextStyle(color: s.text, fontSize: 12),
                ),
                Text(
                  valueText(color),
                  style: TextStyle(color: s.text3, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
