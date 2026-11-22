// ZOD-UI-003, test only: two panels laid out with the layout tokens, mirroring
// the reference's CSS border-box panels (kit.css `.panel`, `.panel-head`,
// `.panel-body`). Boxes only, no text, so no fonts are needed.
//
// Every measured value comes from a token; the 40 px content block is the
// harness's own literal. Since ZOD-UI-014 the panels are the real
// `ZodiannPanel` (an empty head, so the head height and rule are measured).
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// Two panels on a `bg` page: side by side above phone width, stacked on
/// phone, separated by the layout's panel gap and inset by its gutter.
class TokenPanelHarness extends StatelessWidget {
  const TokenPanelHarness({super.key});

  /// The `RepaintBoundary` around the whole page.
  static const boundaryKey = Key('token-panel-harness');

  /// The first panel's content block.
  static const firstContentKey = Key('token-panel-content-a');

  @override
  Widget build(BuildContext context) {
    final layout = ZodiannLayout.of(context);
    final s = Theme.of(context).extension<ZodiannSurfaces>()!;
    final a = _Panel(surfaces: s, contentKey: firstContentKey);
    final b = _Panel(surfaces: s);
    return RepaintBoundary(
      key: boundaryKey,
      child: ColoredBox(
        color: s.bg,
        child: Padding(
          padding: EdgeInsets.all(layout.gutter),
          child: layout == ZodiannLayout.phone
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: layout.panelGap,
                  children: [a, b],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: layout.panelGap,
                  children: [
                    Expanded(child: a),
                    Expanded(child: b),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.surfaces, this.contentKey});

  final ZodiannSurfaces surfaces;
  final Key? contentKey;

  static const double _contentHeight = 40;

  @override
  Widget build(BuildContext context) => ZodiannPanel(
    head: const ZodiannPanelHead(),
    child: ColoredBox(
      key: contentKey,
      color: surfaces.accent,
      child: const SizedBox(height: _contentHeight),
    ),
  );
}
